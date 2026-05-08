// lib/plant_vendor/plant_vendor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plant_vendor_model.dart';

class PlantVendorService {
  final CollectionReference _vendorCollection =
      FirebaseFirestore.instance.collection('plant_vendors');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // Helper: if map contains numeric latitude & longitude, ensure a GeoPoint 'location' exists
  Map<String, dynamic> _ensureGeoPoint(Map<String, dynamic> map) {
    try {
      if (map.containsKey('location') && map['location'] is GeoPoint) {
        return map;
      }
      final hasLat = map.containsKey('latitude');
      final hasLng = map.containsKey('longitude');
      if (hasLat && hasLng) {
        final lat = map['latitude'];
        final lng = map['longitude'];
        if (lat != null && lng != null) {
          // Accept num or String values
          double? dLat;
          double? dLng;
          if (lat is num) dLat = lat.toDouble();
          if (lng is num) dLng = lng.toDouble();
          if (dLat == null || dLng == null) {
            dLat = double.tryParse(lat.toString());
            dLng = double.tryParse(lng.toString());
          }
          if (dLat != null && dLng != null) {
            map['location'] = GeoPoint(dLat, dLng);
          }
        }
      }
    } catch (_) {
      // ignore any conversion errors and leave map unchanged
    }
    return map;
  }

