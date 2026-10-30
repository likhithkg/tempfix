const crypto = require('crypto');

function getPayUEnv() {
  return (process.env.PAYU_ENV || 'test').toLowerCase();
}

function getPayUKey() {
  const key = process.env.PAYU_KEY;
  if (!key) {
    throw new Error('PAYU_KEY is not defined in backend environment');
  }
  return key;
}

function getPayUSalt() {
  const salt = process.env.PAYU_SALT;
  if (!salt) {
    throw new Error('PAYU_SALT is not defined in backend environment');
  }
  return salt;
}

/**
 * Generates dynamic hash for PayU Checkout Pro.
 * Appends PAYU_SALT (and optional postSalt) to hashString received from SDK,
 * then generates SHA-512 hex string.
 * PAYU_SALT NEVER leaves the backend.
 */
function generateDynamicHash({ hashString, postSalt }) {
  if (!hashString || typeof hashString !== 'string') {
    throw new Error('hashString is required for dynamic hash calculation');
  }
  const salt = getPayUSalt();
  let dataToHash = hashString + salt;
  if (postSalt && typeof postSalt === 'string') {
    dataToHash += postSalt;
  }
  return crypto.createHash('sha512').update(dataToHash).digest('hex');
}

/**
 * Calls PayU Server-to-Server Verify Payment API:
 * Endpoint for TEST: https://test.payu.in/merchant/postservice?form=2
 * command=verify_payment
 * var1=txnid
 * hash=sha512(key|command|var1|salt)
 */
async function verifyPaymentWithPayU(txnid) {
  if (!txnid) {
    throw new Error('txnid is required for verification');
  }

  const key = getPayUKey();
  const salt = getPayUSalt();
  const env = getPayUEnv();

  // Test mode endpoint strictly as required
  const endpoint = env === 'production'
    ? 'https://info.payu.in/merchant/postservice.php?form=2'
    : 'https://test.payu.in/merchant/postservice?form=2';

  const command = 'verify_payment';
  const var1 = txnid;
  // Hash formula: sha512(key|command|var1|salt)
  const hashString = `${key}|${command}|${var1}|${salt}`;
  const hash = crypto.createHash('sha512').update(hashString).digest('hex');

  const formData = new URLSearchParams();
  formData.append('key', key);
  formData.append('command', command);
  formData.append('var1', var1);
  formData.append('hash', hash);
  formData.append('form', '2');

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: formData.toString(),
  });

  if (!response.ok) {
    throw new Error(`PayU Verify Payment HTTP error: ${response.status} ${response.statusText}`);
  }

  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (err) {
    throw new Error(`Invalid JSON response from PayU verify_payment: ${text}`);
  }

  return data;
}

/**
 * Validates reverse response hash sent in callback/webhook.
 * When additionalCharges present:
 * sha512(additionalCharges|salt|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key)
 * When additionalCharges NOT present:
 * sha512(salt|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key)
 */
function verifyResponseHash(params) {
  if (!params || !params.hash) return false;

  const salt = getPayUSalt();
  const {
    key,
    txnid,
    amount,
    productinfo,
    firstname,
    email,
    status,
    additionalCharges,
    udf1 = '',
    udf2 = '',
    udf3 = '',
    udf4 = '',
    udf5 = '',
    hash,
  } = params;

  let hashSequence;
  if (additionalCharges) {
    hashSequence = `${additionalCharges}|${salt}|${status}||||||${udf5}|${udf4}|${udf3}|${udf2}|${udf1}|${email}|${firstname}|${productinfo}|${amount}|${txnid}|${key}`;
  } else {
    hashSequence = `${salt}|${status}||||||${udf5}|${udf4}|${udf3}|${udf2}|${udf1}|${email}|${firstname}|${productinfo}|${amount}|${txnid}|${key}`;
  }

  const calculatedHash = crypto.createHash('sha512').update(hashSequence).digest('hex');
  return calculatedHash.toLowerCase() === hash.toLowerCase();
}

/**
 * Generates the forward hash for PayU Hosted Checkout (Flutter Web).
 * Formula: SHA512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt)
 * PAYU_SALT NEVER leaves the backend.
 */
function generateHostedCheckoutHash({
  txnid, amount, productinfo, firstname, email,
  udf1 = '', udf2 = '', udf3 = '', udf4 = '', udf5 = '',
}) {
  const key = getPayUKey();
  const salt = getPayUSalt();
  const s = `${key}|${txnid}|${amount}|${productinfo}|${firstname}|${email}|${udf1}|${udf2}|${udf3}|${udf4}|${udf5}||||||${salt}`;
  return crypto.createHash('sha512').update(s).digest('hex');
}

module.exports = {
  getPayUEnv,
  getPayUKey,
  generateDynamicHash,
  generateHostedCheckoutHash,
  verifyPaymentWithPayU,
  verifyResponseHash,
};
