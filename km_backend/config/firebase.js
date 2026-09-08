require('dotenv').config();
const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

if (!getApps().length) {
  // Render stores env vars as typed; if the private key was pasted from a JSON
  // value it may arrive with surrounding quotes or literal \n sequences instead
  // of real newlines. Strip quotes first, then normalise newlines.
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '')
    .replace(/^["']|["']$/g, '')
    .replace(/\\n/g, '\n');

  initializeApp({
    credential: cert({
      type: 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: privateKey,
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_uri: 'https://oauth2.googleapis.com/token',
    }),
  });
}

module.exports = { getAuth };
