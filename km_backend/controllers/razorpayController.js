const PremiumPayment = require('../models/premiumPaymentModel');
const PremiumEntitlement = require('../models/premiumEntitlementModel');
const Payment = require('../models/paymentModel');
const WebhookEvent = require('../models/webhookEventModel');
const razorpayService = require('../services/razorpayService');
const { getFirestore } = require('../config/firebase');

const VALID_FEATURES = ['renthub_premium', 'plant_vendor_premium', 'crop_disease_premium'];
const PACKAGE_PRICES = { 0: 0, 1: 99, 2: 169, 3: 229 };

function generateTxnId(prefix = 'KMP') {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
}

function calculatePremiumAmount(ownedCount, newCount) {
  const newTotal = Math.min(3, ownedCount + newCount);
  const credit = PACKAGE_PRICES[Math.min(3, ownedCount)] ?? 0;
  return Math.max(0, PACKAGE_PRICES[newTotal] - credit);
}

async function activateEntitlements(userId, features, txnid, packageType) {
  const ops = features.map((featureId) =>
    PremiumEntitlement.findOneAndUpdate(
      { userId, featureId },
      {
        $set: {
          userId,
          featureId,
          sourceTransactionId: txnid,
          packageType,
          status: 'active',
          activatedAt: new Date(),
          expiresAt: null,
        },
      },
      { upsert: true, new: true }
    )
  );
  return Promise.all(ops);
}

// ─── PREMIUM: POST /api/razorpay/create-order ────────────────────────────────

exports.createPremiumOrder = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { features, customerDetails } = req.body;

    if (!Array.isArray(features) || features.length === 0 || features.length > 3) {
      return res.status(400).json({ error: 'features must be a non-empty array of 1–3 items' });
    }
    if (features.some((f) => !VALID_FEATURES.includes(f))) {
      return res.status(400).json({ error: 'Invalid feature ID in request' });
    }
    if (new Set(features).size !== features.length) {
      return res.status(400).json({ error: 'Duplicate features in request' });
    }

    const existing = await PremiumEntitlement.find({
      userId: uid,
      featureId: { $in: features },
      status: 'active',
    });
    if (existing.length > 0) {
      return res.status(409).json({
        error: 'Already owned features',
        features: existing.map((e) => e.featureId),
      });
    }

    const ownedCount = await PremiumEntitlement.countDocuments({ userId: uid, status: 'active' });
    const amount = calculatePremiumAmount(ownedCount, features.length);

    if (amount <= 0) {
      return res.status(400).json({ error: 'Calculated payment amount is 0 or negative' });
    }

    const txnid = generateTxnId('KMP');
    const packageType = features.length;
    const name = (customerDetails?.name || req.user.name || 'Farmer').trim();
    const email = (customerDetails?.email || req.user.email || 'farmer@krishimithra.com').trim();
    const phone = (customerDetails?.phone || req.user.phone || '9999999999').replace(/\D/g, '');
    const productInfo = `KrishiMithra Premium - ${features.length} Feature${features.length > 1 ? 's' : ''}`;
    const amountPaise = amount * 100;

    const razorpayOrder = await razorpayService.createOrder({
      amountPaise,
      currency: 'INR',
      receipt: txnid,
      notes: { userId: uid, features: features.join(','), txnid },
    });

    await PremiumPayment.create({
      txnid,
      userId: uid,
      features,
      packageType,
      amount,
      currency: 'INR',
      productInfo,
      customerDetails: { name, email, phone },
      platform: req.body.platform || 'android',
      status: 'pending',
      provider: 'razorpay',
      razorpayOrderId: razorpayOrder.id,
    });

    return res.json({
      txnid,
      razorpayOrderId: razorpayOrder.id,
      keyId: razorpayService.getKeyId(),
      amountPaise,
      currency: 'INR',
      features,
      prefill: { name, email, contact: phone },
      description: productInfo,
    });
  } catch (err) {
    console.error('[razorpayController.createPremiumOrder]', err.message);
    res.status(500).json({ error: 'Failed to create Razorpay premium order' });
  }
};

// ─── PREMIUM: POST /api/razorpay/verify-payment ──────────────────────────────

