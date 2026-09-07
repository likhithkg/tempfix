const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { verifyAndSyncUser, getMe } = require('../controllers/authController');

// Called by Flutter after every successful Firebase auth to sync user to MongoDB
router.post('/verify', verifyToken, verifyAndSyncUser);

// Returns the current authenticated user's profile from MongoDB
router.get('/me', verifyToken, getMe);

module.exports = router;
