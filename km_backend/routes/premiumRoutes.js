const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const ctrl = require('../controllers/premiumController');

// Entitlements and history endpoints are provider-agnostic — they work for
// both legacy PayU and new Razorpay records stored in PremiumEntitlement/PremiumPayment.
// Premium payment creation and verification now live at /api/razorpay/*.
router.get('/entitlements', verifyToken, ctrl.getEntitlements);
router.get('/history', verifyToken, ctrl.getHistory);

module.exports = router;
