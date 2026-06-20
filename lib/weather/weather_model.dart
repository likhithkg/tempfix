enum AlertLevel { low, medium, high }

class FarmAdvisory {
  final String message;
  final String icon;
  final AlertLevel level;
  const FarmAdvisory({required this.message, required this.icon, required this.level});
}

class DiseaseRisk {
  final String name;
  final String icon;
  final AlertLevel level;
  const DiseaseRisk({required this.name, required this.icon, required this.level});
}

enum SprayingIndex { excellent, good, poor }
enum HarvestIndex { excellent, good, poor }
enum IrrigationNeed { required_, optional_, notRequired }
enum FieldWorkIndex { excellent, moderate, poor }

class AgriculturalIndexes {
  final SprayingIndex spraying;
  final HarvestIndex harvest;
  final IrrigationNeed irrigation;
  final FieldWorkIndex fieldWork;
  const AgriculturalIndexes({
    required this.spraying,
    required this.harvest,
    required this.irrigation,
    required this.fieldWork,
  });
}

class RainIntelligence {
  final bool rainExpected;
  final int hoursUntilRain;
  final double expectedRainfallMm;
  final int durationHours;
  final DateTime? rainStartTime;
  const RainIntelligence({
    required this.rainExpected,
    required this.hoursUntilRain,
    required this.expectedRainfallMm,
    required this.durationHours,
    this.rainStartTime,
  });
}

class WeatherData {
  final String cityName;
  final double currentTemp;
  final double feelsLike;
  final int humidity;
  final String description;
  final String emoji;
  final double windSpeed;
  final int windDirection;
  final double uvIndex;
  final double tempHigh;
  final double tempLow;
  final int precipitationProbability;
  final DateTime? sunrise;
  final DateTime? sunset;
  final bool isDay;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;
  final List<FarmAdvisory> advisories;
  final List<DiseaseRisk> diseaseRisks;
  final AgriculturalIndexes agIndexes;
  final RainIntelligence rainIntelligence;
  final String irrigationRecommendation;

  const WeatherData({
    required this.cityName,
    required this.currentTemp,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.emoji,
    required this.windSpeed,
    required this.windDirection,
    required this.uvIndex,
    required this.tempHigh,
    required this.tempLow,
    required this.precipitationProbability,
    this.sunrise,
    this.sunset,
    required this.isDay,
    required this.hourly,
    required this.daily,
    required this.advisories,
    required this.diseaseRisks,
    required this.agIndexes,
    required this.rainIntelligence,
    required this.irrigationRecommendation,
  });
}

class HourlyWeather {
  final DateTime time;
  final double temp;
  final String emoji;
  final int weatherCode;
  final int rainProbability;
  final double windSpeed;
  final int humidity;
  final double uvIndex;

  const HourlyWeather({
    required this.time,
    required this.temp,
    required this.emoji,
    required this.weatherCode,
    required this.rainProbability,
    required this.windSpeed,
    required this.humidity,
    required this.uvIndex,
  });
}

class DailyWeather {
  final DateTime date;
  final String day;
  final String description;
  final double tempMin;
  final double tempMax;
  final String emoji;
  final int weatherCode;
  final int rainProbability;
  final double windSpeed;
  final double uvIndex;
  final double precipitationSum;
  final DateTime? sunrise;
  final DateTime? sunset;

  const DailyWeather({
    required this.date,
    required this.day,
    required this.description,
    required this.tempMin,
    required this.tempMax,
    required this.emoji,
    required this.weatherCode,
    required this.rainProbability,
    required this.windSpeed,
    required this.uvIndex,
    required this.precipitationSum,
    this.sunrise,
    this.sunset,
  });
}
