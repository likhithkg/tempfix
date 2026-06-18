import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_service.dart';
import 'weather_model.dart';
import 'widgets/hourly_forecast.dart';
import 'widgets/daily_forecast.dart';
import 'widgets/autocomplete_widget.dart';
import 'widgets/day_detail_page.dart';
import '../l10n/app_localizations.dart';
import '../services/libre_translate_service.dart';
import '../theme.dart';

// Semantic gradient backgrounds keyed to weather condition — intentional design.
BoxDecoration getWeatherBackground(String condition) {
  if (condition.contains("Clear")) {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  } else if (condition.contains("Cloudy") || condition.contains("Overcast")) {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  } else if (condition.contains("Rain")) {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF373B44), Color(0xFF4286f4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  } else if (condition.contains("Storm") || condition.contains("Thunder")) {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  } else if (condition.contains("Snow")) {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  } else {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blueGrey, Colors.black87],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  final String? location;

  const WeatherPage({super.key, this.location});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final WeatherService _service = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  WeatherData? _weather;
  bool _loading = true;
  String _error = '';
  String _lastSearched = 'Bengaluru';

  String _translatedDescription = '';
  List<String> _translatedFarmAlerts = [];
  List<String> _translatedRainAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadLocationAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('lastLocation') ?? 'Bengaluru';
    final place = widget.location ?? saved;
    setState(() {
      _lastSearched = place;
      _searchController.text = place;
    });
    _fetchWeather(place);
  }

  Future<void> _translateWeatherContent(
    WeatherData data,
    List<String> farmAlerts,
    List<String> rainAlerts,
  ) async {
    final lang = Localizations.localeOf(context).languageCode;

    final translatedDescription = await LibreTranslateService.translateText(
      text: data.description,
      targetLanguage: lang,
    );

    final translatedFarm = <String>[];
    for (final alert in farmAlerts) {
      translatedFarm.add(await LibreTranslateService.translateText(
        text: alert,
        targetLanguage: lang,
      ));
    }

    final translatedRain = <String>[];
    for (final alert in rainAlerts) {
      translatedRain.add(await LibreTranslateService.translateText(
        text: alert,
        targetLanguage: lang,
      ));
    }

    setState(() {
      _translatedDescription = translatedDescription;
      _translatedFarmAlerts = translatedFarm;
      _translatedRainAlerts = translatedRain;
    });
  }

  Future<void> _fetchWeather(String place) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _service.fetchWeather(place);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastLocation', place);

      final farmAlerts = _service.getFarmAlerts(
        data.currentTemp,
        data.humidity,
        data.windSpeed,
        data.daily,
      );
      final rainAlerts = _service.getRainSprayAdvisory(data.hourly);

      await _translateWeatherContent(data, farmAlerts, rainAlerts);

      setState(() {
        _weather = data;
        _loading = false;
        _lastSearched = place;
        _searchController.text = place;
      });
    } catch (e) {
      setState(() {
        _error = '❌ ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _onDaySelected(DailyWeather selectedDay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailPage(dayWeather: selectedDay),
      ),
    );
  }

  void _searchWeather() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _fetchWeather(query);
    FocusScope.of(context).unfocus();
  }

  // Section header styled for the gradient background (white text).
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KMSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('🌦 ${l.weather}'),
      ),
      body: Container(
        decoration: getWeatherBackground(_weather?.description ?? 'Clear'),
        child: Column(
          children: [
            // ── Search row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KMSpacing.lg, KMSpacing.md, KMSpacing.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AutocompleteWidget(
                      controller: _searchController,
                      onSelected: (place) => _fetchWeather(place),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _searchWeather,
                  ),
                ],
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : _error.isNotEmpty
                      ? Center(
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : _weather == null
                          ? Center(
                              child: Text(
                                l.noData,
                                style: const TextStyle(color: Colors.white),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _fetchWeather(_lastSearched),
                              child: SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(KMSpacing.lg),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    // Date
                                    Text(
                                      DateFormat(
                                        'EEEE, MMM d, y – hh:mm a',
                                      ).format(DateTime.now()),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),

                                    const SizedBox(height: KMSpacing.sm),

                                    // City name
                                    Text(
                                      _weather!.cityName
                                          .split(',')[0]
                                          .trim(),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: KMSpacing.xs),

                                    Text(
                                      _weather!.cityName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: KMSpacing.lg),

                                    // Weather emoji + temp
                                    Text(
                                      _weather!.emoji,
                                      style: const TextStyle(fontSize: 72),
                                    ),

                                    Text(
                                      '${_weather!.currentTemp.toStringAsFixed(1)}°C',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),

                                    Text(
                                      _translatedDescription.isEmpty
                                          ? _weather!.description
                                          : _translatedDescription,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: KMSpacing.sm),

                                    // Wind + Humidity
                                    Text(
                                      '🌬 ${l.wind}: ${_weather!.windSpeed.toStringAsFixed(1)} m/s',
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: KMSpacing.xs),
                                    Text(
                                      '💧 ${l.humidity}: ${_weather!.humidity}%',
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),

                                    const SizedBox(height: KMSpacing.xl),

                                    // Farm advisory
                                    if (_translatedFarmAlerts.isNotEmpty) ...[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: _sectionHeader(
                                          '🌾 ${l.farmAdvisory}',
                                        ),
                                      ),
                                      ..._translatedFarmAlerts.map(
                                        (a) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: KMSpacing.xs),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              a,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: KMSpacing.xl),
                                    ],

                                    // Rain advisory
                                    if (_translatedRainAlerts.isNotEmpty) ...[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: _sectionHeader(
                                          '🌧 ${l.rainAdvisory}',
                                        ),
                                      ),
                                      ..._translatedRainAlerts.map(
                                        (a) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: KMSpacing.xs),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              a,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: KMSpacing.xl),
                                    ],

                                    // Hourly forecast
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: _sectionHeader(
                                        '🕒 ${l.hourlyForecast}',
                                      ),
                                    ),
                                    HourlyForecast(hourly: _weather!.hourly),

                                    const SizedBox(height: KMSpacing.xl),

                                    // 7-day forecast
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: _sectionHeader(
                                        '📅 ${l.sevenDayForecast}',
                                      ),
                                    ),
                                    DailyForecast(
                                      daily: _weather!.daily,
                                      onSelected: _onDaySelected,
                                    ),
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
