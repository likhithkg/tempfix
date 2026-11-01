const crypto = require('crypto');
const OtpChallenge = require('../models/otpChallengeModel');

const OTP_API_BASE = 'https://api.otp.dev/v1/verifications';
// Verify the template ID in your OTP.dev dashboard — it appears to have 7 chars in segment 1
const SENDER_ID   = 'b6c44399-a7e6-4d31-859e-ea83030c417e';
const TEMPLATE_ID = 'b5bf5cd-0621-4197-bc46-976a67570007';

const RESEND_COOLDOWN_MS = 60 * 1000;      // 60 s between resends
const MAX_SENDS          = 5;              // max OTP sends per challenge
const MAX_ATTEMPTS       = 5;             // max verify attempts before lockout
const PROOF_TTL_MS       = 15 * 60 * 1000; // proof token valid for 15 min

// Returns digits only (OTP.dev expects country code + digits, no '+')
function toDigits(phone) {
  return String(phone || '').replace(/\D/g, '');
}

// Canonical form stored in MongoDB: '+' + digits
function canonical(phone) {
  return '+' + toDigits(phone);
}

// POST /api/otp/send
exports.sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone || typeof phone !== 'string') {
      return res.status(400).json({ error: 'phone is required' });
    }

    const digits = toDigits(phone);
    if (digits.length < 10 || digits.length > 15) {
      return res.status(400).json({ error: 'Invalid phone number' });
    }

    const canonPhone = canonical(phone);

    // Look for an existing pending challenge for this phone
    const existing = await OtpChallenge.findOne({
      phoneNumber: canonPhone,
      purpose: 'registration',
      status: 'pending',
      expiresAt: { $gt: new Date() },
    });

    if (existing) {
      // Enforce resend cooldown
      const msSinceLast = existing.lastSentAt
        ? Date.now() - existing.lastSentAt.getTime()
        : Infinity;

      if (msSinceLast < RESEND_COOLDOWN_MS) {
        const retryAfterSeconds = Math.ceil((RESEND_COOLDOWN_MS - msSinceLast) / 1000);
        return res.status(429).json({
          error: 'Please wait before resending',
          retryAfterSeconds,
        });
      }

      if (existing.sentCount >= MAX_SENDS) {
        return res.status(429).json({
          error: 'Maximum OTP resend limit reached. Please try again later.',
        });
      }
    }

    // Send OTP via OTP.dev
    const otpRes = await fetch(OTP_API_BASE, {
      method: 'POST',
      headers: {
        'X-OTP-Key': process.env.OTPDEV_API_KEY,
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: JSON.stringify({
        data: {
          channel:     'sms',
          sender:      SENDER_ID,
          phone:       digits,
          template:    TEMPLATE_ID,
          code_length: 6,
        },
      }),
    });

    if (!otpRes.ok) {
      console.error('[otpController.sendOtp] OTP.dev responded:', otpRes.status);
      return res.status(500).json({ error: 'Failed to send OTP. Please try again.' });
    }

    const otpData = await otpRes.json();
    const expiresAt = new Date(otpData.expire_date);

    if (existing) {
      existing.sentCount     += 1;
      existing.lastSentAt    = new Date();
      existing.expiresAt     = expiresAt;
      existing.attemptCount  = 0; // reset on resend so user gets fresh attempts
      await existing.save();
    } else {
      await OtpChallenge.create({
        phoneNumber: canonPhone,
        purpose:     'registration',
        status:      'pending',
        sentCount:   1,
        lastSentAt:  new Date(),
        expiresAt,
      });
    }

    return res.json({ success: true });
  } catch (err) {
    console.error('[otpController.sendOtp]', err.message);
    res.status(500).json({ error: 'Failed to send OTP. Please try again.' });
  }
};

