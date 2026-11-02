const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    txnid: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    orderId: { type: String, required: true, index: true },
    orderType: {
      type: String,
      enum: ['green_bazaar', 'f2b_mart'],
      default: 'green_bazaar',
    },
    amount: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    productInfo: { type: String, required: true },
    customerDetails: {
      name: { type: String, default: null },
      email: { type: String, default: null },
      phone: { type: String, default: null },
    },
    status: {
      type: String,
      enum: ['initiated', 'pending', 'success', 'failed', 'cancelled'],
      default: 'initiated',
      index: true,
    },
    provider: { type: String, enum: ['payu', 'razorpay'], default: 'razorpay', index: true },

    // Razorpay fields
    razorpayOrderId: { type: String, default: null, index: true },
    razorpayPaymentId: { type: String, default: null },

    // Legacy PayU fields — preserved for historical records
    payuPaymentId: { type: String, default: null },
    bankRefNum: { type: String, default: null },
    paymentMode: { type: String, default: null },

    verifiedAt: { type: Date, default: null },
    firestoreSyncStatus: {
      type: String,
      enum: ['pending', 'synced', 'failed'],
      default: 'pending',
    },
    firestoreSyncError: { type: String, default: null },
    rawGatewayResponse: { type: mongoose.Schema.Types.Mixed, default: null },
    failureReason: { type: String, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Payment', paymentSchema);
