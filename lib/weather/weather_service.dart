import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_model.dart';

class WeatherService {
  final String _locationIqKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';
  final String _tomorrowKey = 'tnYx06QaLBQdUqlgCNPeWgH828139AN0';

  Future<WeatherData> fetchWeather(String place) async {
    final locUrl = Uri.parse(
        'https://us1.locationiq.com/v1/search.php?key=$_locationIqKey&q=$place&format=json');
    final locRes = await http.get(locUrl);

    if (locRes.statusCode != 200) {
      throw Exception('Failed to fetch location');
    }

    final locData = jsonDecode(locRes.body);
    final lat = locData[0]['lat'];
    final lon = locData[0]['lon'];
    final fullPlace = locData[0]['display_name'];

    final url = Uri.parse(
        'https://api.tomorrow.io/v4/weather/forecast?location=$lat,$lon&apikey=$_tomorrowKey&units=metric');

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }

    final data = jsonDecode(response.body);

    // -------------------------
    // Parse current conditions with fallbacks:
    // try minutely -> hourly[0] -> daily[0]
    // Also use precipitationType fallback when weatherCode missing.
    // -------------------------
    Map<String, dynamic> current = <String, dynamic>{};
    int weatherCode = 0;
    String descriptionText = 'Unknown';

    try {
      final timelines = (data['timelines'] is Map) ? data['timelines'] as Map<String, dynamic> : null;

      // Try minutely first (if present)
      if (timelines != null &&
          timelines['minutely'] != null &&
          (timelines['minutely'] as List).isNotEmpty) {
        final min0 = timelines['minutely'][0] as Map<String, dynamic>;
        current = (min0['values'] as Map).cast<String, dynamic>();
        weatherCode = (current['weatherCode'] ?? 0) is int
            ? (current['weatherCode'] ?? 0) as int
            : int.tryParse((current['weatherCode'] ?? 0).toString()) ?? 0;
      }

      // Fallback to hourly[0]
      if ((weatherCode == 0 || weatherCode == null) &&
          timelines != null &&
          timelines['hourly'] != null &&
          (timelines['hourly'] as List).isNotEmpty) {
        final hr0 = timelines['hourly'][0] as Map<String, dynamic>;
        final hrValues = (hr0['values'] as Map).cast<String, dynamic>();
        final hrCode = (hrValues['weatherCode'] ?? 0);
        weatherCode = (hrCode is int) ? hrCode : int.tryParse(hrCode.toString()) ?? weatherCode;
        // Copy temperature/humidity/windSpeed if minutely didn't have them
        current['temperature'] = hrValues['temperature'] ?? current['temperature'];
        current['humidity'] = hrValues['humidity'] ?? current['humidity'];
        current['windSpeed'] = hrValues['windSpeed'] ?? current['windSpeed'];
      }

      // Final fallback to daily[0] (use weatherCodeMax or weatherCode)
      if ((weatherCode == 0 || weatherCode == null) &&
          timelines != null &&
          timelines['daily'] != null &&
          (timelines['daily'] as List).isNotEmpty) {
        final d0 = timelines['daily'][0] as Map<String, dynamic>;
        final dValues = (d0['values'] as Map).cast<String, dynamic>();
        final dCode = (dValues['weatherCodeMax'] ?? dValues['weatherCode'] ?? 0);
        weatherCode = (dCode is int) ? dCode : int.tryParse(dCode.toString()) ?? weatherCode;
      }
    } catch (e) {
      // keep defaults if parsing fails
    }

    // If weatherCode is still missing, try precipitationType as fallback
    try {
      final precip = (current['precipitationType'] ?? current['precipitation_type'] ?? 0);
      final precipitation = (precip is int) ? precip : int.tryParse(precip.toString()) ?? 0;

      if ((weatherCode == 0 || weatherCode == null) && precipitation != 0) {
        switch (precipitation) {
          case 1: // Rain
            weatherCode = 4001;
            break;
          case 2: // Snow
            weatherCode = 5000;
            break;
          case 3: // Freezing Rain
            weatherCode = 6001;
            break;
          case 4: // Ice Pellets
            weatherCode = 7000;
            break;
          default:
            break;
        }
      }

      // optional intensity -> heavy rain mapping
      final precipIntensity = (current['precipitationIntensity'] ?? current['precipitation_intensity'] ?? 0);
      final intensityVal = (precipIntensity is num) ? precipIntensity.toDouble() : double.tryParse(precipIntensity.toString()) ?? 0.0;
      if (precipitation == 1 && intensityVal > 1.5) {
        weatherCode = 4201; // heavy rain
      }
    } catch (e) {
      // ignore fallback parse errors
    }

