const PremiumPayment = require('../models/premiumPaymentModel');
const PremiumEntitlement = require('../models/premiumEntitlementModel');
const payuService = require('../services/payuService');

const VALID_FEATURES = ['renthub_premium', 'plant_vendor_premium', 'crop_disease_premium'];
const PACKAGE_PRICES = { 0: 0, 1: 99, 2: 169, 3: 229 };
const BACKEND_BASE = 'https://km-backend-ug96.onrender.com';
const WEB_APP_BASE = 'https://krishimithra-650c2.web.app';

function calculateAmount(ownedCount, newCount) {
  const newTotal = Math.min(3, ownedCount + newCount);
  const credit = PACKAGE_PRICES[Math.min(3, ownedCount)] ?? 0;
  return Math.max(0, PACKAGE_PRICES[newTotal] - credit);
}

function generateTxnId() {
  return `KMP_${Date.now()}_${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
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

// POST /api/premium/create-payment
exports.createPayment = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { features, platform, customerDetails } = req.body;

    if (!Array.isArray(features) || features.length === 0 || features.length > 3) {
      return res.status(400).json({ error: 'features must be a non-empty array of 1–3 items' });
    }
    if (features.some((f) => !VALID_FEATURES.includes(f))) {
      return res.status(400).json({ error: 'Invalid feature ID in request' });
    }
    if (new Set(features).size !== features.length) {
      return res.status(400).json({ error: 'Duplicate features in request' });
    }
    if (!['android', 'web'].includes(platform)) {
      return res.status(400).json({ error: 'platform must be android or web' });
    }

    // Reject features already owned
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

    // Upgrade pricing: count all currently owned features
    const ownedCount = await PremiumEntitlement.countDocuments({ userId: uid, status: 'active' });
    const amount = calculateAmount(ownedCount, features.length);

    if (amount <= 0) {
      return res.status(400).json({ error: 'Calculated payment amount is 0 or negative' });
    }

    const txnid = generateTxnId();
    const packageType = features.length;
    const name = (customerDetails?.name || req.user.name || 'Farmer').trim();
    const email = (customerDetails?.email || req.user.email || 'farmer@krishimithra.com').trim();
    const phone = (customerDetails?.phone || req.user.phone || '9999999999').replace(/\D/g, '');
    const productInfo = `KrishiMithra Premium - ${features.length} Feature${features.length > 1 ? 's' : ''}`;
    const amountStr = amount.toFixed(2);

    const surl = platform === 'web'
      ? `${BACKEND_BASE}/api/premium/web-return`
      : `${BACKEND_BASE}/api/premium/webhook`;
    const furl = surl;

    await PremiumPayment.create({
      txnid, userId: uid, features, packageType, amount, currency: 'INR',
      productInfo, customerDetails: { name, email, phone },
      platform, status: 'pending',
    });

    const key = payuService.getPayUKey();
    const env = payuService.getPayUEnv();
    const environment = env === 'production' ? 1 : 0;

    const baseResponse = {
      txnid, key, amount: amountStr, productInfo,
      environment, surl, furl, firstname: name, email, phone,
    };

    if (platform === 'web') {
      const hash = payuService.generateHostedCheckoutHash({
        txnid, amount: amountStr, productinfo: productInfo,
        firstname: name, email,
      });
      const payuBaseUrl = env === 'production'
        ? 'https://secure.payu.in/_payment'
        : 'https://test.payu.in/_payment';
      return res.json({ ...baseResponse, hash, payuBaseUrl });
    }

    return res.json(baseResponse);
  } catch (err) {
    console.error('[premiumController.createPayment]', err.message);
    res.status(500).json({ error: 'Failed to create premium payment' });
  }
};

// POST /api/premium/hash  (Android Checkout Pro SDK — dynamic hash generation)
exports.generateHash = async (req, res) => {
  try {
    const { hashName, hashString, postSalt } = req.body;
    if (!hashName || !hashString) {
      return res.status(400).json({ error: 'hashName and hashString are required' });
    }
    const hash = payuService.generateDynamicHash({ hashString, postSalt });
    return res.json({ [hashName]: hash });
  } catch (err) {
    console.error('[premiumController.generateHash]', err.message);
    res.status(500).json({ error: 'Hash generation failed' });
  }
};

// POST /api/premium/verify  (Flutter calls after SDK success callback)
exports.verifyPayment = async (req, res) => {
  try {
    const uid = req.user.uid;
    const { txnid } = req.body;
    if (!txnid) return res.status(400).json({ error: 'txnid is required' });

    const payment = await PremiumPayment.findOne({ txnid });
    if (!payment) return res.status(404).json({ error: 'Transaction not found' });
    if (payment.userId !== uid) return res.status(403).json({ error: 'Forbidden' });

    if (payment.status === 'success') {
      return res.json({ success: true, activatedFeatures: payment.features, message: 'Already verified' });
    }

    const payuData = await payuService.verifyPaymentWithPayU(txnid);
    const txnDetails = payuData?.transaction_details?.[txnid];
    const payuStatus = txnDetails?.status?.toLowerCase();

    if (payuStatus === 'success') {
      await PremiumPayment.findOneAndUpdate({ txnid }, {
        status: 'success',
        payuPaymentId: txnDetails.mihpayid,
        paymentMode: txnDetails.mode,
        verifiedAt: new Date(),
        rawPayuResponse: payuData,
      });
      await activateEntitlements(uid, payment.features, txnid, payment.packageType);
      return res.json({ success: true, activatedFeatures: payment.features, message: 'Features activated' });
    }

    const reason = txnDetails?.field9 || txnDetails?.error_message || payuStatus || 'Payment not successful';
    await PremiumPayment.findOneAndUpdate({ txnid }, {
      status: 'failed', failureReason: reason, rawPayuResponse: payuData,
    });
    return res.status(402).json({ success: false, error: reason });
  } catch (err) {
    console.error('[premiumController.verifyPayment]', err.message);
    res.status(500).json({ error: 'Verification failed' });
  }
};

// POST /api/premium/webhook  (PayU S2S async notification — no auth required)
exports.handleWebhook = async (req, res) => {
  try {
    const params = req.body;

    if (!params.hash) {
      return res.status(400).json({ error: 'Missing hash — webhook rejected' });
    }
    if (!payuService.verifyResponseHash(params)) {
      return res.status(400).json({ error: 'Invalid hash — webhook rejected' });
    }

    const { txnid } = params;
    if (!txnid) return res.status(400).json({ error: 'Missing txnid' });

    const payment = await PremiumPayment.findOne({ txnid });
    if (!payment) return res.status(404).json({ error: 'Transaction not found' });
    if (payment.status === 'success') return res.json({ message: 'Already processed' });

    const payuData = await payuService.verifyPaymentWithPayU(txnid);
    const txnDetails = payuData?.transaction_details?.[txnid];
    const payuStatus = txnDetails?.status?.toLowerCase();

    if (payuStatus === 'success') {
      await PremiumPayment.findOneAndUpdate({ txnid }, {
        status: 'success',
        payuPaymentId: txnDetails.mihpayid,
        paymentMode: txnDetails.mode,
        verifiedAt: new Date(),
        rawPayuResponse: payuData,
      });
      await activateEntitlements(payment.userId, payment.features, txnid, payment.packageType);
    } else {
      await PremiumPayment.findOneAndUpdate({ txnid }, {
        status: 'failed',
        failureReason: txnDetails?.field9 || params.status || 'Unknown',
        rawPayuResponse: payuData,
      });
    }

    res.json({ message: 'Webhook processed' });
  } catch (err) {
    console.error('[premiumController.handleWebhook]', err.message);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
};

// POST /api/premium/web-return  (PayU redirects web browser here after payment — no auth)
exports.handleWebReturn = async (req, res) => {
  try {
    const params = req.body;
    const { txnid } = params;

    if (!txnid) {
      return res.redirect(`${WEB_APP_BASE}/#payment-result?status=error&message=missing_txnid`);
    }

    // Validate reverse hash when provided
    if (params.hash && !payuService.verifyResponseHash(params)) {
      return res.redirect(`${WEB_APP_BASE}/#payment-result?txnid=${txnid}&status=error&message=hash_invalid`);
    }

    try {
      const payuData = await payuService.verifyPaymentWithPayU(txnid);
      const txnDetails = payuData?.transaction_details?.[txnid];
      const payuStatus = txnDetails?.status?.toLowerCase();

      const payment = await PremiumPayment.findOne({ txnid });

      if (payuStatus === 'success') {
        if (payment && payment.status !== 'success') {
          await PremiumPayment.findOneAndUpdate({ txnid }, {
            status: 'success',
            payuPaymentId: txnDetails.mihpayid,
            paymentMode: txnDetails.mode,
            verifiedAt: new Date(),
            rawPayuResponse: payuData,
          });
          await activateEntitlements(payment.userId, payment.features, txnid, payment.packageType);
        }
        return res.redirect(`${WEB_APP_BASE}/#payment-result?txnid=${txnid}&status=success`);
      }

      if (payment && payment.status === 'pending') {
        await PremiumPayment.findOneAndUpdate({ txnid }, {
          status: 'failed',
          failureReason: txnDetails?.field9 || params.status || 'Unknown',
        });
      }
      return res.redirect(`${WEB_APP_BASE}/#payment-result?txnid=${txnid}&status=failure`);
    } catch (verifyErr) {
      console.error('[premiumController.handleWebReturn] S2S verify error:', verifyErr.message);
      return res.redirect(`${WEB_APP_BASE}/#payment-result?txnid=${txnid}&status=pending`);
    }
  } catch (err) {
    console.error('[premiumController.handleWebReturn]', err.message);
    res.redirect(`${WEB_APP_BASE}/#payment-result?status=error`);
  }
};

// GET /api/premium/entitlements
exports.getEntitlements = async (req, res) => {
  try {
    const uid = req.user.uid;
    const entitlements = await PremiumEntitlement.find(
      { userId: uid, status: 'active' },
      { featureId: 1, activatedAt: 1, packageType: 1, _id: 0 }
    );
    res.json({ entitlements });
  } catch (err) {
    console.error('[premiumController.getEntitlements]', err.message);
    res.status(500).json({ error: 'Failed to fetch entitlements' });
  }
};

// GET /api/premium/history
exports.getHistory = async (req, res) => {
  try {
    const uid = req.user.uid;
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, parseInt(req.query.limit, 10) || 20);

    const [payments, total] = await Promise.all([
      PremiumPayment.find(
        { userId: uid },
        { rawPayuResponse: 0, __v: 0 }
      )
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      PremiumPayment.countDocuments({ userId: uid }),
    ]);

    res.json({ payments, total, page, pages: Math.ceil(total / limit) });
  } catch (err) {
    console.error('[premiumController.getHistory]', err.message);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
};
