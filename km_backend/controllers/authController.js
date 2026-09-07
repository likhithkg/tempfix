const User = require('../models/userModel');

const verifyAndSyncUser = async (req, res) => {
  try {
    const { uid, email, phone, emailVerified, name } = req.user;

    const authProvider = phone ? 'phone' : email ? 'email' : 'unknown';

    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      user = await User.create({
        firebaseUid: uid,
        email: email || null,
        phoneNumber: phone || null,
        displayName: name || null,
        authProvider,
        emailVerified: emailVerified || false,
        phoneVerified: !!phone,
      });
    } else {
      user.lastLoginAt = new Date();
      if (email && !user.email) user.email = email;
      if (phone && !user.phoneNumber) user.phoneNumber = phone;
      if (name && !user.displayName) user.displayName = name;
      await user.save();
    }

    res.json({
      uid: user.firebaseUid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      authProvider: user.authProvider,
      createdAt: user.createdAt,
    });
  } catch (err) {
    console.error('Auth sync error:', err.message);
    res.status(500).json({ error: 'Server error during user sync' });
  }
};

const getMe = async (req, res) => {
  try {
    const user = await User.findOne({ firebaseUid: req.user.uid });
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({
      uid: user.firebaseUid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      authProvider: user.authProvider,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    });
  } catch (err) {
    console.error('Get user error:', err.message);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { verifyAndSyncUser, getMe };
