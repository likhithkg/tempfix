const express = require('express');
const router  = express.Router();
const { verifyToken } = require('../middleware/auth');
const ctrl = require('../controllers/otpController');

// Public: initiate OTP delivery to a phone number (pre-registration)
router.post('/send', ctrl.sendOtp);

// Public: verify the OTP code; returns a short-lived single-use proof token on success
router.post('/verify', ctrl.verifyOtp);

// Authenticated: consume the proof token to complete registration
router.post('/complete-registration', verifyToken, ctrl.completeRegistration);

module.exports = router;
