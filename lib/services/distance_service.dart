import 'dart:math';
import 'package:geolocator/geolocator.dart';

class DistanceService {
  static Future<Position?> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static bool isValid(double? lat, double? lon) {
    if (lat == null || lon == null) return false;
    if (lat == 0.0 && lon == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lon < -180 || lon > 180) return false;
    return true;
  }

  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  static String format(double km) {
    if (km < 1.0) return '${(km * 1000).round()} m away';
    if (km < 10.0) return '${km.toStringAsFixed(1)} km away';
    return '${km.round()} km away';
  }

  static List<T> sortByDistance<T>({
    required List<T> items,
    required double userLat,
    required double userLon,
    required double? Function(T) getLat,
    required double? Function(T) getLon,
  }) {
    final withDist = items.map((item) {
      final lat = getLat(item);
      final lon = getLon(item);
      final dist = isValid(lat, lon)
          ? haversine(userLat, userLon, lat!, lon!)
          : double.maxFinite;
      return _Pair(item, dist);
    }).toList()
      ..sort((a, b) => a.dist.compareTo(b.dist));
    return withDist.map((p) => p.item).toList();
  }
}

class _Pair<T> {
  final T item;
  final double dist;
  const _Pair(this.item, this.dist);
}
