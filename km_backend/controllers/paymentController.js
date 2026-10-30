const Payment = require('../models/paymentModel');
const payuService = require('../services/payuService');
const { getFirestore } = require('../config/firebase');

/**
 * Initiates a payment session:
 * 1. Validates authoritative Firestore order & amount
 * 2. Generates unique txnid
 * 3. Records initial payment state in MongoDB
 * 4. Returns PayU public parameters to Flutter (NEVER PAYU_SALT)
 */
const createPayment = async (req, res) => {
  try {
    const { orderId, orderType = 'green_bazaar', amount, productInfo, customerDetails } = req.body;
    const userId = req.user.uid;

    if (!orderId || !amount) {
      return res.status(400).json({ error: 'orderId and amount are required' });
    }

    const firestore = getFirestore();
    const orderDoc = await firestore.collection('gb_orders').doc(orderId).get();

    if (!orderDoc.exists) {
      return res.status(404).json({ error: 'Marketplace order not found' });
    }

    const orderData = orderDoc.data();
    if (orderData.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized: order does not belong to user' });
    }

    // Validate authoritative amount against Firestore order
    const authoritativeTotal = Number((orderData.itemsTotal || 0) + (orderData.deliveryCharge || 0));
    const requestedAmount = Number(amount);

    if (Math.abs(authoritativeTotal - requestedAmount) > 0.01) {
      return res.status(400).json({
        error: 'Payment amount mismatch with authoritative order total',
      });
    }

    // Unique transaction ID
    const txnid = `KM_${Date.now()}_${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    // Record initiated payment in MongoDB
    const payment = await Payment.create({
      txnid,
      userId,
      orderId,
      orderType,
      amount: authoritativeTotal,
      currency: 'INR',
      productInfo: productInfo || 'KrishiMithra Plant Order',
      customerDetails: {
        name: customerDetails?.name || orderData.userName || null,
        email: customerDetails?.email || orderData.buyerEmail || null,
        phone: customerDetails?.phone || orderData.buyerPhone || null,
      },
      status: 'initiated',
    });

    // 0 = Test, 1 = Production
    const envCode = payuService.getPayUEnv() === 'production' ? 1 : 0;

    res.json({
      txnid: payment.txnid,
      key: payuService.getPayUKey(),
      amount: payment.amount.toFixed(2),
      productInfo: payment.productInfo,
      environment: envCode,
      surl: 'https://test.payu.in/admin/test_response',
      furl: 'https://test.payu.in/admin/test_response',
      customerDetails: payment.customerDetails,
    });
  } catch (err) {
    console.error('Error creating payment:', err);
    res.status(500).json({ error: 'Server error creating payment' });
  }
};

/**
 * Generates dynamic hash requested by PayU Checkout Pro Flutter SDK.
 * Appends PAYU_SALT on backend and returns SHA-512 hex string.
 * PAYU_SALT NEVER leaves the backend.
 */
const generateHash = async (req, res) => {
  try {
    const { hashName, hashString, postSalt } = req.body;

    if (!hashName || !hashString) {
      return res.status(400).json({ error: 'hashName and hashString are required' });
    }

    const calculatedHash = payuService.generateDynamicHash({ hashString, postSalt });

    res.json({
      [hashName]: calculatedHash,
    });
  } catch (err) {
    console.error('Error generating PayU dynamic hash:', err.message);
    res.status(500).json({ error: 'Failed to generate hash' });
  }
};

/**
 * Server-side payment verification:
 * 1. Checks MongoDB transaction & enforces idempotency
 * 2. Validates against authoritative Firestore order amount
 * 3. Calls PayU postservice verify_payment API
 * 4. Updates MongoDB Payment record
 * 5. Updates Firestore order paymentStatus to PAID
 * 6. Records reconciliation/error state if Firestore update fails
 */
const verifyPayment = async (req, res) => {
  try {
    const { txnid } = req.body;
    const userId = req.user.uid;

    if (!txnid) {
      return res.status(400).json({ error: 'txnid is required for verification' });
    }

    const payment = await Payment.findOne({ txnid });
    if (!payment) {
      return res.status(404).json({ error: 'Payment transaction record not found' });
    }

    if (payment.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized: payment does not belong to user' });
    }

    // ── Idempotency Check ──────────────────────────────────────────────────
    if (payment.status === 'success') {
      return res.json({
        success: true,
        message: 'Payment already verified',
        payment,
        orderId: payment.orderId,
        alreadyVerified: true,
      });
    }

    // ── Authoritative Order Amount Validation ──────────────────────────────
    const firestore = getFirestore();
    const orderRef = firestore.collection('gb_orders').doc(payment.orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      return res.status(404).json({ error: 'Authoritative marketplace order not found' });
    }

    const orderData = orderDoc.data();
    const authoritativeTotal = Number((orderData.itemsTotal || 0) + (orderData.deliveryCharge || 0));

    if (Math.abs(authoritativeTotal - payment.amount) > 0.01) {
      payment.status = 'failed';
      payment.failureReason = 'Amount tampering detected against authoritative order';
      await payment.save();
      return res.status(400).json({ error: 'Amount validation failed against order' });
    }

    // ── Call PayU Verify Payment API Server-to-Server ─────────────────────
    const payuVerification = await payuService.verifyPaymentWithPayU(txnid);
    const details = payuVerification.transaction_details?.[txnid];

    if (!details) {
      payment.status = 'failed';
      payment.failureReason = 'Transaction not found in PayU verify_payment records';
      payment.rawPayuResponse = payuVerification;
      await payment.save();
      return res.status(400).json({
        success: false,
        error: 'Transaction not found in PayU gateway records',
      });
    }

    const payuStatus = (details.status || '').toLowerCase();
    const payuAmount = parseFloat(details.transaction_amount || details.amt || '0');

    // Verify status and amount returned by PayU
    if (payuStatus === 'success' && Math.abs(payuAmount - payment.amount) < 0.01) {
      // 1. Update MongoDB payment record
      payment.status = 'success';
      payment.payuPaymentId = details.mihpayid || null;
      payment.bankRefNum = details.bank_ref_num || null;
      payment.paymentMode = details.mode || null;
      payment.verifiedAt = new Date();
      payment.rawPayuResponse = details;
      payment.firestoreSyncStatus = 'pending';
      await payment.save();

      // 2. Update Firestore order paymentStatus safely
      try {
        await orderRef.update({
          paymentStatus: 'PAID',
          status: 'confirmed',
          paymentId: payment._id.toString(),
          payuTxnId: txnid,
          payuPaymentId: details.mihpayid || null,
          paidAt: new Date(),
          updatedAt: new Date(),
        });
        payment.firestoreSyncStatus = 'synced';
        await payment.save();
      } catch (fsErr) {
        // Record reconciliation state if Firestore update fails after MongoDB succeeds
        console.error(
          `RECONCILIATION NEEDED: Payment ${txnid} succeeded in MongoDB but Firestore update failed:`,
          fsErr.message
        );
        payment.firestoreSyncStatus = 'failed';
        payment.firestoreSyncError = fsErr.message;
        await payment.save();
      }

      return res.json({
        success: true,
        message: 'Payment verified successfully',
        payment,
        orderId: payment.orderId,
        firestoreSyncStatus: payment.firestoreSyncStatus,
      });
    } else {
      // Handle failed or pending status from PayU
      payment.status = payuStatus === 'pending' ? 'pending' : 'failed';
      payment.failureReason = details.error_Message || `PayU returned status: ${payuStatus}`;
      payment.rawPayuResponse = details;
      await payment.save();

      try {
        await orderRef.update({
          paymentStatus: payment.status.toUpperCase(),
          updatedAt: new Date(),
        });
      } catch (_) {}

      return res.status(400).json({
        success: false,
        status: payment.status,
        error: payment.failureReason,
      });
    }
  } catch (err) {
    console.error('Error during payment verification:', err);
    res.status(500).json({ error: 'Server error during payment verification' });
  }
};

/**
 * Handles user cancellation from PayU Checkout Pro.
 */
const cancelPayment = async (req, res) => {
  try {
    const { txnid } = req.body;
    const userId = req.user.uid;

    if (!txnid) {
      return res.status(400).json({ error: 'txnid is required' });
    }

    const payment = await Payment.findOne({ txnid, userId });
    if (payment && payment.status !== 'success') {
      payment.status = 'cancelled';
      payment.failureReason = 'Cancelled by user on checkout';
      await payment.save();

      try {
        const firestore = getFirestore();
        await firestore.collection('gb_orders').doc(payment.orderId).update({
          paymentStatus: 'CANCELLED',
          updatedAt: new Date(),
        });
      } catch (_) {}
    }

    res.json({ success: true, status: 'cancelled' });
  } catch (err) {
    console.error('Error handling payment cancellation:', err);
    res.status(500).json({ error: 'Server error cancelling payment' });
  }
};

/**
 * Server-to-server webhook endpoint for asynchronous PayU callbacks.
 * Protects against duplicate processing and validates reverse hash if supplied.
 */
const handleWebhook = async (req, res) => {
  try {
    const payload = req.body;
    const txnid = payload.txnid;

    if (!txnid) {
      return res.status(400).send('Missing txnid');
    }

    const payment = await Payment.findOne({ txnid });
    if (!payment) {
      return res.status(404).send('Transaction not found');
    }

    if (payment.status === 'success') {
      return res.status(200).send('Already processed');
    }

    // Validate reverse hash if present
    if (payload.hash) {
      const isHashValid = payuService.verifyResponseHash(payload);
      if (!isHashValid) {
        console.warn(`PayU webhook received invalid reverse hash for ${txnid}`);
        return res.status(400).send('Invalid hash');
      }
    }

    // Call S2S verify_payment to be 100% sure
    const payuVerification = await payuService.verifyPaymentWithPayU(txnid);
    const details = payuVerification.transaction_details?.[txnid];

    if (details && (details.status || '').toLowerCase() === 'success') {
      payment.status = 'success';
      payment.payuPaymentId = details.mihpayid || null;
      payment.bankRefNum = details.bank_ref_num || null;
      payment.paymentMode = details.mode || null;
      payment.verifiedAt = new Date();
      payment.rawPayuResponse = details;
      payment.firestoreSyncStatus = 'pending';
      await payment.save();

      try {
        const firestore = getFirestore();
        await firestore.collection('gb_orders').doc(payment.orderId).update({
          paymentStatus: 'PAID',
          status: 'confirmed',
          paymentId: payment._id.toString(),
          payuTxnId: txnid,
          payuPaymentId: details.mihpayid || null,
          paidAt: new Date(),
          updatedAt: new Date(),
        });
        payment.firestoreSyncStatus = 'synced';
        await payment.save();
      } catch (fsErr) {
        console.error(`RECONCILIATION ERROR via Webhook: Firestore update failed for order ${payment.orderId}:`, fsErr);
        payment.firestoreSyncStatus = 'failed';
        payment.firestoreSyncError = fsErr.message;
        await payment.save();
      }
    }

    res.status(200).send('Webhook processed');
  } catch (err) {
    console.error('Error handling PayU webhook:', err);
    res.status(500).send('Webhook processing error');
  }
};

module.exports = {
  createPayment,
  generateHash,
  verifyPayment,
  cancelPayment,
  handleWebhook,
};
