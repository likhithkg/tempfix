const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const ctrl = require('../controllers/rentController');

// Machine listing publish — requires Firebase ID token + RentHub Premium entitlement
router.post('/publish-machine', verifyToken, ctrl.publishMachine);

module.exports = router;
