const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const ctrl = require('../controllers/premiumController');

router.post('/create-payment', verifyToken, ctrl.createPayment);
router.post('/hash', verifyToken, ctrl.generateHash);
router.post('/verify', verifyToken, ctrl.verifyPayment);
router.post('/webhook', ctrl.handleWebhook);      // PayU S2S — no client auth
router.post('/web-return', ctrl.handleWebReturn); // PayU web redirect — no client auth
router.get('/entitlements', verifyToken, ctrl.getEntitlements);
router.get('/history', verifyToken, ctrl.getHistory);

module.exports = router;
