import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_service.dart';
import 'weather_model.dart';
import 'widgets/hourly_forecast.dart';
import 'widgets/daily_forecast.dart';
import 'widgets/autocomplete_widget.dart';
import 'widgets/day_detail_page.dart';
import 'widgets/farmer_advisory_card.dart';
import 'widgets/ag_indexes_card.dart';
import 'widgets/disease_risk_card.dart';
import 'widgets/sun_info_card.dart';
import 'widgets/rain_intelligence_card.dart';
import 'widgets/wind_card.dart';
import 'widgets/irrigation_card.dart';
import '../services/libre_translate_service.dart';

List<Color> _gradientColors(String description, bool isDay) {
  if (!isDay) {
    return const [Color(0xFF060818), Color(0xFF0D1B4E), Color(0xFF1A237E)];
  }
  final d = description.toLowerCase();
  if (d.contains('thunder') || d.contains('storm')) {
    return const [Color(0xFF0A0A1A), Color(0xFF1A1A2E), Color(0xFF16213E)];
  }
  if (d.contains('rain') || d.contains('shower') || d.contains('drizzle')) {
    return const [Color(0xFF1A237E), Color(0xFF1565C0), Color(0xFF1976D2)];
  }
  if (d.contains('cloud') || d.contains('overcast')) {
    return const [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF607D8B)];
  }
  if (d.contains('fog') || d.contains('mist')) {
    return const [Color(0xFF4A5568), Color(0xFF718096), Color(0xFF90A4AE)];
  }
  if (d.contains('snow')) {
    return const [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF80CBC4)];
  }
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 8) {
    return const [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFF1565C0)];
  }
  if (hour >= 17 && hour < 20) {
    return const [Color(0xFFAD1457), Color(0xFFE64A19), Color(0xFF4A148C)];
  }
  return const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)];
}

class WeatherPage extends StatefulWidget {
  final String? location;
  const WeatherPage({super.key, this.location});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  final WeatherService _service = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  WeatherData? _weather;
  bool _loading = true;
  String _error = '';
  String _lastSearched = 'Bengaluru';
  bool _searchVisible = false;
  String _translatedDescription = '';

  late AnimationController _emojiController;
  late Animation<double> _emojiScale;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _emojiScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.easeInOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadLocationAndFetch();
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _fadeController.dispose();
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

  Future<void> _fetchWeather(String place) async {
    setState(() {
      _loading = true;
      _error = '';
      _searchVisible = false;
    });
    _fadeController.reset();
    try {
      final data = await _service.fetchWeather(place);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastLocation', place);

      final lang = mounted ? Localizations.localeOf(context).languageCode : 'en';
      final translated = await LibreTranslateService.translateText(
        text: data.description,
        targetLanguage: lang,
      );

      if (!mounted) return;
      setState(() {
        _weather = data;
        _loading = false;
        _lastSearched = place;
        _translatedDescription = translated;
      });
      _fadeController.forward();
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = _weather;
    final colors = w != null
        ? _gradientColors(w.description, w.isDay)
        : const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (_searchVisible) _buildSearchBar(),
              Expanded(
                child: _loading
                    ? _buildSkeleton()
                    : _error.isNotEmpty
                        ? _buildError()
                        : w == null
                            ? const SizedBox()
                            : RefreshIndicator(
                                onRefresh: () => _fetchWeather(_lastSearched),
                                color: Colors.white,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: _buildContent(w),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _searchVisible = !_searchVisible),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _lastSearched.split(',').first.trim(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _searchVisible ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _fetchWeather(_lastSearched),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
            ),
            child: AutocompleteWidget(
              controller: _searchController,
              onSelected: _fetchWeather,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(WeatherData w) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHero(w),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                _section('24-HOUR FORECAST', '🕒', HourlyForecast(hourly: w.hourly)),
                const SizedBox(height: 12),
                FarmerAdvisoryCard(advisories: w.advisories),
                const SizedBox(height: 12),
                AgIndexesCard(indexes: w.agIndexes),
                const SizedBox(height: 12),
                RainIntelligenceCard(rain: w.rainIntelligence),
                const SizedBox(height: 12),
                IrrigationCard(
                  recommendation: w.irrigationRecommendation,
                  need: w.agIndexes.irrigation,
                ),
                const SizedBox(height: 12),
                DiseaseRiskCard(risks: w.diseaseRisks),
                const SizedBox(height: 12),
                WindCard(windSpeed: w.windSpeed, windDirection: w.windDirection),
                const SizedBox(height: 12),
                SunInfoCard(weather: w),
                const SizedBox(height: 12),
                _section(
                  '7-DAY FORECAST',
                  '📅',
                  DailyForecast(
                    daily: w.daily,
                    onSelected: (day) => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DayDetailPage(dayWeather: day)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(WeatherData w) {
    final desc = _translatedDescription.isEmpty ? w.description : _translatedDescription;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, MMM d · h:mm a').format(DateTime.now()),
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _emojiScale,
            child: Text(w.emoji, style: const TextStyle(fontSize: 90)),
          ),
          const SizedBox(height: 8),
          Text(
            '${w.currentTemp.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          Text(
            'Feels like ${w.feelsLike.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'H: ${w.tempHigh.toStringAsFixed(0)}°',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const Text('  ·  ', style: TextStyle(color: Colors.white38)),
              Text(
                'L: ${w.tempLow.toStringAsFixed(0)}°',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHeroStats(w),
          if (w.precipitationProbability > 50) ...[
            const SizedBox(height: 12),
            _buildRainAlert(w.precipitationProbability),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroStats(WeatherData w) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroStat(icon: '💧', value: '${w.humidity}%', label: 'Humidity'),
              _vDivider(),
              _HeroStat(icon: '🌬️', value: '${w.windSpeed.toStringAsFixed(0)} m/s', label: 'Wind'),
              _vDivider(),
              _HeroStat(icon: '🌧️', value: '${w.precipitationProbability}%', label: 'Rain'),
              _vDivider(),
              _HeroStat(icon: '🔆', value: WeatherService.uvLabel(w.uvIndex), label: 'UV'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 32, color: Colors.white24);

  Widget _buildRainAlert(int prob) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌧️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$prob% chance of rain today',
            style: const TextStyle(fontSize: 13, color: Colors.lightBlueAccent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String emoji, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _shimmerBox(height: 80, width: 80, radius: 40),
          const SizedBox(height: 16),
          _shimmerBox(height: 72, width: 180, radius: 12),
          const SizedBox(height: 8),
          _shimmerBox(height: 20, width: 120, radius: 8),
          const SizedBox(height: 24),
          _shimmerBox(height: 70, radius: 16),
          const SizedBox(height: 12),
          _shimmerBox(height: 150, radius: 20),
          const SizedBox(height: 12),
          _shimmerBox(height: 160, radius: 20),
          const SizedBox(height: 12),
          _shimmerBox(height: 140, radius: 20),
        ],
      ),
    );
  }

  Widget _shimmerBox({required double height, double? width, double radius = 12}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _fetchWeather(_lastSearched),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
