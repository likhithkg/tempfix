import 'package:cloud_firestore/cloud_firestore.dart';
import 'plant_vendor_model.dart';

class PlantVendorService {
  final CollectionReference _vendorCollection =
      FirebaseFirestore.instance.collection('plant_vendors');

  // ✅ Add new vendor (Firestore will generate ID if vendor.id is empty)
  Future<void> addPlantVendor(PlantVendor vendor) async {
    if (vendor.id.isEmpty) {
      // Firestore auto-generates the ID
      final docRef = await _vendorCollection.add(vendor.toMap());
      // Update vendor with generated ID
      await docRef.update({'id': docRef.id});
    } else {
      // If vendor already has an ID (editing existing vendor)
      await _vendorCollection.doc(vendor.id).set(vendor.toMap());
    }
  }

  // ✅ Update vendor
  Future<void> updatePlantVendor(PlantVendor vendor) async {
    await _vendorCollection.doc(vendor.id).update(vendor.toMap());
  }

  // ✅ Delete vendor
  Future<void> deletePlantVendor(String id) async {
    await _vendorCollection.doc(id).delete();
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