// POST /api/otp/verify
exports.verifyOtp = async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) {
      return res.status(400).json({ error: 'phone and code are required' });
    }

    const canonPhone = canonical(phone);
    const digits     = toDigits(phone);

    const challenge = await OtpChallenge.findOne({
      phoneNumber: canonPhone,
      purpose:     'registration',
      status:      'pending',
    });

    if (!challenge) {
      return res.status(404).json({
        error: 'No active OTP challenge found. Please request a new OTP.',
      });
    }

    if (new Date() > challenge.expiresAt) {
      challenge.status = 'expired';
      await challenge.save();
      return res.status(410).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // Check attempt limit before calling OTP.dev to prevent enumeration
    if (challenge.attemptCount >= MAX_ATTEMPTS) {
      return res.status(429).json({
        error: 'Too many incorrect attempts. Please request a new OTP.',
      });
    }

    // Increment attempt count pessimistically before external call
    challenge.attemptCount += 1;
    await challenge.save();

    // Verify code with OTP.dev
    const verifyUrl = `${OTP_API_BASE}?code=${encodeURIComponent(code)}&phone=${encodeURIComponent(digits)}`;
    const verifyRes = await fetch(verifyUrl, {
      headers: {
        'X-OTP-Key': process.env.OTPDEV_API_KEY,
        'accept': 'application/json',
      },
    });

    if (!verifyRes.ok) {
      console.error('[otpController.verifyOtp] OTP.dev responded:', verifyRes.status);
      return res.status(500).json({ error: 'Verification service unavailable. Please try again.' });
    }

    const verifyData = await verifyRes.json();

    // Empty data array = invalid or unrecognised code
    if (!verifyData.data || verifyData.data.length === 0) {
      return res.status(422).json({ error: 'Incorrect OTP code. Please try again.' });
    }

    const record = verifyData.data[0];
    if (new Date(record.expire_date) < new Date()) {
      challenge.status = 'expired';
      await challenge.save();
      return res.status(410).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // Issue a short-lived, single-use proof token bound to this phone + purpose.
    // Only the SHA-256 hash is persisted — the raw token is returned once and never stored.
    const proofToken     = crypto.randomBytes(32).toString('hex');
    const proofHash      = crypto.createHash('sha256').update(proofToken).digest('hex');
    const proofExpiresAt = new Date(Date.now() + PROOF_TTL_MS);

    challenge.status        = 'verified';
    challenge.proofToken    = proofHash;
    challenge.proofExpiresAt = proofExpiresAt;
    await challenge.save();

    return res.json({
      success:   true,
      proofToken,
      expiresAt: proofExpiresAt.toISOString(),
    });
  } catch (err) {
    console.error('[otpController.verifyOtp]', err.message);
    res.status(500).json({ error: 'Verification failed. Please try again.' });
  }
};

// POST /api/otp/complete-registration — requires Firebase ID token via verifyToken middleware
exports.completeRegistration = async (req, res) => {
  try {
    const { phone, proofToken } = req.body;
    if (!phone || !proofToken) {
      return res.status(400).json({ error: 'phone and proofToken are required' });
    }

    const canonPhone = canonical(phone);

    const challenge = await OtpChallenge.findOne({
      phoneNumber: canonPhone,
      purpose:     'registration',
      status:      'verified',
    });

    if (!challenge) {
      return res.status(403).json({
        error: 'Phone verification required. Please verify your phone before completing registration.',
      });
    }

    if (!challenge.proofExpiresAt || new Date() > challenge.proofExpiresAt) {
      challenge.status = 'expired';
      await challenge.save();
      return res.status(410).json({
        error: 'Verification proof has expired. Please verify your phone again.',
      });
    }

    // Constant-time comparison to prevent timing attacks
    const incomingHash = crypto.createHash('sha256').update(proofToken).digest('hex');
    const storedHash   = challenge.proofToken;

    let tokenValid = false;
    try {
      tokenValid = crypto.timingSafeEqual(
        Buffer.from(incomingHash, 'hex'),
        Buffer.from(storedHash,   'hex'),
      );
    } catch (_) {
      tokenValid = false;
    }

    if (!tokenValid) {
      return res.status(403).json({ error: 'Invalid verification proof.' });
    }

    // Single-use: mark consumed immediately
    challenge.status = 'used';
    challenge.usedAt = new Date();
    await challenge.save();

    return res.json({ success: true });
  } catch (err) {
    console.error('[otpController.completeRegistration]', err.message);
    res.status(500).json({ error: 'Registration completion failed. Please try again.' });
  }
};
