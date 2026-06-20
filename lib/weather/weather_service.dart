import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_model.dart';

class WeatherService {
  final String _locationIqKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';

  Future<WeatherData> fetchWeather(String place) async {
    final locUrl = Uri.parse(
      'https://us1.locationiq.com/v1/search.php?key=$_locationIqKey&q=$place&format=json',
    );
    final locRes = await http.get(locUrl);
    if (locRes.statusCode != 200) throw Exception('Failed to fetch location');
    final locData = jsonDecode(locRes.body) as List;
    final lat = locData[0]['lat'];
    final lon = locData[0]['lon'];
    final fullPlace = locData[0]['display_name'] as String;

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'precipitation,weather_code,wind_speed_10m,wind_direction_10m,is_day'
      '&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,'
      'weather_code,wind_speed_10m,uv_index'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
      'sunrise,sunset,uv_index_max,precipitation_sum,'
      'precipitation_probability_max,wind_speed_10m_max'
      '&timezone=auto&forecast_days=7',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Failed to fetch weather');
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final cur = data['current'] as Map<String, dynamic>;
    final currentTemp = (cur['temperature_2m'] as num).toDouble();
    final feelsLike = (cur['apparent_temperature'] as num? ?? currentTemp).toDouble();
    final humidity = (cur['relative_humidity_2m'] as num).toInt();
    final windSpeed = (cur['wind_speed_10m'] as num).toDouble();
    final windDirection = (cur['wind_direction_10m'] as num? ?? 0).toInt();
    final weatherCode = (cur['weather_code'] as num).toInt();
    final isDay = (cur['is_day'] as num? ?? 1).toInt() == 1;
    final description = _desc(weatherCode);
    final emoji = _emoji(weatherCode, isDay: isDay);

    final hTimes = data['hourly']['time'] as List;
    final hTemps = data['hourly']['temperature_2m'] as List;
    final hCodes = data['hourly']['weather_code'] as List;
    final hRain = data['hourly']['precipitation_probability'] as List;
    final hWind = data['hourly']['wind_speed_10m'] as List;
    final hHum = data['hourly']['relative_humidity_2m'] as List;
    final hUv = data['hourly']['uv_index'] as List;

    final now = DateTime.now();
    int? curHourIdx;
    final List<HourlyWeather> hourly = [];

    for (int i = 0; i < hTimes.length; i++) {
      final t = DateTime.parse(hTimes[i] as String);
      if (curHourIdx == null && t.hour == now.hour && t.day == now.day) {
        curHourIdx = i;
      }
      if (t.isAfter(now.subtract(const Duration(minutes: 30)))) {
        final code = (hCodes[i] as num).toInt();
        hourly.add(HourlyWeather(
          time: t,
          temp: (hTemps[i] as num).toDouble(),
          emoji: _emoji(code, isDay: t.hour >= 6 && t.hour < 18),
          weatherCode: code,
          rainProbability: (hRain[i] as num? ?? 0).toInt(),
          windSpeed: (hWind[i] as num).toDouble(),
          humidity: (hHum[i] as num).toInt(),
          uvIndex: (hUv[i] as num? ?? 0).toDouble(),
        ));
      }
      if (hourly.length >= 24) break;
    }

    final currentUv = (curHourIdx != null && curHourIdx < hUv.length)
        ? (hUv[curHourIdx] as num? ?? 0).toDouble()
        : 0.0;

    final dTimes = data['daily']['time'] as List;
    final dCodes = data['daily']['weather_code'] as List;
    final dMax = data['daily']['temperature_2m_max'] as List;
    final dMin = data['daily']['temperature_2m_min'] as List;
    final dSunrise = data['daily']['sunrise'] as List;
    final dSunset = data['daily']['sunset'] as List;
    final dUv = data['daily']['uv_index_max'] as List;
    final dPrecip = data['daily']['precipitation_sum'] as List;
    final dRainProb = data['daily']['precipitation_probability_max'] as List;
    final dWindMax = data['daily']['wind_speed_10m_max'] as List;

    final todayRainProb = (dRainProb[0] as num? ?? 0).toInt();
    final todayMax = (dMax[0] as num).toDouble();
    final todayMin = (dMin[0] as num).toDouble();
    final todaySunrise = DateTime.tryParse(dSunrise[0] as String? ?? '');
    final todaySunset = DateTime.tryParse(dSunset[0] as String? ?? '');

    final List<DailyWeather> daily = [];
    for (int i = 0; i < dTimes.length; i++) {
      final date = DateTime.parse(dTimes[i] as String);
      final code = (dCodes[i] as num).toInt();
      daily.add(DailyWeather(
        date: date,
        day: i == 0 ? 'Today' : _dayName(date.weekday),
        description: _desc(code),
        tempMin: (dMin[i] as num).toDouble(),
        tempMax: (dMax[i] as num).toDouble(),
        emoji: _emoji(code, isDay: true),
        weatherCode: code,
        rainProbability: (dRainProb[i] as num? ?? 0).toInt(),
        windSpeed: (dWindMax[i] as num).toDouble(),
        uvIndex: (dUv[i] as num? ?? 0).toDouble(),
        precipitationSum: (dPrecip[i] as num? ?? 0).toDouble(),
        sunrise: DateTime.tryParse(dSunrise[i] as String? ?? ''),
        sunset: DateTime.tryParse(dSunset[i] as String? ?? ''),
      ));
    }

    final rainIntel = _rainIntelligence(hourly);
    final advisories = _advisories(
      temp: currentTemp,
      humidity: humidity,
      windSpeed: windSpeed,
      rainProb: todayRainProb,
      daily: daily,
      rainIntel: rainIntel,
    );

    return WeatherData(
      cityName: fullPlace,
      currentTemp: currentTemp,
      feelsLike: feelsLike,
      humidity: humidity,
      description: description,
      emoji: emoji,
      windSpeed: windSpeed,
      windDirection: windDirection,
      uvIndex: currentUv,
      tempHigh: todayMax,
      tempLow: todayMin,
      precipitationProbability: todayRainProb,
      sunrise: todaySunrise,
      sunset: todaySunset,
      isDay: isDay,
      hourly: hourly,
      daily: daily,
      advisories: advisories,
      diseaseRisks: _diseaseRisks(temp: currentTemp, humidity: humidity, rainProb: todayRainProb),
      agIndexes: _agIndexes(
        temp: currentTemp,
        humidity: humidity,
        windSpeed: windSpeed,
        rainProb: todayRainProb,
        daily: daily,
      ),
      rainIntelligence: rainIntel,
      irrigationRecommendation: _irrigationRec(
        temp: currentTemp,
        humidity: humidity,
        rainProb: todayRainProb,
        rainIntel: rainIntel,
      ),
    );
  }

