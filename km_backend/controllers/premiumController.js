const PremiumPayment = require('../models/premiumPaymentModel');
const PremiumEntitlement = require('../models/premiumEntitlementModel');

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
// Returns combined payment history across both PayU (legacy) and Razorpay records.
exports.getHistory = async (req, res) => {
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
    console.error('[premiumController.getHistory]', err.message);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
};
