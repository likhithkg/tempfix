
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

    Map<String, dynamic> current = <String, dynamic>{};

    int weatherCode = 0;
    String descriptionText = 'Unknown';

    try {

      final timelines = (data['timelines'] is Map)
          ? data['timelines'] as Map<String, dynamic>
          : null;

      if (timelines != null &&
          timelines['minutely'] != null &&
          (timelines['minutely'] as List).isNotEmpty) {

        final min0 = timelines['minutely'][0] as Map<String, dynamic>;

        current = (min0['values'] as Map).cast<String, dynamic>();

        weatherCode = (current['weatherCode'] ?? 0) is int
            ? (current['weatherCode'] ?? 0) as int
            : int.tryParse((current['weatherCode'] ?? 0).toString()) ?? 0;
      }

      if ((weatherCode == 0) &&
          timelines != null &&
          timelines['hourly'] != null &&
          (timelines['hourly'] as List).isNotEmpty) {

        final hr0 = timelines['hourly'][0] as Map<String, dynamic>;

        final hrValues = (hr0['values'] as Map).cast<String, dynamic>();

        final hrCode = (hrValues['weatherCode'] ?? 0);

        weatherCode =
            (hrCode is int) ? hrCode : int.tryParse(hrCode.toString()) ?? 0;

        current['temperature'] = hrValues['temperature'];
        current['humidity'] = hrValues['humidity'];
        current['windSpeed'] = hrValues['windSpeed'];
      }

      if ((weatherCode == 0) &&
          timelines != null &&
          timelines['daily'] != null &&
          (timelines['daily'] as List).isNotEmpty) {

        final d0 = timelines['daily'][0] as Map<String, dynamic>;

        final dValues = (d0['values'] as Map).cast<String, dynamic>();

        final dCode = (dValues['weatherCodeMax'] ??
            dValues['weatherCode'] ??
            0);

        weatherCode =
            (dCode is int) ? dCode : int.tryParse(dCode.toString()) ?? 0;
      }

    } catch (e) {}

    try {

      final precip =
          (current['precipitationType'] ?? current['precipitation_type'] ?? 0);

      final precipitation =
          (precip is int) ? precip : int.tryParse(precip.toString()) ?? 0;

      if ((weatherCode == 0) && precipitation != 0) {

        switch (precipitation) {

          case 1:
            weatherCode = 4001;
            break;

          case 2:
            weatherCode = 5000;
            break;

          case 3:
            weatherCode = 6001;
            break;

          case 4:
            weatherCode = 7000;
            break;
        }
      }

      final precipIntensity =
          (current['precipitationIntensity'] ??
              current['precipitation_intensity'] ??
              0);

      final intensityVal = (precipIntensity is num)
          ? precipIntensity.toDouble()
          : double.tryParse(precipIntensity.toString()) ?? 0.0;

      if (precipitation == 1 && intensityVal > 1.5) {
        weatherCode = 4201;
      }

    } catch (e) {}

    final currentTemp = (current['temperature'] ?? 0);

    final currentTempDouble = (currentTemp is num)
        ? currentTemp.toDouble()
        : double.tryParse(currentTemp.toString()) ?? 0.0;

    final humidityVal = (current['humidity'] ?? 0);

    final humidity =
        (humidityVal is int) ? humidityVal : int.tryParse(humidityVal.toString()) ?? 0;

    final wind = (current['windSpeed'] ?? 0);

    final windSpeed =
        (wind is num) ? wind.toDouble() : double.tryParse(wind.toString()) ?? 0.0;

    descriptionText = _getWeatherDescription(weatherCode);

    final nowLocal = DateTime.now().toLocal();

    final emoji = _getWeatherEmoji(
      weatherCode,
      timestamp: nowLocal,
      description: descriptionText,
    );

    // --------------------------
    // HOURLY FORECAST (FUTURE ONLY)
    // --------------------------

    final nowUtc = DateTime.now().toUtc();

    final hourlyRaw = (data['timelines'] != null &&
            data['timelines']['hourly'] != null)
        ? data['timelines']['hourly'] as List
        : <dynamic>[];

    final hourly = hourlyRaw
        .map<HourlyWeather?>((item) {

          final timeStr = item['time'] as String?;

          final timestamp =
              timeStr != null ? DateTime.tryParse(timeStr) : null;

          // Only future hours
          if (timestamp == null || !timestamp.isAfter(nowUtc)) return null;

          final values = (item['values'] as Map).cast<String, dynamic>();

          final tempVal = (values['temperature'] ?? 0);

          final temp = (tempVal is num)
              ? tempVal.toDouble()
              : double.tryParse(tempVal.toString()) ?? 0.0;

          final codeVal = (values['weatherCode'] ?? 0);

          final code =
              (codeVal is int) ? codeVal : int.tryParse(codeVal.toString()) ?? 0;

          final desc = _getWeatherDescription(code);

          return HourlyWeather(
            time: timestamp.toLocal(),
            temp: temp,
            emoji: _getWeatherEmoji(
                code,
                timestamp: timestamp,
                description: desc),
          );

        })
        .whereType<HourlyWeather>()
        .take(12)
        .toList();

    // --------------------------
    // DAILY FORECAST
    // --------------------------

    final todayUtc = DateTime.now().toUtc();

    final dailyRaw = (data['timelines'] != null &&
            data['timelines']['daily'] != null)
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

          if (isSameDate) return null;

          final values = (item['values'] as Map).cast<String, dynamic>();

          final minVal = (values['temperatureMin'] ?? 0);

          final minTemp = (minVal is num)
              ? minVal.toDouble()
              : double.tryParse(minVal.toString()) ?? 0.0;

          final maxVal = (values['temperatureMax'] ?? 0);

          final maxTemp = (maxVal is num)
              ? maxVal.toDouble()
              : double.tryParse(maxVal.toString()) ?? 0.0;

          final codeVal =
              (values['weatherCodeMax'] ?? values['weatherCode'] ?? 0);

          final code =
              (codeVal is int) ? codeVal : int.tryParse(codeVal.toString()) ?? 0;

          final midday = DateTime(date.year, date.month, date.day, 12);

          return DailyWeather(
            date: date,
            day: _getDayName(date.weekday),
            tempMin: minTemp,
            tempMax: maxTemp,
            emoji: _getWeatherEmoji(
                code,
                timestamp: midday,
                description: _getWeatherDescription(code)),
          );

        })
        .whereType<DailyWeather>()
        .take(6)
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

      case 4001:
        return 'Rain';

      case 4201:
        return 'Heavy Rain';

      case 5000:
        return 'Snow';

      case 8000:
        return 'Thunderstorm';

      default:
        return 'Unknown';
    }
  }

  bool _isDayForTimestamp(DateTime timestamp) {

    final local = timestamp.toLocal();

    final h = local.hour;

    return h >= 6 && h < 18;
  }

  String _getWeatherEmoji(int code,
      {DateTime? timestamp, String? description}) {

    final isDay = (timestamp != null)
        ? _isDayForTimestamp(timestamp)
        : _isDayForTimestamp(DateTime.now());

    switch (code) {

      case 1000:
        return isDay ? '☀️' : '🌙';

      case 1101:
        return isDay ? '🌤️' : '☁️🌙';

      case 1001:
        return isDay ? '☁️' : '☁️🌙';

      case 4001:
      case 4201:
        return isDay ? '🌧️' : '🌧️🌙';

      case 8000:
        return isDay ? '⛈️' : '⛈️🌙';

      default:
        return isDay ? '🌈' : '🌈🌙';
    }
  }

  // FARM ADVISORY

  List<String> getFarmAlerts(
      double temp, int humidity, double wind, List<DailyWeather> daily) {

    List<String> alerts = [];

    if (temp > 35) {
      alerts.add("🌡 High temperature — irrigate crops.");
    }

    if (humidity > 85) {
      alerts.add("🍄 High humidity — fungal disease risk.");
    }

    if (wind > 8) {
      alerts.add("🌬 Strong wind — avoid pesticide spraying.");
    }

    if (alerts.isEmpty) {
      alerts.add("✅ Weather conditions are normal for farming.");
    }

    return alerts;
  }

  // RAIN ADVISORY

  List<String> getRainSprayAdvisory(List<HourlyWeather> hourly) {

    List<String> alerts = [];

    bool rainSoon = false;

    for (var h in hourly.take(3)) {

      if (h.emoji.contains("🌧") ||
          h.emoji.contains("🌦") ||
          h.emoji.contains("⛈")) {

        rainSoon = true;
      }
    }

    if (rainSoon) {

      alerts.add("🌧 Rain expected in next 3 hours.");
      alerts.add("🚫 Avoid pesticide spraying.");
      alerts.add("💧 Delay irrigation.");

    } else {

      alerts.add("✅ No rain expected in next 3 hours.");
      alerts.add("🌾 Safe time for pesticide spraying.");
    }

    return alerts;
  }
}