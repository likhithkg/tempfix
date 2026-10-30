const { getFirestore } = require('../config/firebase');
const PremiumEntitlement = require('../models/premiumEntitlementModel');

const RENTHUB_FEATURE = 'renthub_premium';

// POST /api/rent/publish-machine
// Creates a new machine listing in Firestore ONLY after server-side entitlement check.
// The client is never trusted to decide whether the user has paid.
exports.publishMachine = async (req, res) => {
  try {
    const uid = req.user.uid;

    // Server-side entitlement check against MongoDB — not the Flutter client
    const entitlement = await PremiumEntitlement.findOne({
      userId: uid,
      featureId: RENTHUB_FEATURE,
      status: 'active',
    });

    if (!entitlement) {
      return res.status(403).json({
        error: 'RentHub Premium entitlement required to publish a machine listing',
      });
    }

    const { machine } = req.body;
    if (!machine || typeof machine !== 'object') {
      return res.status(400).json({ error: 'machine data is required' });
    }

    const { name, type, pricePerHour, ownerName, phone, latitude, longitude } = machine;

    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ error: 'machine.name is required' });
    }
    if (!type || typeof type !== 'string') {
      return res.status(400).json({ error: 'machine.type is required' });
    }
    if (!pricePerHour || isNaN(Number(pricePerHour)) || Number(pricePerHour) <= 0) {
      return res.status(400).json({ error: 'machine.pricePerHour must be a positive number' });
    }
    if (!ownerName || typeof ownerName !== 'string' || !ownerName.trim()) {
      return res.status(400).json({ error: 'machine.ownerName is required' });
    }
    if (!phone) {
      return res.status(400).json({ error: 'machine.phone is required' });
    }
    if (latitude == null || isNaN(Number(latitude)) || longitude == null || isNaN(Number(longitude))) {
      return res.status(400).json({ error: 'machine.latitude and longitude are required' });
    }

    const db = getFirestore();
    const docRef = db.collection('rent_machines').doc();

    const machineData = {
      name: String(name).trim(),
      title: String(name).trim(),
      type: String(type).trim(),
      pricePerDay: 0,
      ratePerDay: 0,
      pricePerHour: Number(pricePerHour),
      ownerName: String(ownerName).trim(),
      ownerId: uid, // always the verified Firebase uid — client-supplied ownerId is ignored
      phone: String(phone).replace(/\D/g, ''),
      latitude: Number(latitude),
      longitude: Number(longitude),
      imageUrl: machine.imageUrl ? String(machine.imageUrl) : '',
      location: machine.location ? String(machine.location) : '',
      ownerPhotoUrl: machine.ownerPhotoUrl ? String(machine.ownerPhotoUrl) : null,
      availability: 'available',
      rating: 4.5,
      completedJobs: 0,
      acceptanceRate: 1.0,
      yearsInService: 1,
      badges: [],
      reliabilityScore: 80.0,
      listingStatus: 'published',
      createdAt: new Date(),
    };

    await docRef.set(machineData);

    return res.json({ success: true, machineId: docRef.id });
  } catch (err) {
    console.error('[rentController.publishMachine]', err.message);
    res.status(500).json({ error: 'Failed to publish machine listing' });
  }
};