  List<FarmAdvisory> _advisories({
    required double temp,
    required int humidity,
    required double windSpeed,
    required int rainProb,
    required List<DailyWeather> daily,
    required RainIntelligence rainIntel,
  }) {
    final list = <FarmAdvisory>[];

    if (temp > 40) {
      list.add(const FarmAdvisory(message: 'Extreme heat — protect livestock and irrigate urgently.', icon: '🌡️', level: AlertLevel.high));
    } else if (temp > 35) {
      list.add(const FarmAdvisory(message: 'High temperature — irrigate crops, especially in afternoon.', icon: '🌡️', level: AlertLevel.medium));
    }

    if (rainProb > 70) {
      list.add(const FarmAdvisory(message: 'Heavy rain likely today — postpone field operations.', icon: '🌧️', level: AlertLevel.high));
    } else if (rainProb > 40) {
      list.add(const FarmAdvisory(message: 'Rain expected today — plan indoor tasks.', icon: '🌦️', level: AlertLevel.medium));
    }

    if (windSpeed > 10) {
      list.add(const FarmAdvisory(message: 'Strong winds — avoid pesticide spraying today.', icon: '🌬️', level: AlertLevel.high));
    } else if (windSpeed > 6) {
      list.add(const FarmAdvisory(message: 'Moderate winds — spray early morning for best results.', icon: '🌬️', level: AlertLevel.medium));
    } else if (rainProb < 20 && windSpeed < 4) {
      list.add(const FarmAdvisory(message: 'Excellent conditions for pesticide spraying.', icon: '✅', level: AlertLevel.low));
    }

    if (daily.length > 1 && daily[1].rainProbability > 60) {
      list.add(const FarmAdvisory(message: 'Rain expected tomorrow — harvest crops today if possible.', icon: '⚠️', level: AlertLevel.high));
    }

    if (humidity > 85) {
      list.add(const FarmAdvisory(message: 'High humidity — fungal disease risk elevated. Monitor crops.', icon: '🍄', level: AlertLevel.medium));
    }

    if (rainIntel.rainExpected && rainIntel.hoursUntilRain <= 3) {
      list.add(const FarmAdvisory(message: 'Rain arriving soon — delay irrigation and outdoor spraying.', icon: '💧', level: AlertLevel.medium));
    }

    if (list.isEmpty) {
      list.add(const FarmAdvisory(message: 'Good farming conditions today. Proceed with planned activities.', icon: '✅', level: AlertLevel.low));
    }

    return list;
  }

