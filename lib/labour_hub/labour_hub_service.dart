import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'labour_profile_model.dart';
import 'job_post_model.dart';
import 'job_application_model.dart';
import 'labour_review_model.dart';

class LabourHubService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  StreamController<List<LabourProfile>>? _allProfilesCtrl;
  StreamSubscription? _sub1;
  StreamSubscription? _sub2;
  List<LabourProfile> _newProfiles = [];
  List<LabourProfile> _legacyProfiles = [];

  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    _allProfilesCtrl?.close();
    _allProfilesCtrl = null;
    _sub1 = null;
    _sub2 = null;
  }

  // ── Legacy `labours` → LabourProfile ─────────────────────────────────────

  LabourProfile _legacyToProfile(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    double _d(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
    int _i(dynamic v) => v == null ? 0 : (v as num).toInt();
    DateTime _ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return now;
    }

    final skill = (d['skill'] as String? ?? d['category'] as String? ?? '').trim();
    final available = d['available'] as bool? ?? true;

    return LabourProfile(
      id: doc.id,
      uid: d['createdBy'] as String? ?? doc.id,
      name: d['name'] as String? ?? '',
      phone: d['contact'] as String? ?? d['phone'] as String? ?? '',
      village: d['location'] as String? ?? '',
      district: '',
      latitude: _d(d['latitude'] ?? d['lat']),
      longitude: _d(d['longitude'] ?? d['lon']),
      experienceYears: _i(d['experience'] ?? d['experienceYears']),
      dailyWage: _d(d['wage'] ?? d['dailyWage']),
      availabilityStatus: available ? 'available' : 'unavailable',
      skills: skill.isNotEmpty ? [skill] : [],
      photoUrl: d['imageUrl'] as String? ?? d['photoUrl'] as String? ?? '',
      rating: _d(d['rating']),
      reviewCount: _i(d['reviewCount']),
      completedJobs: _i(d['completedJobs']),
      createdAt: _ts(d['postedAt'] ?? d['createdAt']),
      updatedAt: _ts(d['updatedAt'] ?? d['postedAt']),
      lastActive: _ts(d['lastActive'] ?? d['updatedAt'] ?? d['postedAt']),
    );
  }

  // ── Labour Profiles ───────────────────────────────────────────────────────

  Future<LabourProfile?> getMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('labour_profiles').doc(uid).get();
      return doc.exists ? LabourProfile.fromDoc(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Future<LabourProfile?> getProfile(String uid) async {
    try {
      final doc = await _db.collection('labour_profiles').doc(uid).get();
      return doc.exists ? LabourProfile.fromDoc(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Stream<List<LabourProfile>> streamAllProfiles() {
    if (_allProfilesCtrl != null) return _allProfilesCtrl!.stream;

    _allProfilesCtrl = StreamController<List<LabourProfile>>.broadcast();

    void emit() {
      if (_allProfilesCtrl == null || _allProfilesCtrl!.isClosed) return;
      final newUids = _newProfiles.map((p) => p.uid).toSet();
      final merged = [
        ..._newProfiles,
        ..._legacyProfiles.where((p) => !newUids.contains(p.uid)),
      ];
      _allProfilesCtrl!.add(merged);
    }

    _sub1 = _db.collection('labour_profiles').limit(100).snapshots().listen(
      (snap) {
        _newProfiles = snap.docs
            .map((d) {
              try {
                return LabourProfile.fromDoc(d);
              } catch (_) {
                return null;
              }
            })
            .whereType<LabourProfile>()
            .toList();
        emit();
      },
      onError: (_) => emit(),
    );

    _sub2 = _db.collection('labours').limit(100).snapshots().listen(
      (snap) {
        _legacyProfiles = snap.docs
            .map((d) {
              try {
                return _legacyToProfile(d);
              } catch (_) {
                return null;
              }
            })
            .whereType<LabourProfile>()
            .toList();
        emit();
      },
      onError: (_) => emit(),
    );

    return _allProfilesCtrl!.stream;
  }

  Stream<List<LabourProfile>> streamAvailableProfiles() {
    return streamAllProfiles()
        .map((list) => list.where((p) => p.availabilityStatus == 'available').toList());
  }

  Stream<List<LabourProfile>> streamTopRatedProfiles() {
    return streamAllProfiles().map((list) {
      final sorted = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      return sorted.take(20).toList();
    });
  }

  Stream<List<LabourProfile>> streamNearbyProfiles(
    double userLat,
    double userLng,
    double radiusKm,
  ) {
    return streamAllProfiles().map((list) {
      final result = <MapEntry<LabourProfile, double>>[];
      for (final p in list) {
        if (!p.hasLocation) continue;
        final dist = _haversine(userLat, userLng, p.latitude, p.longitude);
        if (dist <= radiusKm) result.add(MapEntry(p, dist));
      }
      result.sort((a, b) => a.value.compareTo(b.value));
      return result.map((e) => e.key).toList();
    });
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double distanceBetween(double lat1, double lon1, double lat2, double lon2) =>
      _haversine(lat1, lon1, lat2, lon2);

  Future<void> saveProfile(LabourProfile profile) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final map = profile.toMap();
    final doc = await _db.collection('labour_profiles').doc(uid).get();
    if (!doc.exists) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    await _db
        .collection('labour_profiles')
        .doc(uid)
        .set(map, SetOptions(merge: true));
  }

  Future<void> updateAvailability(String status) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('labour_profiles').doc(uid).update({
      'availabilityStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLastActive() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('labour_profiles').doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
        'onlineStatus': true,
      });
    } catch (_) {}
  }

  Future<void> setOffline() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('labour_profiles').doc(uid).update({
        'onlineStatus': false,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Job Posts ──────────────────────────────────────────────────────────────

  Stream<List<JobPost>> streamOpenJobs() {
    return _db
        .collection('job_posts')
        .where('status', isEqualTo: 'open')
        .limit(50)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) {
            try {
              return JobPost.fromDoc(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<JobPost>()
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<JobPost>> streamMyPostedJobs() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('job_posts')
        .where('farmerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) {
            try {
              return JobPost.fromDoc(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<JobPost>()
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> postJob(JobPost job) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in — cannot post job');
    if (user.uid != job.farmerId) {
      throw Exception(
          'UID mismatch: auth=${user.uid} vs farmerId=${job.farmerId}');
    }

    final ref = _db.collection('job_posts').doc();
    final payload = job.toMap();

    debugPrint('[LabourHub] postJob ▶ '
        'collection=job_posts '
        'docId=${ref.id} '
        'uid=${user.uid} '
        'farmerId=${job.farmerId} '
        'title="${job.title}" '
        'status=${job.status} '
        'timestamp=${DateTime.now().toIso8601String()}');
    debugPrint('[LabourHub] postJob payload=$payload');

    try {
      await ref.set(payload);
      debugPrint('[LabourHub] postJob ✓ success docId=${ref.id}');
      return ref.id;
    } on FirebaseException catch (e, st) {
      debugPrint('[LabourHub] postJob ✗ FirebaseException '
          'code=${e.code} message=${e.message}');
      debugPrint('[LabourHub] postJob stack: $st');
      rethrow;
    } catch (e, st) {
      debugPrint('[LabourHub] postJob ✗ unexpected error: $e');
      debugPrint('[LabourHub] postJob stack: $st');
      rethrow;
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    debugPrint('[LabourHub] updateJobStatus ▶ jobId=$jobId status=$status');
    try {
      await _db.collection('job_posts').doc(jobId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[LabourHub] updateJobStatus ✓');
    } on FirebaseException catch (e, st) {
      debugPrint(
          '[LabourHub] updateJobStatus ✗ code=${e.code} message=${e.message}\n$st');
      rethrow;
    }
  }

  Future<void> deleteJob(String jobId) async {
    await _db.collection('job_posts').doc(jobId).delete();
  }

  // ── Job Applications ───────────────────────────────────────────────────────

  Future<void> applyForJob(JobApplication app) async {
    final ref = _db.collection('job_applications').doc();
    debugPrint('[LabourHub] applyForJob ▶ '
        'collection=job_applications docId=${ref.id} '
        'jobId=${app.jobId} labourId=${app.labourId}');
    try {
      await ref.set(app.toMap());
      debugPrint('[LabourHub] applyForJob ✓ docId=${ref.id}');
    } on FirebaseException catch (e, st) {
      debugPrint(
          '[LabourHub] applyForJob ✗ code=${e.code} message=${e.message}\n$st');
      rethrow;
    }
    try {
      await _db.collection('job_posts').doc(app.jobId).update({
        'applicantCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      debugPrint(
          '[LabourHub] applyForJob applicantCount increment skipped: code=${e.code}');
    }
  }

  Future<bool> hasApplied(String jobId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final snap = await _db
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .where('labourId', isEqualTo: uid)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Stream<List<JobApplication>> streamMyApplications() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('job_applications')
        .where('labourId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) {
            try {
              return JobApplication.fromDoc(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<JobApplication>()
          .toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return list;
    });
  }

  Stream<List<JobApplication>> streamJobApplications(String jobId) {
    return _db
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) {
            try {
              return JobApplication.fromDoc(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<JobApplication>()
          .toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return list;
    });
  }

  Future<void> updateApplicationStatus(String appId, String status) async {
    await _db
        .collection('job_applications')
        .doc(appId)
        .update({'status': status});
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<void> addReview(LabourReview review) async {
    final ref = _db.collection('labour_reviews').doc();
    await ref.set(review.toMap());
    final snap = await _db
        .collection('labour_reviews')
        .where('labourId', isEqualTo: review.labourId)
        .get();
    if (snap.docs.isNotEmpty) {
      final total = snap.docs.fold<double>(
          0,
          (s, d) =>
              s + ((d.data()['rating'] as num?)?.toDouble() ?? 0));
      await _db.collection('labour_profiles').doc(review.labourId).update({
        'rating': total / snap.docs.length,
        'reviewCount': snap.docs.length,
      });
    }
  }

  Stream<List<LabourReview>> streamReviews(String labourId) {
    return _db
        .collection('labour_reviews')
        .where('labourId', isEqualTo: labourId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) {
            try {
              return LabourReview.fromDoc(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<LabourReview>()
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── Favourites ─────────────────────────────────────────────────────────────

  Future<void> toggleFavourite(String labourId) async {
    final uid = _uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    final favs = doc.exists
        ? List<String>.from(doc.data()?['favouriteLabours'] ?? [])
        : <String>[];
    favs.contains(labourId) ? favs.remove(labourId) : favs.add(labourId);
    await ref.set({'favouriteLabours': favs}, SetOptions(merge: true));
  }

  Future<List<String>> getFavourites() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists
          ? List<String>.from(doc.data()?['favouriteLabours'] ?? [])
          : [];
    } catch (_) {
      return [];
    }
  }

  Stream<List<String>> streamFavouriteIds() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => List<String>.from(doc.data()?['favouriteLabours'] ?? []));
  }

  Future<List<LabourProfile>> fetchFavouriteProfiles() async {
    final ids = await getFavourites();
    if (ids.isEmpty) return [];
    final results = <LabourProfile>[];
    for (final id in ids) {
      try {
        final doc = await _db.collection('labour_profiles').doc(id).get();
        if (doc.exists) {
          results.add(LabourProfile.fromDoc(doc));
          continue;
        }
      } catch (_) {}
      try {
        final doc = await _db.collection('labours').doc(id).get();
        if (doc.exists) results.add(_legacyToProfile(doc));
      } catch (_) {}
    }
    return results;
  }

  // ── Legacy compat ─────────────────────────────────────────────────────────

  Stream<List<dynamic>> streamLabours() =>
      streamAllProfiles().map((list) => list);

  Future<void> deleteLabour(String id) async {
    await _db.collection('labour_profiles').doc(id).delete();
  }

  Future<String> addLabour(dynamic labour) async {
    final ref = _db.collection('labours').doc();
    final map = labour.toMap() as Map<String, dynamic>;
    map['postedAt'] = FieldValue.serverTimestamp();
    await ref.set(map);
    return ref.id;
  }

  Future<void> updateLabour(String id, dynamic labour) async {
    final map = labour.toMap() as Map<String, dynamic>;
    map.remove('id');
    map.remove('createdBy');
    await _db.collection('labours').doc(id).update(map);
  }
}
