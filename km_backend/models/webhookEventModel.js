const mongoose = require('mongoose');

const webhookEventSchema = new mongoose.Schema(
  {
    eventId: { type: String, required: true, unique: true, index: true },
    provider: { type: String, default: 'razorpay' },
    eventType: { type: String, default: null },
    processedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('WebhookEvent', webhookEventSchema);