exports.verifyPremiumPayment = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ error: 'razorpayOrderId, razorpayPaymentId, and razorpaySignature are required' });
    }

    const payment = await PremiumPayment.findOne({ razorpayOrderId });
    if (!payment) {
      return res.status(404).json({ error: 'Payment record not found for this Razorpay order' });
    }
    if (payment.userId !== uid) {
      return res.status(403).json({ error: 'Forbidden: payment does not belong to user' });
    }

    // Idempotency: already verified
    if (payment.status === 'success') {
      return res.json({
        success: true,
        activatedFeatures: payment.features,
        txnid: payment.txnid,
        message: 'Payment already verified',
      });
    }

    // Verify Razorpay signature
    const isValid = razorpayService.verifyPaymentSignature({
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    });

    if (!isValid) {
      payment.status = 'failed';
      payment.failureReason = 'Razorpay signature verification failed';
      await payment.save();
      return res.status(400).json({ success: false, error: 'Payment signature verification failed' });
    }

    // Mark success and activate entitlements
    payment.status = 'success';
    payment.razorpayPaymentId = razorpayPaymentId;
    payment.verifiedAt = new Date();
    await payment.save();

    await activateEntitlements(uid, payment.features, payment.txnid, payment.packageType);

    return res.json({
      success: true,
      activatedFeatures: payment.features,
      txnid: payment.txnid,
      message: `${payment.features.length} feature${payment.features.length > 1 ? 's' : ''} activated`,
    });
  } catch (err) {
    console.error('[razorpayController.verifyPremiumPayment]', err.message);
    res.status(500).json({ error: 'Payment verification failed' });
  }
};

// ─── PREMIUM: POST /api/razorpay/payment-status ──────────────────────────────
// Idempotent status check used by the result page after initial verification.

exports.getPremiumPaymentStatus = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { txnid } = req.body;

    if (!txnid) return res.status(400).json({ error: 'txnid is required' });

    const payment = await PremiumPayment.findOne({ txnid });
    if (!payment) return res.status(404).json({ success: false, error: 'Transaction not found' });
    if (payment.userId !== uid) return res.status(403).json({ success: false, error: 'Forbidden' });

    const activated = payment.status === 'success' ? payment.features : [];
    return res.json({
      success: payment.status === 'success',
      activatedFeatures: activated,
      txnid: payment.txnid,
      message: payment.status === 'success' ? 'Payment successful' : (payment.failureReason || 'Payment not completed'),
    });
  } catch (err) {
    console.error('[razorpayController.getPremiumPaymentStatus]', err.message);
    res.status(500).json({ error: 'Failed to fetch payment status' });
  }
};

// ─── PREMIUM: GET /api/razorpay/payment-history ──────────────────────────────

exports.getPremiumHistory = async (req, res) => {
  try {
    const uid = req.user.uid;
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, parseInt(req.query.limit, 10) || 20);

    const [payments, total] = await Promise.all([
      PremiumPayment.find(
        { userId: uid },
        { rawGatewayResponse: 0, __v: 0 }
      )
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      PremiumPayment.countDocuments({ userId: uid }),
    ]);

    res.json({ payments, total, page, pages: Math.ceil(total / limit) });
  } catch (err) {
    console.error('[razorpayController.getPremiumHistory]', err.message);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
};

// ─── WEBHOOK: POST /api/razorpay/webhook ─────────────────────────────────────
// Handles both premium and marketplace payment events.
// Raw body is required for signature verification — see server.js for capture setup.

