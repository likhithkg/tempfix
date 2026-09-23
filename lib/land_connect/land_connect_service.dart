import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'land_listing_model.dart';
import 'land_request_model.dart';

class LandConnectService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  // ── Collections ─────────────────────────────────────────────────────────────

  static CollectionReference get _listings => _db.collection('land_listings');
  static CollectionReference get _requests => _db.collection('land_connect_requests');
  static CollectionReference get _reports => _db.collection('land_connect_reports');

  // ── Land Listings ────────────────────────────────────────────────────────────

  static Future<String> createListing(LandListing listing) async {
    final doc = _listings.doc();
    final now = DateTime.now();
    final data = listing.copyWith(
      id: doc.id,
      ownerId: _uid ?? listing.ownerId,
      createdAt: now,
      updatedAt: now,
    ).toMap();
    await doc.set(data);
    return doc.id;
  }

  static Future<void> updateListing(LandListing listing) async {
    final data = listing.copyWith(updatedAt: DateTime.now()).toMap();
    await _listings.doc(listing.id).update(data);
  }

  static Future<void> updateListingStatus(String listingId, String status) async {
    await _listings.doc(listingId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<void> deleteListing(String listingId) async {
    await _listings.doc(listingId).update({
      'status': 'deleted',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<LandListing?> getListing(String listingId) async {
    final doc = await _listings.doc(listingId).get();
    if (!doc.exists) return null;
    return LandListing.fromDoc(doc);
  }

  /// Active listings for all cultivators (discovery).
  static Future<List<LandListing>> getActiveListings({int limit = 100}) async {
    final snap = await _listings
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(LandListing.fromDoc).toList();
  }

  /// My listings (owner view) — client-side filtering for deleted to avoid composite index.
  static Stream<List<LandListing>> myListings() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _listings
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map(LandListing.fromDoc)
            .where((l) => l.status != 'deleted')
            .toList());
  }

  // ── Land Requests ────────────────────────────────────────────────────────────

  /// Send a cultivation request; returns null on success or error message.
  static Future<String?> sendRequest(LandRequest request) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in';

    // Duplicate check: one active request per cultivator + listing
    final existing = await _requests
        .where('listingId', isEqualTo: request.listingId)
        .where('cultivatorId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted'])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return 'already_sent';

    final doc = _requests.doc();
    final now = DateTime.now();
    await doc.set(request.copyWith(
      id: doc.id,
      cultivatorId: uid,
      status: 'pending',
      createdAt: now,
    ).toMap());
    return null;
  }

  static Future<void> withdrawRequest(String requestId) async {
    await _requests.doc(requestId).update({
      'status': 'withdrawn',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<void> updateRequestStatus(String requestId, String status) async {
    await _requests.doc(requestId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Requests made by the current cultivator.
  static Stream<List<LandRequest>> myCultivatorRequests() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _requests
        .where('cultivatorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(LandRequest.fromDoc).toList());
  }

  /// Incoming requests to listings owned by the current user.
  static Stream<List<LandRequest>> incomingRequests() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _requests
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(LandRequest.fromDoc).toList());
  }

  /// Check if cultivator has an active request for this listing.
  static Future<bool> hasActiveRequest(String listingId) async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _requests
        .where('listingId', isEqualTo: listingId)
        .where('cultivatorId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted'])
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Get existing request for a listing (for the cultivator).
  static Future<LandRequest?> getMyRequestForListing(String listingId) async {
    final uid = _uid;
    if (uid == null) return null;
    final snap = await _requests
        .where('listingId', isEqualTo: listingId)
        .where('cultivatorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return LandRequest.fromDoc(snap.docs.first);
  }

  // ── Reports ──────────────────────────────────────────────────────────────────

  static Future<void> reportListing({
    required String listingId,
    required String reason,
    String details = '',
  }) async {
    await _reports.add({
      'listingId': listingId,
      'reportedBy': _uid ?? '',
      'reason': reason,
      'details': details,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'reviewed': false,
    });
  }
}

extension _LandRequestCopyWith on LandRequest {
  LandRequest copyWith({
    String? id,
    String? cultivatorId,
    String? status,
    DateTime? createdAt,
  }) =>
      LandRequest(
        id: id ?? this.id,
        listingId: listingId,
        cultivatorId: cultivatorId ?? this.cultivatorId,
        cultivatorName: cultivatorName,
        cultivatorPhone: cultivatorPhone,
        cultivatorExperience: cultivatorExperience,
        ownerId: ownerId,
        landTitle: landTitle,
        landLocation: landLocation,
        cropName: cropName,
        requestedAcres: requestedAcres,
        durationMonths: durationMonths,
        proposedArrangement: proposedArrangement,
        proposedAmount: proposedAmount,
        message: message,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt,
      );
}
