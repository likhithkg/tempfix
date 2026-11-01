const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const ctrl = require('../controllers/plantVendorController');

// Plant listing publish — requires Firebase ID token + Plant Vendor Premium entitlement
router.post('/publish-plant', verifyToken, ctrl.publishPlant);

module.exports = router;
