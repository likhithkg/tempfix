import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _apiKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';
  static const _prefKey = 'selectedLocation';
  static const _recentKey = 'recentLocations';
  static const _defaultKey = 'defaultLocation';

  // Save selected location
  static Future<void> saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, location);
  }

  // Load saved location
  static Future<String?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  // Save recent location (max 5)
  static Future<void> saveRecentLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recent = prefs.getStringList(_recentKey) ?? [];

    recent.remove(location); // avoid duplicates
    recent.insert(0, location); // add to top

    if (recent.length > 5) {
      recent = recent.sublist(0, 5);
    }

    await prefs.setStringList(_recentKey, recent);
  }

  // Get recent locations
  static Future<List<String>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  // Get suggestions from LocationIQ API
  static Future<List<dynamic>> getSuggestions(String input) async {
    final url = Uri.parse(
      'https://api.locationiq.com/v1/autocomplete?key=$_apiKey&q=$input&limit=6&format=json&countrycodes=IN',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ✅ Set default location
  static Future<void> setDefaultLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultKey, location);
  }

  // ✅ Get default location
  static Future<String?> getDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultKey);
  }
}