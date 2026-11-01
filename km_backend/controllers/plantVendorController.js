const admin = require('firebase-admin');
const { getFirestore } = require('../config/firebase');
const PremiumEntitlement = require('../models/premiumEntitlementModel');

const PLANT_VENDOR_FEATURE = 'plant_vendor_premium';

// POST /api/plant-vendor/publish-plant
// Creates a new plant listing in Firestore ONLY after server-side entitlement check.
// The client is never trusted to decide whether the user has paid.
exports.publishPlant = async (req, res) => {
  try {
    const uid = req.user.uid;

    // Server-side entitlement check against MongoDB — not the Flutter client
    const entitlement = await PremiumEntitlement.findOne({
      userId: uid,
      featureId: PLANT_VENDOR_FEATURE,
      status: 'active',
    });

    if (!entitlement) {
      return res.status(403).json({
        error: 'Plant Vendor Premium entitlement required to publish a plant listing',
      });
    }

    const { plant } = req.body;
    if (!plant || typeof plant !== 'object') {
      return res.status(400).json({ error: 'plant data is required' });
    }

    const { plantName, type, price, vendorName, phone } = plant;

    if (!plantName || typeof plantName !== 'string' || !plantName.trim()) {
      return res.status(400).json({ error: 'plant.plantName is required' });
    }
    if (!type || typeof type !== 'string') {
      return res.status(400).json({ error: 'plant.type is required' });
    }
    if (price == null || isNaN(Number(price)) || Number(price) < 0) {
      return res.status(400).json({ error: 'plant.price must be a non-negative number' });
    }
    if (!vendorName || typeof vendorName !== 'string' || !vendorName.trim()) {
      return res.status(400).json({ error: 'plant.vendorName is required' });
    }
    if (!phone) {
      return res.status(400).json({ error: 'plant.phone is required' });
    }

    const db = getFirestore();
    const docRef = db.collection('plant_vendors').doc();

    const lat = Number(plant.latitude) || 0;
    const lng = Number(plant.longitude) || 0;

    const plantData = {
      id: docRef.id,
      plantName: String(plantName).trim(),
      type: String(type).trim(),
      price: Number(price),
      quantity: Number(plant.quantity) || 0,
      vendorName: String(vendorName).trim(),
      phone: String(phone).replace(/\D/g, ''),
      address: plant.address ? String(plant.address) : '',
      latitude: lat,
      longitude: lng,
      // Use GeoPoint when valid coordinates provided, otherwise store location string
      location: (lat !== 0 || lng !== 0)
        ? new admin.firestore.GeoPoint(lat, lng)
        : (plant.location ? String(plant.location) : ''),
      description: plant.description ? String(plant.description) : '',
      imageUrl: plant.imageUrl ? String(plant.imageUrl) : null,
      productSource: 'vendor',
      createdBy: uid, // always the verified Firebase uid — client-supplied value is ignored
      ownerId: uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    await docRef.set(plantData);

    return res.json({ success: true, plantId: docRef.id });
  } catch (err) {
    console.error('[plantVendorController.publishPlant]', err.message);
    res.status(500).json({ error: 'Failed to publish plant listing' });
  }
};
