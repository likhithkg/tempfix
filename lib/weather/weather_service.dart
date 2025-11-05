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

    // Parse current conditions
    final current = data['timelines']['minutely'][0]['values'];
    final currentTemp = (current['temperature'] ?? 0).toDouble();
    final humidity = (current['humidity'] ?? 0).toInt();
    final windSpeed = (current['windSpeed'] ?? 0).toDouble();
    final weatherCode = current['weatherCode'] ?? 0;
    final description = _getWeatherDescription(weatherCode);
    final emoji = _getWeatherEmoji(weatherCode);

    // Parse hourly forecast (next 12 hours from current hour)
    final now = DateTime.now().toUtc();
    final currentHour = DateTime.utc(now.year, now.month, now.day, now.hour);

    final hourlyRaw = data['timelines']['hourly'];
    final hourly = hourlyRaw
        .map<HourlyWeather?>((item) {
          final timestamp = DateTime.tryParse(item['time']);
          if (timestamp == null || timestamp.isBefore(currentHour)) return null;

          final values = item['values'];
          final temp = (values['temperature'] ?? 0).toDouble();
          final code = values['weatherCode'] ?? 0;

          return HourlyWeather(
            time: timestamp,
            temp: temp,
            emoji: _getWeatherEmoji(code),
          );
        })
        .whereType<HourlyWeather>()
        .take(12)
        .toList();

    // Parse daily forecast: Exclude today, take next 6
    final today = DateTime.now().toUtc();
    final dailyRaw = data['timelines']['daily'];

    final daily = dailyRaw
        .map<DailyWeather?>((item) {
          final date = DateTime.tryParse(item['time']);
          if (date == null) return null;

          final isSameDate = date.year == today.year &&
                             date.month == today.month &&
                             date.day == today.day;

          if (isSameDate) return null; // Exclude today

          final values = item['values'];
          final minTemp = (values['temperatureMin'] ?? 0).toDouble();
          final maxTemp = (values['temperatureMax'] ?? 0).toDouble();
          final code = values['weatherCodeMax'] ?? 0;

          return DailyWeather(
            date: date,
            day: _getDayName(date.weekday),
            tempMin: minTemp,
            tempMax: maxTemp,
            emoji: _getWeatherEmoji(code),
          );
        })
        .whereType<DailyWeather>()
        .take(6) // Only next 6 days
        .toList();

    return WeatherData(
      cityName: fullPlace,
      currentTemp: currentTemp,
      humidity: humidity,
      description: description,
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
    case 1000: return 'Clear';
    case 1100: return 'Mostly Clear';
    case 1101: return 'Partly Cloudy';
    case 1102: return 'Mostly Cloudy';
    case 1001: return 'Cloudy';
    case 4000: return 'Drizzle';
    case 4001: return 'Rain';
    case 4200: return 'Light Rain';
    case 4201: return 'Heavy Rain';
    case 5000: return 'Snow';
    case 5100: return 'Light Snow';
    case 5101: return 'Heavy Snow';
    case 6000: return 'Freezing Drizzle';
    case 6001: return 'Freezing Rain';
    case 6200: return 'Light Freezing Rain';
    case 6201: return 'Heavy Freezing Rain';
    case 7000: return 'Ice Pellets';
    case 7101: return 'Heavy Ice Pellets';
    case 7102: return 'Light Ice Pellets';
    case 8000: return 'Thunderstorm';
    default: return 'Unknown';
  }
}

String _getWeatherEmoji(int code) {
  switch (code) {
    case 1000: // Clear
    case 1100: return '☀';
    case 1101: // Partly Cloudy
    case 1102: return '🌤';
    case 1001: return '☁';
    case 4000: return '🌦'; // Drizzle
    case 4200: return '🌦'; // Light Rain
    case 4001: // Rain
    case 4201: return '🌧'; // Heavy Rain
    case 6000: // Freezing Drizzle
    case 6001: // Freezing Rain
    case 6200: // Light Freezing Rain
    case 6201: return '🌧❄'; // Heavy Freezing Rain
    case 5000: // Snow
    case 5100: return '❄';
    case 5101: return '🌨'; // Heavy Snow
    case 7000: return '🧊'; // Ice Pellets
    case 7101: return '🧊❄'; // Heavy Ice Pellets
    case 7102: return '🧊'; // Light Ice Pellets
    case 8000: return '⛈'; // Thunderstorm
    default: return '🌈'; // Default/Unknown
  }
}
}