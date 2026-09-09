const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true, index: true },
  email:        { type: String, default: null },
  phoneNumber:  { type: String, default: null },
  displayName:  { type: String, default: null },
  authProvider: {
    type: String,
    enum: ['phone', 'google', 'email', 'unknown'],
    default: 'unknown',
  },
  emailVerified:  { type: Boolean, default: false },
  phoneVerified:  { type: Boolean, default: false },
  profileImageId: { type: mongoose.Schema.Types.ObjectId, default: null },
  createdAt:    { type: Date, default: Date.now },
  lastLoginAt:  { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
