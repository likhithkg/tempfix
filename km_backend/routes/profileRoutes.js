'use strict';

const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const profileUpload = require('../middleware/profileUploadMiddleware');
const { uploadProfilePhoto, getProfilePhoto } = require('../controllers/profileController');

// Public — retrieve a profile photo by its GridFS ObjectId.
router.get('/photo/:id', getProfilePhoto);

// Protected — upload or replace the authenticated user's profile photo.
// Multer errors (file too large, wrong type) are caught here and returned as
// clean JSON before the controller runs.
router.post(
  '/photo',
  verifyToken,
  (req, res, next) => {
    profileUpload.single('photo')(req, res, (err) => {
      if (!err) return next();
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res
          .status(400)
          .json({ error: 'Image too large. Maximum size is 5 MB.' });
      }
      return res.status(400).json({ error: err.message || 'Upload error' });
    });
  },
  uploadProfilePhoto,
);

module.exports = router;
