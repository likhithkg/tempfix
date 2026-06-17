import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_model.dart';

class WeatherService {

  final String _locationIqKey =
      'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

  Future<WeatherData> fetchWeather(String place) async {

    // LOCATION SEARCH
    final locUrl = Uri.parse(
      'https://us1.locationiq.com/v1/search.php?key=$_locationIqKey&q=$place&format=json',
    );

    final locRes = await http.get(locUrl);

    if (locRes.statusCode != 200) {
      throw Exception('Failed to fetch location');
    }

    final locData = jsonDecode(locRes.body);

    final lat = locData[0]['lat'];
    final lon = locData[0]['lon'];
    final fullPlace = locData[0]['display_name'];

    // OPEN METEO API
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
      '&hourly=temperature_2m,weather_code'
      '&daily=temperature_2m_max,temperature_2m_min,weather_code'
      '&timezone=auto',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }

    final data = jsonDecode(response.body);

    // CURRENT WEATHER
    final current = data['current'];

    final currentTemp =
        (current['temperature_2m'] ?? 0).toDouble();

    final humidity =
        (current['relative_humidity_2m'] ?? 0) as int;

    final windSpeed =
        (current['wind_speed_10m'] ?? 0).toDouble();

    final weatherCode =
        (current['weather_code'] ?? 0) as int;

    final description =
        _getWeatherDescription(weatherCode);

    final emoji = _getWeatherEmoji(
      weatherCode,
      timestamp: DateTime.now(),
    );

    // HOURLY FORECAST
    final hourlyTimes = data['hourly']['time'];
    final hourlyTemps = data['hourly']['temperature_2m'];
    final hourlyCodes = data['hourly']['weather_code'];

    List<HourlyWeather> hourly = [];

    for (int i = 0; i < hourlyTimes.length; i++) {

      final time = DateTime.parse(hourlyTimes[i]);

      if (time.isAfter(DateTime.now())) {

        final code = hourlyCodes[i];

        hourly.add(
          HourlyWeather(
            time: time,
            temp: hourlyTemps[i].toDouble(),
            emoji: _getWeatherEmoji(
              code,
              timestamp: time,
            ),
          ),
        );
      }

      if (hourly.length >= 12) break;
    }

    // DAILY FORECAST
    final dailyTimes = data['daily']['time'];
    final minTemps = data['daily']['temperature_2m_min'];
    final maxTemps = data['daily']['temperature_2m_max'];
    final dailyCodes = data['daily']['weather_code'];

    List<DailyWeather> daily = [];

    for (int i = 1; i < dailyTimes.length; i++) {

      final date = DateTime.parse(dailyTimes[i]);
      final code = dailyCodes[i];

      daily.add(
        DailyWeather(
          date: date,
          day: _getDayName(date.weekday),
          tempMin: minTemps[i].toDouble(),
          tempMax: maxTemps[i].toDouble(),
          emoji: _getWeatherEmoji(
            code,
            timestamp: date,
          ),
        ),
      );
    }

    return WeatherData(
      cityName: fullPlace,
      currentTemp: currentTemp,
      humidity: humidity,
      description: description,
      emoji: emoji,
      windSpeed: windSpeed,
      hourly: daily.isNotEmpty ? hourly : [],
      daily: daily,
    );
  }

  // DAY NAME
  String _getDayName(int weekday) {

    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    return days[(weekday - 1) % 7];
  }

  // WEATHER DESCRIPTION
  String _getWeatherDescription(int code) {

    switch (code) {

      case 0:
        return 'Clear';

      case 1:
      case 2:
      case 3:
        return 'Cloudy';

      case 45:
      case 48:
        return 'Fog';

      case 51:
      case 53:
      case 55:
        return 'Drizzle';

      case 61:
      case 63:
      case 65:
        return 'Rain';

      case 71:
      case 73:
      case 75:
        return 'Snow';

      case 95:
        return 'Thunderstorm';

      default:
        return 'Unknown';
    }
  }

  // DAY/NIGHT CHECK
  bool _isDayForTimestamp(DateTime timestamp) {

    final local = timestamp.toLocal();

    final h = local.hour;

    return h >= 6 && h < 18;
  }

  // WEATHER EMOJI
  String _getWeatherEmoji(
    int code, {
    DateTime? timestamp,
  }) {

    final isDay = (timestamp != null)
        ? _isDayForTimestamp(timestamp)
        : _isDayForTimestamp(DateTime.now());

    switch (code) {

      case 0:
        return isDay ? '☀️' : '🌙';

      case 1:
      case 2:
      case 3:
        return isDay ? '⛅' : '☁️🌙';

      case 45:
      case 48:
        return '🌫️';

      case 51:
      case 53:
      case 55:
        return '🌦️';

      case 61:
      case 63:
      case 65:
        return isDay ? '🌧️' : '🌧️🌙';

      case 71:
      case 73:
      case 75:
        return '❄️';

      case 95:
        return '⛈️';

      default:
        return '🌈';
    }
  }

  // FARM ADVISORY
  List<String> getFarmAlerts(
    double temp,
    int humidity,
    double wind,
    List<DailyWeather> daily,
  ) {

    List<String> alerts = [];

    if (temp > 35) {
      alerts.add(
        "🌡 High temperature — irrigate crops.",
      );
    }

    if (humidity > 85) {
      alerts.add(
        "🍄 High humidity — fungal disease risk.",
      );
    }

    if (wind > 8) {
      alerts.add(
        "🌬 Strong wind — avoid pesticide spraying.",
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        "✅ Weather conditions are normal for farming.",
      );
    }

    return alerts;
  }

  // RAIN ADVISORY
  List<String> getRainSprayAdvisory(
    List<HourlyWeather> hourly,
  ) {

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

      alerts.add(
        "🌧 Rain expected in next 3 hours.",
      );

      alerts.add(
        "🚫 Avoid pesticide spraying.",
      );

      alerts.add(
        "💧 Delay irrigation.",
      );

    } else {

      alerts.add(
        "✅ No rain expected in next 3 hours.",
      );

      alerts.add(
        "🌾 Safe time for pesticide spraying.",
      );
    }

    return alerts;
  }
}