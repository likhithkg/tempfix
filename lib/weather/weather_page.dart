import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
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
import 'widgets/weather_background.dart';
import 'widgets/animated_weather_icon.dart';
import '../services/libre_translate_service.dart';

// ─── Gradient palette (time-of-day + condition aware) ────────────────────────

List<Color> _gradientColors(String description, bool isDay) {
  if (!isDay) {
    return const [Color(0xFF040812), Color(0xFF0A1628), Color(0xFF0D1B4E)];
  }
  final d = description.toLowerCase();
  if (d.contains('thunder') || d.contains('storm')) {
    return const [Color(0xFF0A0A1A), Color(0xFF1A1A2E), Color(0xFF16213E)];
  }
  if (d.contains('rain') || d.contains('shower') || d.contains('drizzle')) {
    return const [Color(0xFF0D1B4E), Color(0xFF1565C0), Color(0xFF1976D2)];
  }
  if (d.contains('cloud') || d.contains('overcast')) {
    return const [Color(0xFF263238), Color(0xFF37474F), Color(0xFF546E7A)];
  }
  if (d.contains('fog') || d.contains('mist')) {
    return const [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF78909C)];
  }
  if (d.contains('snow')) {
    return const [Color(0xFF37474F), Color(0xFF546E7A), Color(0xFF80CBC4)];
  }
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 7) {
    return const [Color(0xFF1A0533), Color(0xFFBF360C), Color(0xFFFF7043)];
  }
  if (hour >= 7 && hour < 9) {
    return const [Color(0xFF1565C0), Color(0xFFE65100), Color(0xFFFF9800)];
  }
  if (hour >= 9 && hour < 16) {
    return const [Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF29B6F6)];
  }
  if (hour >= 16 && hour < 18) {
    return const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)];
  }
  if (hour >= 18 && hour < 20) {
    return const [Color(0xFF4A148C), Color(0xFFAD1457), Color(0xFFE64A19)];
  }
  return const [Color(0xFF0D1B3E), Color(0xFF1A237E), Color(0xFF283593)];
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class WeatherPage extends StatefulWidget {
  final String? location;
  const WeatherPage({super.key, this.location});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with SingleTickerProviderStateMixin {
  final WeatherService _service = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  // Scroll offset is shared between the scroll view and WeatherBackground
  // via ValueNotifier — only the background cloud layer rebuilds on scroll.
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0);

  WeatherData? _weather;
  bool _loading = true;
  String _error = '';
  String _lastSearched = 'Bengaluru';
  bool _searchVisible = false;
  String _translatedDescription = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadLocationAndFetch();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _scrollNotifier.dispose();
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = _weather;
    final colors = w != null
        ? _gradientColors(w.description, w.isDay)
        : const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1 + 2 + 3: Animated weather background (gradient,
          //    sky effects, cloud parallax, weather particles) ──────────────
          if (w != null)
            WeatherBackground(
              description: w.description,
              isDay: w.isDay,
              gradientColors: colors,
              scrollNotifier: _scrollNotifier,
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

          // ── Layer 4: UI content ────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                if (_searchVisible) _buildSearchBar(),
                Expanded(child: _buildBody(w)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WeatherData? w) {
    if (_loading) return _buildSkeleton();
    if (_error.isNotEmpty) return _buildError();
    if (w == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: () => _fetchWeather(_lastSearched),
      color: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _scrollNotifier.value = notification.metrics.pixels;
            return false;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildContent(w),
          ),
        ),
      ),
    );
  }

  // ─── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (Navigator.canPop(context))
            _glassButton(
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onTap: () => Navigator.pop(context),
            ),
          const Spacer(),
          _locationChip(),
          const SizedBox(width: 8),
          _glassButton(
            child: const Icon(Icons.refresh, color: Colors.white, size: 18),
            onTap: () => _fetchWeather(_lastSearched),
          ),
        ],
      ),
    );
  }

  Widget _locationChip() {
    return GestureDetector(
      onTap: () => setState(() => _searchVisible = !_searchVisible),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    _lastSearched.split(',').first.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _searchVisible ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // ─── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.32),
                width: 1,
              ),
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

  // ─── Main content ────────────────────────────────────────────────────────────

  Widget _buildContent(WeatherData w) {
    return Column(
      children: [
        _buildHero(w),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: Column(
            children: [
              _glassSection('🕒', AppLocalizations.of(context)!.twentyFourHourForecast, HourlyForecast(hourly: w.hourly)),
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
              _glassSection(
                '📅',
                AppLocalizations.of(context)!.sevenDayForecastSection,
                DailyForecast(
                  daily: w.daily,
                  onSelected: (day) => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, a, __) => DayDetailPage(dayWeather: day),
                      transitionsBuilder: (_, anim, __, child) => FadeTransition(
                        opacity: anim,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Hero section ────────────────────────────────────────────────────────────

  Widget _buildHero(WeatherData w) {
    final desc = _translatedDescription.isEmpty ? w.description : _translatedDescription;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        children: [
          // Date + time
          Text(
            DateFormat('EEEE, MMM d  ·  h:mm a').format(DateTime.now()),
            style: const TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 0.4),
          ),

          const SizedBox(height: 18),

          // Animated weather icon (floating + glow ring)
          AnimatedWeatherIcon(
            emoji: w.emoji,
            description: w.description,
            isDay: w.isDay,
          ),

          const SizedBox(height: 10),

          // Temperature
          Text(
            '${w.currentTemp.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontSize: 86,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              height: 0.95,
              letterSpacing: -2,
            ),
          ),

          const SizedBox(height: 6),

          // Condition
          Text(
            desc,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 6),

          // Feels like
          Text(
            '${AppLocalizations.of(context)!.feelsLike} ${w.feelsLike.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),

          const SizedBox(height: 4),

          // H/L
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'H: ${w.tempHigh.toStringAsFixed(0)}°',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('·', style: TextStyle(color: Colors.white30, fontSize: 16)),
              ),
              Text(
                'L: ${w.tempLow.toStringAsFixed(0)}°',
                style: const TextStyle(fontSize: 14, color: Colors.white60),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Stat strip
          _buildHeroStats(w),

          // Rain badge (if significant)
          if (w.precipitationProbability > 50) ...[
            const SizedBox(height: 12),
            _rainBadge(w.precipitationProbability),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroStats(WeatherData w) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroStat(icon: '💧', value: '${w.humidity}%', label: AppLocalizations.of(context)!.humidity),
              _vDivider(),
              _HeroStat(
                icon: '🌬️',
                value: '${w.windSpeed.toStringAsFixed(0)} m/s',
                label: AppLocalizations.of(context)!.wind,
              ),
              _vDivider(),
              _HeroStat(
                icon: '🌧️',
                value: '${w.precipitationProbability}%',
                label: AppLocalizations.of(context)!.rain,
              ),
              _vDivider(),
              _HeroStat(
                icon: '🔆',
                value: WeatherService.uvLabel(w.uvIndex),
                label: AppLocalizations.of(context)!.uv,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withValues(alpha: 0.18),
      );

  Widget _rainBadge(int prob) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.lightBlueAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.lightBlueAccent.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌧️', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.rainChanceToday(prob),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Glass section card ──────────────────────────────────────────────────────

  Widget _glassSection(String emoji, String title, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 1.0,
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

  // ─── Loading skeleton ────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _pulse(height: 90, width: 90, radius: 45),
          const SizedBox(height: 14),
          _pulse(height: 80, width: 160, radius: 12),
          const SizedBox(height: 8),
          _pulse(height: 22, width: 100, radius: 8),
          const SizedBox(height: 20),
          _pulse(height: 72, radius: 18),
          const SizedBox(height: 12),
          _pulse(height: 155, radius: 20),
          const SizedBox(height: 12),
          _pulse(height: 170, radius: 20),
          const SizedBox(height: 12),
          _pulse(height: 140, radius: 20),
          const SizedBox(height: 12),
          _pulse(height: 120, radius: 20),
        ],
      ),
    );
  }

  Widget _pulse({required double height, double? width, double radius = 12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Error state ─────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 14),
                  Text(
                    _error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _fetchWeather(_lastSearched),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero stat tile ───────────────────────────────────────────────────────────

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
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
