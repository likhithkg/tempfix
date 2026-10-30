const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { verifyToken } = require('../middleware/auth');

// Protected payment endpoints
router.post('/create', verifyToken, paymentController.createPayment);
router.post('/generate-hash', verifyToken, paymentController.generateHash);
router.post('/verify', verifyToken, paymentController.verifyPayment);
router.post('/cancel', verifyToken, paymentController.cancelPayment);

// Public webhook endpoint for PayU asynchronous server-to-server callbacks
router.post('/webhook', paymentController.handleWebhook);

module.exports = router;