    // Numeric parsing with safe conversions for display fields
    final currentTemp = (current['temperature'] ?? 0);
    final currentTempDouble = (currentTemp is num) ? currentTemp.toDouble() : double.tryParse(currentTemp.toString()) ?? 0.0;
    final humidityVal = (current['humidity'] ?? 0);
    final humidity = (humidityVal is int) ? humidityVal : int.tryParse(humidityVal.toString()) ?? 0;
    final wind = (current['windSpeed'] ?? 0);
    final windSpeed = (wind is num) ? wind.toDouble() : double.tryParse(wind.toString()) ?? 0.0;

    // Description based on numeric code (still helpful as readable text)
    descriptionText = _getWeatherDescription(weatherCode);

    // Use the local now as timestamp for current conditions
    final nowLocal = DateTime.now().toLocal();
    final emoji = _getWeatherEmoji(
      weatherCode,
      timestamp: nowLocal,
      description: descriptionText,
    );

    // -------------------------
    // Parse hourly forecast (next 12 hours from current hour)
    // -------------------------
    final nowUtc = DateTime.now().toUtc();
    final currentHour = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, nowUtc.hour);

    final hourlyRaw = (data['timelines'] != null && data['timelines']['hourly'] != null)
        ? data['timelines']['hourly'] as List
        : <dynamic>[];

    final hourly = hourlyRaw
        .map<HourlyWeather?>((item) {
          final timeStr = item['time'] as String?;
          final timestamp = timeStr != null ? DateTime.tryParse(timeStr) : null;
          if (timestamp == null || timestamp.isBefore(currentHour)) return null;

          final values = (item['values'] as Map).cast<String, dynamic>();
          final tempVal = (values['temperature'] ?? 0);
          final temp = (tempVal is num) ? tempVal.toDouble() : double.tryParse(tempVal.toString()) ?? 0.0;
          final codeVal = (values['weatherCode'] ?? 0);
          final code = (codeVal is int) ? codeVal : int.tryParse(codeVal.toString()) ?? 0;

          // Optional description if available
          final desc = _getWeatherDescription(code);

          return HourlyWeather(
            time: timestamp,
            temp: temp,
            emoji: _getWeatherEmoji(code, timestamp: timestamp, description: desc),
          );
        })
        .whereType<HourlyWeather>()
        .take(12)
        .toList();

    // -------------------------
    // Parse daily forecast: Exclude today, take next 6
    // -------------------------
    final todayUtc = DateTime.now().toUtc();
    final dailyRaw = (data['timelines'] != null && data['timelines']['daily'] != null)
        ? data['timelines']['daily'] as List
        : <dynamic>[];

    final daily = dailyRaw
        .map<DailyWeather?>((item) {
          final dateStr = item['time'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          if (date == null) return null;

          final isSameDate = date.year == todayUtc.year &&
                             date.month == todayUtc.month &&
                             date.day == todayUtc.day;

          if (isSameDate) return null; // Exclude today

          final values = (item['values'] as Map).cast<String, dynamic>();
          final minVal = (values['temperatureMin'] ?? 0);
          final minTemp = (minVal is num) ? minVal.toDouble() : double.tryParse(minVal.toString()) ?? 0.0;
          final maxVal = (values['temperatureMax'] ?? 0);
          final maxTemp = (maxVal is num) ? maxVal.toDouble() : double.tryParse(maxVal.toString()) ?? 0.0;
          final codeVal = (values['weatherCodeMax'] ?? values['weatherCode'] ?? 0);
          final code = (codeVal is int) ? codeVal : int.tryParse(codeVal.toString()) ?? 0;

          // Use the day's noon as the timestamp for day/night decision on daily entries
          final midday = DateTime(date.year, date.month, date.day, 12);

          return DailyWeather(
            date: date,
            day: _getDayName(date.weekday),
            tempMin: minTemp,
            tempMax: maxTemp,
            emoji: _getWeatherEmoji(code, timestamp: midday, description: _getWeatherDescription(code)),
          );
        })
        .whereType<DailyWeather>()
        .take(6) // Only next 6 days
        .toList();

    return WeatherData(
      cityName: fullPlace,
      currentTemp: currentTempDouble,
      humidity: humidity,
      description: descriptionText,
      emoji: emoji,
      windSpeed: windSpeed,
      hourly: hourly,
      daily: daily,
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  String _getWeatherDescription(int code) {
    switch (code) {
      case 1000:
        return 'Clear';
      case 1100:
        return 'Mostly Clear';
      case 1101:
        return 'Partly Cloudy';
      case 1102:
        return 'Mostly Cloudy';
      case 1001:
        return 'Cloudy';
      case 4000:
        return 'Drizzle';
      case 4001:
        return 'Rain';
      case 4200:
        return 'Light Rain';
      case 4201:
        return 'Heavy Rain';
      case 5000:
        return 'Snow';
      case 5100:
        return 'Light Snow';
      case 5101:
        return 'Heavy Snow';
      case 6000:
        return 'Freezing Drizzle';
      case 6001:
        return 'Freezing Rain';
      case 6200:
        return 'Light Freezing Rain';
      case 6201:
        return 'Heavy Freezing Rain';
      case 7000:
        return 'Ice Pellets';
      case 7101:
        return 'Heavy Ice Pellets';
      case 7102:
        return 'Light Ice Pellets';
      case 8000:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  /// Decide if the given timestamp corresponds to local daytime.
  /// Uses timestamp.toLocal().hour and simple 6..18 rule as fallback.
  bool _isDayForTimestamp(DateTime timestamp) {
    try {
      final local = timestamp.toLocal();
      final h = local.hour;
      // Consider 6:00..17:59 as day. This is a simple, robust rule if sunrise/sunset are not available.
      return h >= 6 && h < 18;
    } catch (e) {
      // On error assume day (safer for UI)
      return true;
    }
  }

  /// Get emoji for a weather code. If timestamp is provided, the emoji will reflect
  /// day/night for that timestamp. If not provided, uses current local time.
  /// Also inspects `description` text as a fallback when code is unknown.
    /// Get emoji for a weather code. If timestamp is provided, the emoji will reflect
  /// day/night for that timestamp. If not provided, uses current local time.
  /// Also inspects `description` text as a fallback when code is unknown.
  String _getWeatherEmoji(int code, {DateTime? timestamp, String? description}) {
    final isDay = (timestamp != null)
        ? _isDayForTimestamp(timestamp)
        : _isDayForTimestamp(DateTime.now());

    switch (code) {
      case 1100: // Mostly Clear
        return isDay ? '🌤️' : '🌙';
      case 1101: // Partly Cloudy
      case 1102: // Mostly Cloudy
        return isDay ? '🌤️' : '☁️🌙';
      case 1001: // Cloudy
        return isDay ? '☁️' : '☁️🌙';
      case 4000: // Drizzle
      case 4200: // Light Rain
        return isDay ? '🌦️' : '🌧️🌙';
      case 4001: // Rain
      case 4201: // Heavy Rain
        return isDay ? '🌧️' : '🌧️🌙';
      case 5000: // Snow
      case 5100: // Light Snow
        return isDay ? '❄️' : '❄️🌙';
      case 5101: // Heavy Snow
        return isDay ? '🌨️' : '🌨️🌙';
      case 6000: // Freezing Drizzle
      case 6001: // Freezing Rain
      case 6200:
      case 6201:
        return isDay ? '🌧️❄️' : '🌧️❄️🌙';
      case 7000:
      case 7102:
        return isDay ? '🧊' : '🧊🌙';
      case 7101:
        return isDay ? '🧊❄️' : '🧊❄️🌙';
      case 8000: // Thunderstorm
        return isDay ? '⛈️' : '⛈️🌙';
      case 1000: // Clear (moved last intentionally)
        return isDay ? '☀️' : '🌙';
      default:
        // fallback: inspect description text for keywords (case-insensitive)
        if (description != null) {
          final d = description.toLowerCase();
          if (d.contains('rain') || d.contains('shower') || d.contains('drizzle')) {
            return isDay ? '🌦️' : '🌧️🌙';
          }
          if (d.contains('snow') || d.contains('sleet')) {
            return isDay ? '❄️' : '❄️🌙';
          }
          if (d.contains('thunder') || d.contains('storm')) {
            return isDay ? '⛈️' : '⛈️🌙';
          }
          if (d.contains('cloud')) {
            return isDay ? '☁️' : '☁️🌙';
          }
          if (d.contains('clear') || d.contains('sun')) {
            return isDay ? '☀️' : '🌙';
          }
        }
        return isDay ? '🌈' : '🌈🌙';
    }
  }
}