const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/razorpayController');
const { verifyToken } = require('../middleware/auth');

// Premium payment flow
router.post('/create-order', verifyToken, ctrl.createPremiumOrder);
router.post('/verify-payment', verifyToken, ctrl.verifyPremiumPayment);
router.post('/payment-status', verifyToken, ctrl.getPremiumPaymentStatus);
router.get('/payment-history', verifyToken, ctrl.getPremiumHistory);

// Webhook — no client auth; signature verified using RAZORPAY_WEBHOOK_SECRET
router.post('/webhook', ctrl.handleWebhook);

// Marketplace (GreenBazaar) payment flow
router.post('/marketplace/create-order', verifyToken, ctrl.createMarketplaceOrder);
router.post('/marketplace/verify-payment', verifyToken, ctrl.verifyMarketplacePayment);

module.exports = router;
