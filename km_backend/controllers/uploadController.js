const cloudinary = require("../config/cloudinary");
const Image = require("../models/imageModel");

const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "No image uploaded",
      });
    }

    const result = await cloudinary.uploader.upload(req.file.path, {
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
    console.log(error);

    res.status(500).json({
      success: false,
      message: "Image upload failed",
    });
  }
};

module.exports = {
  uploadImage,
};