  List<DiseaseRisk> _diseaseRisks({
    required double temp,
    required int humidity,
    required int rainProb,
  }) {
    return [
      DiseaseRisk(
        name: 'Leaf Spot',
        icon: '🍃',
        level: (humidity > 80 && temp > 15 && temp < 32 && rainProb > 40)
            ? AlertLevel.high
            : (humidity > 70 && rainProb > 20)
                ? AlertLevel.medium
                : AlertLevel.low,
      ),
      DiseaseRisk(
        name: 'Fungal Disease',
        icon: '🍄',
        level: (humidity > 85 && rainProb > 50)
            ? AlertLevel.high
            : (humidity > 75 && rainProb > 30)
                ? AlertLevel.medium
                : AlertLevel.low,
      ),
      DiseaseRisk(
        name: 'Powdery Mildew',
        icon: '🌿',
        level: (humidity > 80 && temp > 10 && temp < 27)
            ? AlertLevel.high
            : (humidity > 65 && temp > 8 && temp < 30)
                ? AlertLevel.medium
                : AlertLevel.low,
      ),
    ];
  }

  AgriculturalIndexes _agIndexes({
    required double temp,
    required int humidity,
    required double windSpeed,
    required int rainProb,
    required List<DailyWeather> daily,
  }) {
    SprayingIndex spraying;
    if (windSpeed < 3 && rainProb < 20 && humidity < 80) {
      spraying = SprayingIndex.excellent;
    } else if (windSpeed < 6 && rainProb < 40) {
      spraying = SprayingIndex.good;
    } else {
      spraying = SprayingIndex.poor;
    }

    final next2Rain = daily.length > 1 ? daily[1].rainProbability : 0;
    HarvestIndex harvest;
    if (rainProb < 30 && next2Rain < 30 && temp > 18 && temp < 36) {
      harvest = HarvestIndex.excellent;
    } else if (rainProb < 55 && next2Rain < 55) {
      harvest = HarvestIndex.good;
    } else {
      harvest = HarvestIndex.poor;
    }

    IrrigationNeed irrigation;
    if (rainProb > 60) {
      irrigation = IrrigationNeed.notRequired;
    } else if (temp > 33 || humidity < 45) {
      irrigation = IrrigationNeed.required_;
    } else if (temp > 28 && rainProb < 50) {
      irrigation = IrrigationNeed.optional_;
    } else {
      irrigation = IrrigationNeed.notRequired;
    }

    FieldWorkIndex fieldWork;
    if (rainProb < 20 && windSpeed < 8 && temp > 15 && temp < 33) {
      fieldWork = FieldWorkIndex.excellent;
    } else if (rainProb < 55 && windSpeed < 12 && temp < 38) {
      fieldWork = FieldWorkIndex.moderate;
    } else {
      fieldWork = FieldWorkIndex.poor;
    }

    return AgriculturalIndexes(
      spraying: spraying,
      harvest: harvest,
      irrigation: irrigation,
      fieldWork: fieldWork,
    );
  }

