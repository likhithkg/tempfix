const mongoose = require('mongoose');

const premiumEntitlementSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    featureId: { type: String, required: true },
    sourceTransactionId: { type: String, required: true },
    packageType: { type: Number, required: true },
    status: {
      type: String,
      enum: ['active', 'revoked'],
      default: 'active',
      index: true,
    },
    activatedAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

// One record per user+feature — upsert on purchase keeps the document in sync
premiumEntitlementSchema.index({ userId: 1, featureId: 1 }, { unique: true });

module.exports = mongoose.model('PremiumEntitlement', premiumEntitlementSchema);
