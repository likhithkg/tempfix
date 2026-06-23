// lib/rent/rent_machine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_model.dart';
import 'rent_booking_model.dart';

class RentMachineService {
  static final RentMachineService instance = RentMachineService._internal();
  factory RentMachineService() => instance;
  RentMachineService._internal();

  final CollectionReference _db =
      FirebaseFirestore.instance.collection('rent_machines');
  final CollectionReference _bookings =
      FirebaseFirestore.instance.collection('rent_bookings');

  // ─── Machine CRUD ──────────────────────────────────────────────────────────

  Future<void> addRentMachine(RentMachine machine) async {
    final id = machine.id.isNotEmpty ? machine.id : _db.doc().id;
    await _db.doc(id).set(machine.copyWith(id: id).toMap());
  }

  Future<void> addMachine(RentMachine machine) async => addRentMachine(machine);

  Stream<List<RentMachine>> streamRentMachines() {
    return _db.snapshots().map(
        (snap) => snap.docs.map((d) => RentMachine.fromDoc(d)).toList());
  }

  Future<List<RentMachine>> getRentMachines() async {
    try {
      final snapshot = await _db.get().timeout(const Duration(seconds: 10));
      final results = snapshot.docs.map((d) => RentMachine.fromDoc(d)).toList();
      if (results.isEmpty) {
        try {
          final cg = await FirebaseFirestore.instance
              .collectionGroup('rent_machines')
              .get()
              .timeout(const Duration(seconds: 10));
          final cgResults = cg.docs.map((d) => RentMachine.fromDoc(d)).toList();
          if (cgResults.isNotEmpty) return cgResults;
        } catch (_) {}
      }
      return results;
    } catch (e) {
      print('[RentMachineService] getRentMachines error: $e');
      return [];
    }
  }

  Future<List<RentMachine>> fetchOnce() async => getRentMachines();

  Future<RentMachine?> getRentMachineById(String id) async {
    try {
      final doc = await _db.doc(id).get();
      if (!doc.exists) return null;
      return RentMachine.fromDoc(doc);
    } catch (e) {
      print('[RentMachineService] getRentMachineById error: $e');
      rethrow;
    }
  }

  Future<void> updateRentMachine(String id, RentMachine machine) async {
    await _db.doc(id).update(machine.toMap());
  }

  Future<void> updateMachine(String id, RentMachine machine) async =>
      updateRentMachine(id, machine);

  Future<void> updateAvailability(
      String id, MachineAvailability availability) async {
    await _db.doc(id).update({'availability': availability.name});
  }

  Future<void> deleteRentMachine(String id) async => _db.doc(id).delete();

  Future<List<RentMachine>> getMachinesByLocation(String location) async {
    try {
      final snap = await _db.where('location', isEqualTo: location).get();
      return snap.docs.map((d) => RentMachine.fromDoc(d)).toList();
    } catch (e) {
      print('[RentMachineService] getMachinesByLocation error: $e');
      rethrow;
    }
  }

  Future<List<RentMachine>> searchMachines(String query) async {
    if (query.trim().isEmpty) return getRentMachines();
    final q = query.trim().toLowerCase();
    try {
      final snap = await _db
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query')
          .get();
      final results = snap.docs.map((d) => RentMachine.fromDoc(d)).toList();
      if (results.isNotEmpty) {
        return results
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.ownerName.toLowerCase().contains(q) ||
                (m.location?.toLowerCase().contains(q) ?? false))
            .toList();
      }
      final all = await getRentMachines();
      return all
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.ownerName.toLowerCase().contains(q) ||
              (m.location?.toLowerCase().contains(q) ?? false))
          .toList();
    } catch (e) {
      final all = await getRentMachines();
      return all
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.ownerName.toLowerCase().contains(q) ||
              (m.location?.toLowerCase().contains(q) ?? false))
          .toList();
    }
  }

  // ─── Booking methods ───────────────────────────────────────────────────────

  Future<String> createBooking(RentBooking booking) async {
    final ref = _bookings.doc();
    final b = RentBooking(
      id: ref.id,
      machineId: booking.machineId,
      machineName: booking.machineName,
      machineType: booking.machineType,
      machineImageUrl: booking.machineImageUrl,
      farmerId: booking.farmerId,
      farmerName: booking.farmerName,
      ownerId: booking.ownerId,
      ownerName: booking.ownerName,
      ownerPhone: booking.ownerPhone,
      hours: booking.hours,
      bookingDate: booking.bookingDate,
      fieldLatitude: booking.fieldLatitude,
      fieldLongitude: booking.fieldLongitude,
      fieldLocation: booking.fieldLocation,
      machineCharge: booking.machineCharge,
      travelCharge: booking.travelCharge,
      totalCost: booking.totalCost,
      status: booking.status,
      notes: booking.notes,
      createdAt: DateTime.now(),
      machineLatitude: booking.machineLatitude,
      machineLongitude: booking.machineLongitude,
    );
    await ref.set(b.toMap());
    return ref.id;
  }

  Stream<List<RentBooking>> streamBookingsByFarmer(String farmerId) {
    return _bookings
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RentBooking.fromDoc(d)).toList());
  }

  Stream<List<RentBooking>> streamBookingsByOwner(String ownerId) {
    return _bookings
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RentBooking.fromDoc(d)).toList());
  }

  Stream<RentBooking?> streamBookingById(String id) {
    return _bookings
        .doc(id)
        .snapshots()
        .map((snap) => snap.exists ? RentBooking.fromDoc(snap) : null);
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await _bookings.doc(id).update({'status': status.name});
  }

  Future<List<RentBooking>> getRecentBookingsByFarmer(String farmerId,
      {int limit = 5}) async {
    try {
      final snap = await _bookings
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => RentBooking.fromDoc(d)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Debug ─────────────────────────────────────────────────────────────────

  Future<void> debugFetchRawDocs() async {
    try {
      final docs = await _db.get();
      print('[RentMachineService] top-level count: ${docs.size}');
      for (var d in docs.docs) {
        print('- docId: ${d.id}, data: ${d.data()}');
      }
    } catch (e) {
      print('[RentMachineService] debugFetchRawDocs error: $e');
    }
  }
}
