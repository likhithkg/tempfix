'use strict';

const mongoose = require('mongoose');
const { GridFSBucket, ObjectId } = require('mongodb');
const User = require('../models/userModel');

const BACKEND_URL =
  process.env.BACKEND_URL || 'https://km-backend-ug96.onrender.com';

// Lazy singleton — created only after mongoose has connected.
let _bucket = null;
function getBucket() {
  if (!_bucket) {
    _bucket = new GridFSBucket(mongoose.connection.db, {
      bucketName: 'profilePhotos',
    });
  }
  return _bucket;
}

async function deleteGridFSFile(objectId) {
  if (!objectId) return;
  try {
    await getBucket().delete(new ObjectId(objectId));
  } catch {
    // File may already be gone; ignore silently.
  }
}

// POST /api/profile/photo
const uploadProfilePhoto = async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No image supplied' });
  }

  const uid = req.user.uid;

  try {
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res
        .status(404)
        .json({ error: 'User not found — call /api/auth/verify first.' });
    }

    // Delete the previous profile photo from GridFS if one exists.
    await deleteGridFSFile(user.profileImageId);

    // Derive a safe file extension from the MIME type.
    const ext = req.file.mimetype === 'image/jpeg'
      ? 'jpg'
      : req.file.mimetype === 'image/png'
        ? 'png'
        : 'webp';
    const filename = `profile_${uid}_${Date.now()}.${ext}`;

    // Write the in-memory buffer to GridFS.
    const uploadStream = getBucket().openUploadStream(filename, {
      contentType: req.file.mimetype,
      metadata: { firebaseUid: uid },
    });

    await new Promise((resolve, reject) => {
      uploadStream.on('finish', resolve);
      uploadStream.on('error', reject);
      uploadStream.end(req.file.buffer);
    });

    const fileId = uploadStream.id;

    user.profileImageId = fileId;
    await user.save();

    const imageUrl = `${BACKEND_URL}/api/profile/photo/${fileId}`;
    return res.status(200).json({
      success: true,
      imageUrl,
      profileImageId: fileId.toString(),
    });
  } catch (err) {
    console.error('Profile photo upload error:', err);
    return res.status(500).json({ error: 'Server error during photo upload' });
  }
};

// GET /api/profile/photo/:id  (public — no auth required)
const getProfilePhoto = async (req, res) => {
  const { id } = req.params;

  let fileId;
  try {
    fileId = new ObjectId(id);
  } catch {
    return res.status(400).json({ error: 'Invalid image ID' });
  }

  try {
    const files = await getBucket().find({ _id: fileId }).toArray();
    if (!files.length) {
      return res.status(404).json({ error: 'Image not found' });
    }

    const file = files[0];
    res.set('Content-Type', file.contentType || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=31536000');

    const downloadStream = getBucket().openDownloadStream(fileId);
    downloadStream.on('error', () => {
      if (!res.headersSent) res.status(404).json({ error: 'Image not found' });
    });
    downloadStream.pipe(res);
  } catch (err) {
    console.error('Profile photo retrieval error:', err);
    if (!res.headersSent) {
      res.status(500).json({ error: 'Server error' });
    }
  }
};

module.exports = { uploadProfilePhoto, getProfilePhoto };
