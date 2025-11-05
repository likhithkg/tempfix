// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔑 Replace with your LocationIQ API key
  static const String _apiKey = "pk.56ccd9d8fb2cd5f3e9d7a656e3b52566";

  /// Convert a location name into latitude/longitude
  static Future<Map<String, double>> getCoordinatesFromName(String query) async {
    final url =
        "https://us1.locationiq.com/v1/search.php?key=$_apiKey&q=$query&format=json&limit=1";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data.isNotEmpty) {
        return {
          "lat": double.tryParse(data[0]["lat"] ?? "0") ?? 0.0,
          "lon": double.tryParse(data[0]["lon"] ?? "0") ?? 0.0,
        };
      }
    }
    return {"lat": 0.0, "lon": 0.0};
  }

  /// Save default location for a specific user
  static Future<void> setDefaultLocation(
    String location, {
    required String userId,
    required double lat,
    required double lon,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'default_location': location,
      'default_lat': lat,
      'default_lon': lon,
    }, SetOptions(merge: true));
  }

  /// Save a location (last used)
  static Future<void> saveLocation(String location, {required String userId}) async {
    await _firestore.collection('users').doc(userId).set({
      'last_location': location,
    }, SetOptions(merge: true));
  }

  /// Save a location to recent locations list
  static Future<void> saveRecentLocation(String location, {required String userId}) async {
    final docRef = _firestore.collection('users').doc(userId);
    final doc = await docRef.get();

    List<String> recent = [];
    if (doc.exists && doc.data()!['recent_locations'] != null) {
      recent = List<String>.from(doc.data()!['recent_locations']);
    }

    // Avoid duplicates
    recent.remove(location);
    recent.insert(0, location);

    // Keep only last 5
    if (recent.length > 5) {
      recent = recent.sublist(0, 5);
    }

    await docRef.set({'recent_locations': recent}, SetOptions(merge: true));
  }

  /// Get recent locations for a user
  static Future<List<String>> getRecentLocations({required String userId}) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!['recent_locations'] != null) {
      return List<String>.from(doc.data()!['recent_locations']);
    }
    return [];
  }

  /// Get default location (name) for a user
  static Future<String?> getDefaultLocation({required String userId}) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!['default_location'] != null) {
      return doc.data()!['default_location'] as String;
    }
    return null;
  }

  /// Get default coordinates (lat/lon) for a user
  static Future<Map<String, double>?> getDefaultCoordinates({required String userId}) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists &&
        doc.data()?['default_lat'] != null &&
        doc.data()?['default_lon'] != null) {
      return {
        "lat": (doc.data()?['default_lat'] as num).toDouble(),
        "lon": (doc.data()?['default_lon'] as num).toDouble(),
      };
    }
    return null;
  }

  /// Fetch autocomplete suggestions from LocationIQ
  static Future<List<dynamic>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    final url =
        "https://us1.locationiq.com/v1/autocomplete.php?key=$_apiKey&q=$query&format=json&limit=5";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}