require('dotenv').config();
const { initializeApp, getApps, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

if (!getApps().length) {
  // Render env vars are stored as raw text.  Several copy-paste paths produce
  // different representations of the PEM newlines; normalise all of them:
  //   1. Strip any surrounding " or ' (pasted with JSON quotes included)
  //   2. Double-escaped \\n  (3 chars: \ \ n)  → real newline
  //   3. Single-escaped \n   (2 chars: \ n)    → real newline
  //   4. Strip \r (CRLF from Windows-origin keys)
  const privateKey = (process.env.FIREBASE_PRIVATE_KEY || '')
    .replace(/^["']|["']$/g, '')
    .replace(/\\\\n/g, '\n')
    .replace(/\\n/g, '\n')
    .replace(/\r/g, '');

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
