class WeatherData {
  final String cityName;
  final double currentTemp;
  final int humidity;
  final String description;
  final String emoji;
  final double windSpeed;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  WeatherData({
    required this.cityName,
    required this.currentTemp,
    required this.humidity,
    required this.description,
    required this.emoji,
    required this.windSpeed,
    required this.hourly,
    required this.daily,
  });
}

class HourlyWeather {
  final DateTime time;
  final double temp;
  final String emoji;

  HourlyWeather({
    required this.time,
    required this.temp,
    required this.emoji,
  });
}

class DailyWeather {
  final DateTime date;
  final String day;
  final double tempMin;
  final double tempMax;
  final String emoji;

  DailyWeather({
    required this.date,
    required this.day,
    required this.tempMin,
    required this.tempMax,
    required this.emoji,
  });
}