const mongoose = require('mongoose');

const otpChallengeSchema = new mongoose.Schema({
  phoneNumber:    { type: String, required: true },
  purpose:        { type: String, required: true, default: 'registration' },
  status:         {
    type: String,
    enum: ['pending', 'verified', 'used', 'expired'],
    default: 'pending',
  },
  // Number of verify() attempts — capped at MAX_ATTEMPTS in controller
  attemptCount:   { type: Number, default: 0 },
  // Number of times an OTP was sent to this phone for this challenge
  sentCount:      { type: Number, default: 0 },
  lastSentAt:     { type: Date, default: null },
  // SHA-256 hash of the proof token — raw token is returned to client only, never stored
  proofToken:     { type: String, default: null },
  proofExpiresAt: { type: Date, default: null },
  usedAt:         { type: Date, default: null },
  // TTL field — MongoDB auto-deletes documents when this time passes
  expiresAt:      { type: Date, required: true },
  createdAt:      { type: Date, default: Date.now },
});

// Auto-delete expired challenges
otpChallengeSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
// Fast lookup by phone + status
otpChallengeSchema.index({ phoneNumber: 1, status: 1 });

module.exports = mongoose.model('OtpChallenge', otpChallengeSchema);
