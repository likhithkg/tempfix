const crypto = require('crypto');

function getKeyId() {
  const key = process.env.RAZORPAY_KEY_ID;
  if (!key) throw new Error('RAZORPAY_KEY_ID is not set in environment');
  return key;
}

function getKeySecret() {
  const secret = process.env.RAZORPAY_KEY_SECRET;
  if (!secret) throw new Error('RAZORPAY_KEY_SECRET is not set in environment');
  return secret;
}

function getWebhookSecret() {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!secret) throw new Error('RAZORPAY_WEBHOOK_SECRET is not set in environment');
  return secret;
}

/**
 * Creates a Razorpay order via the Orders API.
 * amount must be in the smallest currency unit (paise for INR).
 */
async function createOrder({ amountPaise, currency = 'INR', receipt, notes = {} }) {
  const keyId = getKeyId();
  const keySecret = getKeySecret();
  const auth = Buffer.from(`${keyId}:${keySecret}`).toString('base64');

  const response = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${auth}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ amount: amountPaise, currency, receipt, notes }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Razorpay order creation failed: HTTP ${response.status}: ${errorText}`);
  }

  return response.json();
}

/**
 * Verifies Razorpay payment signature.
 * Formula: HMAC_SHA256(razorpayOrderId + "|" + razorpayPaymentId, keySecret)
 */
function verifyPaymentSignature({ razorpayOrderId, razorpayPaymentId, razorpaySignature }) {
  try {
    const keySecret = getKeySecret();
    const body = `${razorpayOrderId}|${razorpayPaymentId}`;
    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(body)
      .digest('hex');
    return expectedSignature === razorpaySignature;
  } catch (_) {
    return false;
  }
}

/**
 * Verifies Razorpay webhook signature.
 * Header: X-Razorpay-Signature = HMAC_SHA256(rawBody, webhookSecret)
 */
function verifyWebhookSignature(rawBody, signature) {
  try {
    const webhookSecret = getWebhookSecret();
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(rawBody)
      .digest('hex');
    return expectedSignature === signature;
  } catch (_) {
    return false;
  }
}

module.exports = {
  getKeyId,
  createOrder,
  verifyPaymentSignature,
  verifyWebhookSignature,
};
