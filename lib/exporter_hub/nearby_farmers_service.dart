// lib/exporter_hub/nearby_farmers_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class NearbyFarmersService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch candidate docs from Firestore.
  /// Now fetches both 'farmers' and 'export_products' and merges them.
  Future<List<QueryDocumentSnapshot>> _fetchCandidateDocs({int limit = 1000}) async {
    final List<QueryDocumentSnapshot> results = [];

    // Fetch a chunk from farmers
    try {
      final farmersRef = _db.collection('farmers');
      final farmersSnap = await farmersRef.limit(limit).get();
      if (farmersSnap.docs.isNotEmpty) {
        results.addAll(farmersSnap.docs);
      }
    } catch (e) {
      // ignore or log - don't fail entire flow if one collection errors
    }

    // Fetch a chunk from export_products
    try {
      final exportRef = _db.collection('export_products');
      final exportSnap = await exportRef.limit(limit).get();
      if (exportSnap.docs.isNotEmpty) {
        results.addAll(exportSnap.docs);
      }
    } catch (e) {
      // ignore or log
    }

    // If nothing from both, try returning an empty list (caller handles)
    return results;
  }

  /// Extract lat/lon using many possible field names and types including GeoPoint.
  Map<String, double>? extractCoordsFromMap(Map<String, dynamic> m) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    // Handle Firestore GeoPoint objects
    dynamic _handlePossibleGeoPoint(dynamic v) {
      // If it's already a GeoPoint (Firestore)
      if (v is GeoPoint) {
        return {'lat': v.latitude, 'lon': v.longitude};
      }
      // If it's a map-like with latitude/longitude
      if (v is Map) {
        final la = _toDouble(v['latitude'] ?? v['lat']);
        final lo = _toDouble(v['longitude'] ?? v['lng'] ?? v['lon']);
        if (la != null && lo != null) return {'lat': la, 'lon': lo};
      }
      // If it's a list/array [lat, lon]
      if (v is List && v.length >= 2) {
        final la = _toDouble(v[0]);
        final lo = _toDouble(v[1]);
        if (la != null && lo != null) return {'lat': la, 'lon': lo};
      }
      // If it's a string "lat,lon"
      if (v is String) {
        final parts = v.split(RegExp(r'\s*,\s*'));
        if (parts.length >= 2) {
          final la = _toDouble(parts[0]);
          final lo = _toDouble(parts[1]);
          if (la != null && lo != null) return {'lat': la, 'lon': lo};
        }
      }
      return null;
    }

    // Common key pairs
    final candidates = [
      ['locationLat', 'locationLon'],
      ['lat', 'lng'],
      ['latitude', 'longitude'],
      ['lat', 'lon'],
      ['location_lat', 'location_lon'],
      ['geo_lat', 'geo_lon'],
    ];

    for (final pair in candidates) {
      final a = m[pair[0]];
      final b = m[pair[1]];
      if (a != null && b != null) {
        final la = _toDouble(a);
        final lo = _toDouble(b);
        if (la != null && lo != null) return {'lat': la, 'lon': lo};
      }
    }

    // Recognize top-level GeoPoint or array or string fields
    final possibleGeo = m['location'] ?? m['geo'] ?? m['position'] ?? m['geo_point'] ?? m['geopoint'];
    final handled = _handlePossibleGeoPoint(possibleGeo);
    if (handled != null) return handled;

    // Some docs store a nested object like { location: { lat:..., lng:... } }
    if (possibleGeo is Map) {
      final nested = _handlePossibleGeoPoint(possibleGeo);
      if (nested != null) return nested;
    }

    // Handle nested named fields like 'position' containing geopoint or map
    final pos = m['position'];
    if (pos != null) {
      final pHandled = _handlePossibleGeoPoint(pos);
      if (pHandled != null) return pHandled;
      if (pos is Map) {
        final la = _toDouble(pos['lat'] ?? pos['latitude']);
        final lo = _toDouble(pos['lng'] ?? pos['lon'] ?? pos['longitude']);
        if (la != null && lo != null) return {'lat': la, 'lon': lo};
      }
    }

    // Lastly, try to find any GeoPoint-like map anywhere in document keys
    for (final entry in m.entries) {
      final v = entry.value;
      final candidate = _handlePossibleGeoPoint(v);
      if (candidate != null) return candidate;
    }

    return null;
  }

  /// Query nearby farmers by client-side filtering.
  /// centerLat/centerLon required. radiusKm default 20.
  Future<List<Map<String, dynamic>>> queryNearbyFarmers({
    required double centerLat,
    required double centerLon,
    double radiusKm = 20,
    int limit = 1000,
  }) async {
    final docs = await _fetchCandidateDocs(limit: limit);

    final List<Map<String, dynamic>> result = [];

    for (final d in docs) {
      final raw = d.data();
      if (raw == null) continue;

      // Ensure we have a Map<String, dynamic>
      final m = (raw is Map<String, dynamic>) ? raw : Map<String, dynamic>.from(raw as Map);

      final coords = extractCoordsFromMap(m);
      if (coords == null) continue;

      final lat = coords['lat']!;
      final lon = coords['lon']!;
      final meters = Geolocator.distanceBetween(centerLat, centerLon, lat, lon);
      final km = meters / 1000.0;
      if (km <= radiusKm) {
        final farmerPhone =
            (m['farmerMobile'] ?? m['farmerMobileNo'] ?? m['farmer_phone'] ?? m['farmerId'] ?? m['phone'] ?? '') as dynamic;
        final farmerPhoneStr = farmerPhone?.toString() ?? '';
        final farmerIdKey = farmerPhoneStr.trim().isNotEmpty ? farmerPhoneStr.trim() : (m['farmerId']?.toString() ?? d.id);

        result.add({
          'id': farmerIdKey,
          'name': (m['farmerName'] ?? m['name'] ?? m['productName'] ?? 'Unknown').toString(),
          'phone': farmerPhoneStr,
          'lat': lat,
          'lon': lon,
          'distKm': km,
          'location': (m['location'] ?? '') is String ? (m['location'] ?? '') : '',
          'sourceDoc': d.id,
          'raw': m,
        });
      }
    }

    // dedupe by id and keep smallest distance
    final Map<String, Map<String, dynamic>> dedup = {};
    for (final f in result) {
      final id = f['id'] as String;
      if (!dedup.containsKey(id) || (f['distKm'] as double) < (dedup[id]!['distKm'] as double)) {
        dedup[id] = f;
      }
    }

    final out = dedup.values.toList();
    out.sort((a, b) => (a['distKm'] as double).compareTo(b['distKm'] as double));
    return out;
  }
}