exports.handleWebhook = async (req, res) => {
  try {
    const rawBody = req.rawBody ? req.rawBody.toString('utf8') : JSON.stringify(req.body);
    const signature = req.headers['x-razorpay-signature'];

    if (!signature) {
      return res.status(400).json({ error: 'Missing X-Razorpay-Signature header' });
    }

    if (!razorpayService.verifyWebhookSignature(rawBody, signature)) {
      return res.status(400).json({ error: 'Invalid webhook signature' });
    }

    const event = req.body;
    const eventId = event.id;
    const eventType = event.event;

    if (!eventId) {
      return res.status(400).json({ error: 'Missing event ID' });
    }

    // Idempotency: skip already-processed events
    const existing = await WebhookEvent.findOne({ eventId });
    if (existing) {
      return res.json({ message: 'Event already processed' });
    }

    // Record event before processing (prevents duplicate processing on retry)
    await WebhookEvent.create({ eventId, provider: 'razorpay', eventType });

    if (eventType === 'payment.captured') {
      const payment = event.payload?.payment?.entity;
      if (payment) {
        const razorpayOrderId = payment.order_id;
        const razorpayPaymentId = payment.id;
        await _handlePremiumCapture(razorpayOrderId, razorpayPaymentId, payment);
        await _handleMarketplaceCapture(razorpayOrderId, razorpayPaymentId, payment);
      }
    } else if (eventType === 'payment.failed') {
      const payment = event.payload?.payment?.entity;
      if (payment) {
        const razorpayOrderId = payment.order_id;
        await _handlePaymentFailed(razorpayOrderId, payment);
      }
    }

    res.json({ message: 'Webhook processed' });
  } catch (err) {
    console.error('[razorpayController.handleWebhook]', err.message);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
};

async function _handlePremiumCapture(razorpayOrderId, razorpayPaymentId, paymentEntity) {
  try {
    const record = await PremiumPayment.findOne({ razorpayOrderId });
    if (!record || record.status === 'success') return;

    record.status = 'success';
    record.razorpayPaymentId = razorpayPaymentId;
    record.verifiedAt = new Date();
    record.rawGatewayResponse = paymentEntity;
    await record.save();

    await activateEntitlements(record.userId, record.features, record.txnid, record.packageType);
  } catch (err) {
    console.error('[razorpay webhook] Premium capture error:', err.message);
  }
}

async function _handleMarketplaceCapture(razorpayOrderId, razorpayPaymentId, paymentEntity) {
  try {
    const record = await Payment.findOne({ razorpayOrderId });
    if (!record || record.status === 'success') return;

    record.status = 'success';
    record.razorpayPaymentId = razorpayPaymentId;
    record.verifiedAt = new Date();
    record.rawGatewayResponse = paymentEntity;
    record.firestoreSyncStatus = 'pending';
    await record.save();

    const firestore = getFirestore();
    try {
      await firestore.collection('gb_orders').doc(record.orderId).update({
        paymentStatus: 'PAID',
        status: 'confirmed',
        paymentId: record._id.toString(),
        razorpayOrderId,
        razorpayPaymentId,
        paidAt: new Date(),
        updatedAt: new Date(),
      });
      record.firestoreSyncStatus = 'synced';
      await record.save();
    } catch (fsErr) {
      console.error(`[razorpay webhook] RECONCILIATION NEEDED: Firestore update failed for order ${record.orderId}:`, fsErr.message);
      record.firestoreSyncStatus = 'failed';
      record.firestoreSyncError = fsErr.message;
      await record.save();
    }
  } catch (err) {
    console.error('[razorpay webhook] Marketplace capture error:', err.message);
  }
}

async function _handlePaymentFailed(razorpayOrderId, paymentEntity) {
  const reason = paymentEntity?.error_description || paymentEntity?.error_code || 'Payment failed';
  await PremiumPayment.updateOne(
    { razorpayOrderId, status: 'pending' },
    { status: 'failed', failureReason: reason, rawGatewayResponse: paymentEntity }
  ).catch(() => {});
  await Payment.updateOne(
    { razorpayOrderId, status: { $in: ['initiated', 'pending'] } },
    { status: 'failed', failureReason: reason }
  ).catch(() => {});
}

// ─── MARKETPLACE: POST /api/razorpay/marketplace/create-order ────────────────

exports.createMarketplaceOrder = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { orderId, orderType = 'green_bazaar', customerDetails } = req.body;

    if (!orderId) {
      return res.status(400).json({ error: 'orderId is required' });
    }

    const firestore = getFirestore();
    const orderDoc = await firestore.collection('gb_orders').doc(orderId).get();

    if (!orderDoc.exists) {
      return res.status(404).json({ error: 'Marketplace order not found' });
    }

    const orderData = orderDoc.data();
    if (orderData.userId !== uid) {
      return res.status(403).json({ error: 'Unauthorized: order does not belong to user' });
    }

    const authoritativeTotal = Number((orderData.itemsTotal || 0) + (orderData.deliveryCharge || 0));
    if (authoritativeTotal <= 0) {
      return res.status(400).json({ error: 'Order total must be greater than zero' });
    }

    const txnid = generateTxnId('KM');
    const amountPaise = Math.round(authoritativeTotal * 100);
    const name = (customerDetails?.name || orderData.userName || 'Customer').trim();
    const email = (customerDetails?.email || orderData.buyerEmail || 'customer@krishimithra.com').trim();
    const phone = (customerDetails?.phone || orderData.buyerPhone || '9999999999').replace(/\D/g, '');
    const productInfo = 'KrishiMithra Plant Order';

    const razorpayOrder = await razorpayService.createOrder({
      amountPaise,
      currency: 'INR',
      receipt: txnid,
      notes: { userId: uid, orderId, txnid },
    });

    await Payment.create({
      txnid,
      userId: uid,
      orderId,
      orderType,
      amount: authoritativeTotal,
      currency: 'INR',
      productInfo,
      customerDetails: { name, email, phone },
      status: 'initiated',
      provider: 'razorpay',
      razorpayOrderId: razorpayOrder.id,
    });

    return res.json({
      txnid,
      razorpayOrderId: razorpayOrder.id,
      keyId: razorpayService.getKeyId(),
      amountPaise,
      currency: 'INR',
      prefill: { name, email, contact: phone },
      description: productInfo,
    });
  } catch (err) {
    console.error('[razorpayController.createMarketplaceOrder]', err.message);
    res.status(500).json({ error: 'Failed to create marketplace Razorpay order' });
  }
};

