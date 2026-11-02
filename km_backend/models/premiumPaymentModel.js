const mongoose = require('mongoose');

const premiumPaymentSchema = new mongoose.Schema(
  {
    txnid: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    features: [{ type: String, required: true }],
    packageType: { type: Number, required: true, enum: [1, 2, 3] },
    amount: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    productInfo: { type: String, required: true },
    customerDetails: {
      name: { type: String, default: null },
      email: { type: String, default: null },
      phone: { type: String, default: null },
    },
    platform: { type: String, enum: ['android', 'web'], default: 'android' },
    status: {
      type: String,
      enum: ['pending', 'success', 'failed', 'cancelled'],
      default: 'pending',
      index: true,
    },
    provider: { type: String, enum: ['payu', 'razorpay'], default: 'razorpay', index: true },

    // Razorpay fields
    razorpayOrderId: { type: String, default: null, index: true },
    razorpayPaymentId: { type: String, default: null },

    // Legacy PayU fields — preserved for historical records
    payuPaymentId: { type: String, default: null },
    paymentMode: { type: String, default: null },

    verifiedAt: { type: Date, default: null },
    rawGatewayResponse: { type: mongoose.Schema.Types.Mixed, default: null },
    failureReason: { type: String, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('PremiumPayment', premiumPaymentSchema);