  RainIntelligence _rainIntelligence(List<HourlyWeather> hourly) {
    final now = DateTime.now();
    int? startIdx;
    int endIdx = 0;

    for (int i = 0; i < hourly.length; i++) {
      final isRain = _isRainCode(hourly[i].weatherCode) || hourly[i].rainProbability > 45;
      if (isRain) {
        startIdx ??= i;
        endIdx = i;
      }
    }

    if (startIdx == null) {
      return const RainIntelligence(
        rainExpected: false,
        hoursUntilRain: 0,
        expectedRainfallMm: 0,
        durationHours: 0,
      );
    }

    final rainStart = hourly[startIdx].time;
    final rawHours = rainStart.difference(now).inHours;
    final duration = endIdx - startIdx + 1;

    return RainIntelligence(
      rainExpected: true,
      hoursUntilRain: rawHours < 0 ? 0 : rawHours,
      expectedRainfallMm: duration * 2.5,
      durationHours: duration,
      rainStartTime: rainStart,
    );
  }

  String _irrigationRec({
    required double temp,
    required int humidity,
    required int rainProb,
    required RainIntelligence rainIntel,
  }) {
    if (rainIntel.rainExpected && rainIntel.hoursUntilRain <= 6) {
      return 'No irrigation needed. Rain expected in ${rainIntel.hoursUntilRain}h.';
    }
    if (rainProb > 60) return 'Skip irrigation — high chance of rain today.';
    if (temp > 38 && humidity < 45) return 'Urgent irrigation needed — extreme heat and dry conditions.';
    if (temp > 33 && humidity < 55) return 'Irrigation recommended this evening.';
    if (humidity > 80) return 'Soil likely moist. Monitor before irrigating.';
    if (rainProb > 40) return 'Light irrigation only — some rain expected.';
    return 'Light irrigation may be beneficial today.';
  }

  bool _isRainCode(int code) =>
      (code >= 51 && code <= 67) ||
      (code >= 80 && code <= 82) ||
      code == 95 || code == 96 || code == 99;

  String _dayName(int weekday) {
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d[(weekday - 1) % 7];
  }

  String _desc(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code <= 48) return 'Fog';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rain';
    if (code <= 75) return 'Snow';
    if (code <= 82) return 'Showers';
    if (code == 95) return 'Thunderstorm';
    if (code >= 96) return 'Thunderstorm with Hail';
    return 'Unknown';
  }

  String _emoji(int code, {required bool isDay}) {
    if (code == 0) return isDay ? '☀️' : '🌙';
    if (code <= 2) return isDay ? '⛅' : '🌥️';
    if (code == 3) return '☁️';
    if (code <= 48) return '🌫️';
    if (code <= 55) return '🌦️';
    if (code <= 65) return isDay ? '🌧️' : '🌧️';
    if (code <= 75) return '❄️';
    if (code <= 82) return '🌦️';
    if (code == 95) return '⛈️';
    if (code >= 96) return '⛈️';
    return '🌈';
  }

  static String windDirection(int degrees) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((degrees + 22.5) / 45).floor() % 8];
  }

  static String uvLabel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  // Legacy compatibility for rain advisory used in old page
  List<String> getRainSprayAdvisory(List<HourlyWeather> hourly) {
    final intel = _rainIntelligence(hourly);
    if (intel.rainExpected && intel.hoursUntilRain <= 3) {
      return ['🌧 Rain expected in next 3 hours.', '🚫 Avoid pesticide spraying.'];
    }
    return ['✅ No rain expected in next 3 hours.', '🌾 Safe time for pesticide spraying.'];
  }
}