// ─── MARKETPLACE: POST /api/razorpay/marketplace/verify-payment ──────────────

exports.verifyMarketplacePayment = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ error: 'razorpayOrderId, razorpayPaymentId, and razorpaySignature are required' });
    }

    const payment = await Payment.findOne({ razorpayOrderId });
    if (!payment) {
      return res.status(404).json({ error: 'Payment record not found' });
    }
    if (payment.userId !== uid) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    if (payment.status === 'success') {
      return res.json({ success: true, orderId: payment.orderId, message: 'Already verified' });
    }

    const isValid = razorpayService.verifyPaymentSignature({
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    });

    if (!isValid) {
      payment.status = 'failed';
      payment.failureReason = 'Razorpay signature verification failed';
      await payment.save();
      return res.status(400).json({ success: false, error: 'Payment signature verification failed' });
    }

    // Validate amount against Firestore order
    const firestore = getFirestore();
    const orderRef = firestore.collection('gb_orders').doc(payment.orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      return res.status(404).json({ error: 'Authoritative order not found' });
    }

    const orderData = orderDoc.data();
    const authoritativeTotal = Number((orderData.itemsTotal || 0) + (orderData.deliveryCharge || 0));

    if (Math.abs(authoritativeTotal - payment.amount) > 0.01) {
      payment.status = 'failed';
      payment.failureReason = 'Amount tampering detected';
      await payment.save();
      return res.status(400).json({ success: false, error: 'Amount validation failed' });
    }

    payment.status = 'success';
    payment.razorpayPaymentId = razorpayPaymentId;
    payment.verifiedAt = new Date();
    payment.firestoreSyncStatus = 'pending';
    await payment.save();

    try {
      await orderRef.update({
        paymentStatus: 'PAID',
        status: 'confirmed',
        paymentId: payment._id.toString(),
        razorpayOrderId,
        razorpayPaymentId,
        paidAt: new Date(),
        updatedAt: new Date(),
      });
      payment.firestoreSyncStatus = 'synced';
      await payment.save();
    } catch (fsErr) {
      console.error(`RECONCILIATION NEEDED: Firestore update failed for order ${payment.orderId}:`, fsErr.message);
      payment.firestoreSyncStatus = 'failed';
      payment.firestoreSyncError = fsErr.message;
      await payment.save();
    }

    return res.json({
      success: true,
      orderId: payment.orderId,
      txnid: payment.txnid,
      firestoreSyncStatus: payment.firestoreSyncStatus,
    });
  } catch (err) {
    console.error('[razorpayController.verifyMarketplacePayment]', err.message);
    res.status(500).json({ error: 'Marketplace payment verification failed' });
  }
};
