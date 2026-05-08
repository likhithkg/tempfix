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

  // 🌾 NEW: Farm alerts
  List<String> _farmAlerts = [];

  // 🌧 NEW: Rain alerts
  List<String> _rainAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadLocationAndFetch();
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

  Future<void> _fetchWeather(String place) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data = await _service.fetchWeather(place);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastLocation', place);

      // 🌾 Generate farm alerts
      final farmAlerts = _service.getFarmAlerts(
        data.currentTemp,
        data.humidity,
        data.windSpeed,
        data.daily,
      );

      // 🌧 Generate rain alerts
      final rainAlerts = _service.getRainSprayAdvisory(
        data.hourly,
      );

      setState(() {
        _weather = data;
        _farmAlerts = farmAlerts;
        _rainAlerts = rainAlerts;
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

  /// 🔎 Manual search trigger
  void _searchWeather() {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    _fetchWeather(query);

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text("🌦 ${AppLocalizations.of(context)!.weather}"),
        backgroundColor: const Color.fromARGB(255, 135, 193, 237),
      ),
      body: Container(
        decoration: getWeatherBackground(
          _weather?.description ?? "Clear",
        ),
        child: Column(
          children: [

            /// 🔎 Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [

                  Expanded(
                    child: AutocompleteWidget(
                      controller: _searchController,
                      onSelected: (place) {
                        _fetchWeather(place);
                      },
                    ),
                  ),

                  /// 🔍 Search button
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchWeather,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error))
                      : (_weather == null)
                          ? Center(child: Text(AppLocalizations.of(context)!.noData))
                          : RefreshIndicator(
                              onRefresh: () => _fetchWeather(_lastSearched),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [

                                    Text(
                                      DateFormat('EEEE, MMM d, y – hh:mm a')
                                          .format(DateTime.now()),
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      _weather!.cityName.split(',')[0].trim(),
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      _weather!.cityName,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      _weather!.emoji,
                                      style: const TextStyle(fontSize: 72),
                                    ),

                                    Text(
                                      '${_weather!.currentTemp.toStringAsFixed(1)}°C',
                                      style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold),
                                    ),

                                    Text(
                                      _weather!.description,
                                      style: const TextStyle(fontSize: 18),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                        '🌬 Wind: ${_weather!.windSpeed.toStringAsFixed(1)} m/s'),

                                    const SizedBox(height: 5),

                                    Text(
                                        '💧 Humidity: ${_weather!.humidity}%'),

                                    const SizedBox(height: 24),

                                    // 🌾 FARM ALERTS
                                    if (_farmAlerts.isNotEmpty) ...[
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "🌾 Farm Advisory",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._farmAlerts.map((a) => Text(a)),
                                      const SizedBox(height: 24),
                                    ],

                                    // 🌧 RAIN ALERTS
                                    if (_rainAlerts.isNotEmpty) ...[
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "🌧 Rain Advisory",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._rainAlerts.map((a) => Text(a)),
                                      const SizedBox(height: 24),
                                    ],

                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "🕒 Hourly Forecast",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    HourlyForecast(
                                      hourly: _weather!.hourly
                                          as List<HourlyWeather>,
                                    ),

                                    const SizedBox(height: 24),

                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "📅 7-Day Forecast",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

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