  // ✅ Add new vendor (Firestore will generate ID if vendor.id is empty)
  Future<void> addPlantVendor(PlantVendor vendor) async {
    final user = _currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'auth',
        code: 'not-signed-in',
        message: 'You must be signed in to add a vendor.',
      );
    }

    final baseData = vendor.toMap();

    // Prefer vendor.createdBy if provided and matches current user (defensive)
    final providedCreatedBy = (baseData['createdBy'] is String)
        ? (baseData['createdBy'] as String)
        : '';

    if (providedCreatedBy.isNotEmpty && providedCreatedBy != user.uid) {
      // Avoid sending a different UID than the signed-in user.
      throw FirebaseException(
        plugin: 'auth',
        code: 'createdBy-mismatch',
        message: 'createdBy must match the signed-in user.',
      );
    }

    // Ensure GeoPoint if lat/lng present
    final enriched = _ensureGeoPoint({...baseData});

    final data = {
      ...enriched,
      'createdBy': user.uid,
      'ownerId': user.uid, // keep backwards compatibility
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (vendor.id.isEmpty) {
        final docRef = await _vendorCollection.add(data);
        // write the generated id into the document, merge to avoid overwriting timestamp
        await docRef.set({'id': docRef.id}, SetOptions(merge: true));
      } else {
        // If client supplies an id (creating with known id) use set merge
        await _vendorCollection.doc(vendor.id).set(data, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin ?? 'firestore',
        code: e.code,
        message: 'Failed to add vendor: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw FirebaseException(
        plugin: 'unknown',
        code: 'unknown',
        message: 'Unknown error when adding vendor: $e',
      );
    }
  }

  // -----------------------
  // CLAIM + UPDATE helper
  // -----------------------
  /// Claims an ownerless doc (if needed) and updates it.
  /// If the doc has an owner different from current user, throws 'not-owner'.
  Future<void> claimAndUpdateVendor(String docId, Map<String, dynamic> updatedFields) async {
    final user = _currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'auth',
        code: 'not-signed-in',
        message: 'You must be signed in to update a vendor.',
      );
    }
    final uid = user.uid;
    final docRef = _vendorCollection.doc(docId);
    final snap = await docRef.get();

    // Ensure GeoPoint when updating
    final updatedWithGeo = _ensureGeoPoint({...updatedFields});

    // Compose timestamped payload
    final payloadBase = {
      ...updatedWithGeo,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      // Create doc and claim ownership
      final payload = {
        ...payloadBase,
        'createdBy': uid,
        'ownerId': uid,
      };
      await docRef.set(payload, SetOptions(merge: true));
      return;
    }

    final data = snap.data() as Map<String, dynamic>? ?? {};
    final existingOwner = (data['createdBy'] ?? data['ownerId']) as String? ?? '';

    if (existingOwner.isEmpty) {
      // Legacy ownerless doc: claim it by including createdBy in same write
      final payload = {
        ...payloadBase,
        'createdBy': uid,
        'ownerId': uid,
      };
      await docRef.set(payload, SetOptions(merge: true));
      return;
    }

    if (existingOwner != uid) {
      // Document owned by someone else
      throw FirebaseException(
        plugin: 'auth',
        code: 'not-owner',
        message: 'You are not the owner of this listing and cannot update it.',
      );
    }

    // Normal update for owned doc
    await docRef.set(payloadBase, SetOptions(merge: true));
  }

  // ✅ Update vendor (uses claim logic)
  Future<void> updatePlantVendor(PlantVendor vendor) async {
    if (vendor.id.isEmpty) {
      throw ArgumentError('Vendor id is empty. Use addPlantVendor to create a new vendor.');
    }

    // Prevent accidental createdBy mismatch from vendor.toMap()
    final dataMap = vendor.toMap();
    final user = _currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'auth',
        code: 'not-signed-in',
        message: 'You must be signed in to update a vendor.',
      );
    }

    if (dataMap.containsKey('createdBy') && dataMap['createdBy'] != user.uid) {
      throw FirebaseException(
        plugin: 'auth',
        code: 'createdBy-mismatch',
        message: 'createdBy must match the signed-in user.',
      );
    }

    // Delegate to claimAndUpdateVendor which handles ownerless docs properly
    await claimAndUpdateVendor(vendor.id, dataMap);
  }

  // ✅ Delete vendor (verify owner client-side for friendlier errors)
  Future<void> deletePlantVendor(String id) async {
    final user = _currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'auth',
        code: 'not-signed-in',
        message: 'You must be signed in to delete a vendor.',
      );
    }

    final docRef = _vendorCollection.doc(id);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'firestore',
        code: 'not-found',
        message: 'Vendor not found.',
      );
    }

    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    final owner = (data['createdBy'] ?? data['ownerId']) as String? ?? '';

    if (owner.isNotEmpty && owner != user.uid) {
      throw FirebaseException(
        plugin: 'auth',
        code: 'not-owner',
        message: 'You are not the owner of this listing and cannot delete it.',
      );
    }

    try {
      await docRef.delete();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin ?? 'firestore',
        code: e.code,
        message: 'Failed to delete vendor: ${e.message ?? e.code}',
      );
    }
  }

  // ✅ Get vendor by ID
  Future<PlantVendor?> getVendorById(String id) async {
    final doc = await _vendorCollection.doc(id).get();
    if (doc.exists) {
      return PlantVendor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ✅ Get ALL vendors
  Future<List<PlantVendor>> getAllVendors() async {
    final snapshot =
        await _vendorCollection.orderBy('timestamp', descending: true).get();

    return snapshot.docs
        .map((doc) =>
            PlantVendor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ⭐ NEW (name matches UI)
  Future<List<PlantVendor>> getPlantVendors() async {
    final snapshot =
        await _vendorCollection.orderBy('timestamp', descending: true).get();

    return snapshot.docs
        .map((doc) =>
            PlantVendor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // Optional filtered getters you had
  Future<List<PlantVendor>> getSeeds() async {
    final start = 'Seeds';
    final end = 'Seeds\uf8ff';
    final snapshot = await _vendorCollection
        .orderBy('type')
        .where('type', isGreaterThanOrEqualTo: start)
        .where('type', isLessThanOrEqualTo: end)
        .get();

    return snapshot.docs
        .map((doc) =>
            PlantVendor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<PlantVendor>> getPlants() async {
    final start = 'Plant';
    final end = 'Plant\uf8ff';
    final snapshot = await _vendorCollection
        .orderBy('type')
        .where('type', isGreaterThanOrEqualTo: start)
        .where('type', isLessThanOrEqualTo: end)
        .get();

    return snapshot.docs
        .map((doc) =>
            PlantVendor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  // ✅ Stream vendors (live updates)
  Stream<List<PlantVendor>> streamVendors() {
    return _vendorCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PlantVendor.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
