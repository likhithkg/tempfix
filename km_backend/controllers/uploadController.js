const fs = require("fs");
const cloudinary = require("../config/cloudinary");
const Image = require("../models/imageModel");

const uploadImage = async (req, res) => {
  const tempPath = req.file?.path;
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "No image uploaded" });
    }

    const result = await cloudinary.uploader.upload(tempPath, {
      folder: "km-app",
    });

    const savedImage = await Image.create({
      imageUrl: result.secure_url,
      publicId: result.public_id,
    });

    res.status(200).json({
      success: true,
      message: "Image uploaded successfully",
      data: savedImage,
    });
  } catch (error) {
    console.error("[uploadController]", error.message);

    // Handle multer errors
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ success: false, message: "File too large. Maximum size is 5 MB." });
    }

    res.status(500).json({ success: false, message: "Image upload failed" });
  } finally {
    // Always remove the temp file so the disk doesn't fill up
    if (tempPath) {
      fs.unlink(tempPath, () => {});
    }
  }
};

module.exports = { uploadImage };
