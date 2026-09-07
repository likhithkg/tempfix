const { getAuth } = require('../config/firebase');

const verifyToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decoded = await getAuth().verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email || null,
      phone: decoded.phone_number || null,
      emailVerified: decoded.email_verified || false,
      name: decoded.name || null,
    };
    next();
  } catch (err) {
    if (err.code === 'auth/id-token-expired') {
      return res.status(401).json({ error: 'Token expired' });
    }
    if (err.code === 'auth/argument-error' || err.code === 'auth/id-token-revoked') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    return res.status(401).json({ error: 'Authentication failed' });
  }
};

module.exports = { verifyToken };
