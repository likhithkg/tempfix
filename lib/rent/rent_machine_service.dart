// lib/rent/rent_machine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rent_model.dart';

class RentMachineService {
  // ✅ Singleton instance (keeps existing usage RentMachineService.instance)
  static final RentMachineService instance = RentMachineService._internal();
  factory RentMachineService() => instance;
  RentMachineService._internal();

  // IMPORTANT: this matches your Firestore rules which use `rent_machines`
  final CollectionReference _db =
      FirebaseFirestore.instance.collection('rent_machines');

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
  /// - Defensive: uses a 10s timeout to avoid infinite loading.
  /// - If top-level collection returns empty, tries collectionGroup fallback
  ///   for subcollections named 'rent_machines'.
  Future<List<RentMachine>> getRentMachines() async {
    try {
      print('[RentMachineService] getRentMachines: starting top-level query');
      final snapshot = await _db.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[RentMachineService] getRentMachines: top-level get() timed out after 10s');
          throw Exception('Firestore top-level get() timed out');
        },
      );

      print('[RentMachineService] getRentMachines: top-level returned ${snapshot.size} docs');
      final List<RentMachine> results =
          snapshot.docs.map((doc) => RentMachine.fromDoc(doc)).toList();

      // Fallback to collectionGroup if top-level empty
      if (results.isEmpty) {
        print('[RentMachineService] getRentMachines: top-level empty, trying collectionGroup fallback');
        try {
          final cgSnap = await FirebaseFirestore.instance
              .collectionGroup('rent_machines')
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  print('[RentMachineService] collectionGroup get() timed out after 10s');
                  throw Exception('collectionGroup get() timed out');
                },
              );

          final List<RentMachine> cgResults =
              cgSnap.docs.map((d) => RentMachine.fromDoc(d)).toList();
          print('[RentMachineService] collectionGroup returned ${cgResults.length} docs');
          if (cgResults.isNotEmpty) return cgResults;
        } catch (e) {
          print('[RentMachineService] collectionGroup fallback failed: ${e.toString()}');
        }
      }

      return results;
    } catch (e, st) {
      print('[RentMachineService] getRentMachines error: ${e.toString()}');
      print(st);
      // Return empty list instead of rethrowing so UI can handle "no data"
      return <RentMachine>[];
    }
  }

  /// 🔄 Alias for one-time fetch
  Future<List<RentMachine>> fetchOnce() async {
    return getRentMachines();
  }

  /// ✅ Get machine by ID
  Future<RentMachine?> getRentMachineById(String id) async {
    try {
      final doc = await _db.doc(id).get();
      if (!doc.exists) return null;
      return RentMachine.fromDoc(doc);
    } catch (e) {
      print('[RentMachineService] getRentMachineById error: ${e.toString()}');
      rethrow;
    }
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
    try {
      final snapshot =
          await _db.where('location', isEqualTo: location).get();
      return snapshot.docs
          .map((doc) => RentMachine.fromDoc(doc))
          .toList();
    } catch (e) {
      print(
          '[RentMachineService] getMachinesByLocation error: ${e.toString()}');
      rethrow;
    }
  }

  /// ✅ Search machines by name (prefix search)
  /// - If Firestore prefix query returns nothing or fails (e.g., index missing),
  ///   falls back to fetching all and applying a client-side prefix filter.
    /// ✅ Enhanced search — matches machine name, owner name, OR location.
  /// - Tries Firestore prefix search on `name`.
  /// - Falls back to client-side filter across name, ownerName, and location.
  Future<List<RentMachine>> searchMachines(String query) async {
    if (query.trim().isEmpty) return await getRentMachines();

    final q = query.trim().toLowerCase();

    try {
      // 1️⃣ Try Firestore prefix search on `name`
      final snapshot = await _db
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // 2️⃣ Convert snapshot to models
      final firestoreResults =
          snapshot.docs.map((doc) => RentMachine.fromDoc(doc)).toList();

      // 3️⃣ If Firestore has results — also filter by owner/location locally
      if (firestoreResults.isNotEmpty) {
        return firestoreResults.where((m) {
          final name = (m.name).toLowerCase();
          final owner = (m.ownerName).toLowerCase();
          final loc = (m.location ?? '').toLowerCase();
          return name.contains(q) || owner.contains(q) || loc.contains(q);
        }).toList();
      }

      // 4️⃣ Fallback — fetch all and filter client-side across all fields
      final all = await getRentMachines();
      return all.where((m) {
        final name = (m.name).toLowerCase();
        final owner = (m.ownerName).toLowerCase();
        final loc = (m.location ?? '').toLowerCase();
        return name.contains(q) || owner.contains(q) || loc.contains(q);
      }).toList();
    } catch (e) {
      print('[RentMachineService] searchMachines error: $e');

      // 5️⃣ Final fallback — client-side filter
      final all = await getRentMachines();
      return all.where((m) {
        final name = (m.name).toLowerCase();
        final owner = (m.ownerName).toLowerCase();
        final loc = (m.location ?? '').toLowerCase();
        return name.contains(q) || owner.contains(q) || loc.contains(q);
      }).toList();
    }
  }


  // -------------------------
  // Debug / utility helpers
  // -------------------------

  /// Prints raw docs for debugging — call from a temporary debug UI or console.
  Future<void> debugFetchRawDocs() async {
    try {
      final docs = await _db.get();
      print('[RentMachineService] debugFetchRawDocs — top-level count: ${docs.size}');
      for (var d in docs.docs) {
        print('- docId: ${d.id}, data: ${d.data()}');
      }

      // also try collectionGroup to see if docs exist under subcollections
      try {
        final cg = await FirebaseFirestore.instance.collectionGroup('rent_machines').get();
        print('[RentMachineService] debugFetchRawDocs — collectionGroup count: ${cg.size}');
        for (var d in cg.docs) {
          print('- cg docId: ${d.id}, path: ${d.reference.path}, data: ${d.data()}');
        }
      } catch (e) {
        print('[RentMachineService] debugFetchRawDocs collectionGroup failed: ${e.toString()}');
      }
    } catch (e) {
      print('[RentMachineService] debugFetchRawDocs error: ${e.toString()}');
    }
  }
}
