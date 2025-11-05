// lib/rent/rent_machine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_model.dart';

class RentMachineService {
  // ✅ Singleton instance (keeps existing usage RentMachineService.instance)
  static final RentMachineService instance = RentMachineService._internal();
  factory RentMachineService() => instance;
  RentMachineService._internal();

  final CollectionReference _db =
      FirebaseFirestore.instance.collection('rentMachines');

  /// ✅ Add a new machine (use given id if present, else auto-generate)
  Future<void> addRentMachine(RentMachine machine) async {
    final id = machine.id.isNotEmpty ? machine.id : _db.doc().id;
    await _db.doc(id).set(machine.copyWith(id: id).toMap());
  }

  /// 🔄 Alias for addRentMachine
  Future<void> addMachine(RentMachine machine) async {
    await addRentMachine(machine);
  }

  /// ✅ Get all machines (one-time fetch)
  Future<List<RentMachine>> getRentMachines() async {
    final snapshot = await _db.get();
    return snapshot.docs
        .map((doc) => RentMachine.fromDoc(doc))
        .toList();
  }

  /// 🔄 Alias for one-time fetch
  Future<List<RentMachine>> fetchOnce() async {
    return getRentMachines();
  }

  /// ✅ Get machine by ID
  Future<RentMachine?> getRentMachineById(String id) async {
    final doc = await _db.doc(id).get();
    if (!doc.exists) return null;
    return RentMachine.fromDoc(doc);
  }

  /// ✅ Update a machine by id
  Future<void> updateRentMachine(String id, RentMachine machine) async {
    await _db.doc(id).update(machine.toMap());
  }

  /// 🔄 Alias for updateRentMachine
  Future<void> updateMachine(String id, RentMachine machine) async {
    await updateRentMachine(id, machine);
  }

  /// ✅ Delete a machine by id
  Future<void> deleteRentMachine(String id) async {
    await _db.doc(id).delete();
  }

  /// ✅ Search by exact location
  Future<List<RentMachine>> getMachinesByLocation(String location) async {
    final snapshot =
        await _db.where('location', isEqualTo: location).get();
    return snapshot.docs
        .map((doc) => RentMachine.fromDoc(doc))
        .toList();
  }

  /// ✅ Search machines by name (prefix search)
  Future<List<RentMachine>> searchMachines(String query) async {
    final snapshot = await _db
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => RentMachine.fromDoc(doc))
        .toList();
  }

  /// ✅ Realtime stream with optional type & search filters
  Stream<List<RentMachine>> streamMachines({
    String? typeFilter,
    String? search,
  }) {
    Query query = _db;

    if (typeFilter != null &&
        typeFilter.isNotEmpty &&
        typeFilter != 'All') {
      query = query.where('type', isEqualTo: typeFilter);
    }

    if (search != null && search.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThanOrEqualTo: '$search\uf8ff');
    }

    return query.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => RentMachine.fromDoc(doc)).toList());
  }
}