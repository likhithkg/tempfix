import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../weather/weather_model.dart';
import '../../weather/weather_service.dart';
import '../../weather/weather_page.dart';

// ─── Gradient palette (mirrors weather_page.dart) ─────────────────────────────

List<Color> _palette(String description, bool isDay) {
  if (!isDay) return const [Color(0xFF040812), Color(0xFF0A1628), Color(0xFF0D1B4E)];
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
  final h = DateTime.now().hour;
  if (h >= 5 && h < 7) return const [Color(0xFF1A0533), Color(0xFFBF360C), Color(0xFFFF7043)];
  if (h >= 7 && h < 9) return const [Color(0xFF1565C0), Color(0xFFE65100), Color(0xFFFF9800)];
  if (h >= 9 && h < 16) return const [Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF29B6F6)];
  if (h >= 16 && h < 18) return const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)];
  if (h >= 18 && h < 20) return const [Color(0xFF4A148C), Color(0xFFAD1457), Color(0xFFE64A19)];
  return const [Color(0xFF0D1B3E), Color(0xFF1A237E), Color(0xFF283593)];
}

// ─── Background cloud painter (lightweight, no parallax) ─────────────────────

class _MiniCloudPainter extends CustomPainter {
  final double t;
  final Color color;
  _MiniCloudPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final clouds = [
      (0.10, 0.18, 0.32, 0.28),
      (0.65, 0.08, 0.25, 0.22),
      (0.40, 0.28, 0.20, 0.16),
    ];
    for (final c in clouds) {
      final x = ((c.$1 + t * 0.008) % 1.1 - 0.05) * size.width;
      final y = c.$2 * size.height;
      paint.color = color.withValues(alpha: c.$4);
      _cloud(canvas, paint, Offset(x, y), c.$3 * size.width, c.$3 * size.width * 0.42);
    }
  }

  void _cloud(Canvas canvas, Paint p, Offset c, double rx, double ry) {
    final path = Path();
    void add(double dx, double dy, double r) =>
        path.addOval(Rect.fromCircle(center: Offset(c.dx + dx, c.dy + dy), radius: r));
    add(0, 0, ry * 0.62); add(rx * 0.3, ry * 0.1, ry * 0.48);
    add(-rx * 0.28, ry * 0.12, ry * 0.42); add(0, ry * 0.45, ry * 0.7);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_MiniCloudPainter o) => o.t != t;
}

// ─── Rain painter (simplified, fewer drops) ───────────────────────────────────

class _MiniRainPainter extends CustomPainter {
  final double t;
  final List<(double x, double y0, double spd, double len, double op)> drops;
  _MiniRainPainter(this.t, this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final y = ((d.$2 + t * d.$3) % 1.0) * size.height;
      paint.color = const Color(0xFFB3E5FC).withValues(alpha: d.$5);
      canvas.drawLine(
        Offset(d.$1 * size.width, y),
        Offset(d.$1 * size.width + 3, y + d.$4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRainPainter o) => o.t != t;
}

// ─── Sun glow painter ─────────────────────────────────────────────────────────

class _MiniSunPainter extends CustomPainter {
  final double pulse;
  final double rotation;
  _MiniSunPainter(this.pulse, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.82, -size.height * 0.06);

    canvas.drawCircle(c, size.width * 0.45,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFF9C4).withValues(alpha: 0.25 + pulse * 0.1),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c, radius: size.width * 0.45)));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation * 2 * pi);
    final rp = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.12 + pulse * 0.05)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 10; i++) {
      final a = i * pi / 5;
      canvas.drawLine(
        Offset(cos(a) * size.width * 0.12, sin(a) * size.width * 0.12),
        Offset(cos(a) * size.width * 0.25, sin(a) * size.width * 0.25),
        rp,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MiniSunPainter o) => o.pulse != pulse || o.rotation != rotation;
}

// ─── Star painter (night) ─────────────────────────────────────────────────────

class _MiniStarPainter extends CustomPainter {
  final double t;
  final List<(double x, double y, double r, double ph)> stars;
  _MiniStarPainter(this.t, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final tw = (sin(t * 2 * pi * 0.7 + s.$4) + 1) * 0.5;
      p.color = Colors.white.withValues(alpha: 0.12 + tw * 0.7);
      canvas.drawCircle(Offset(s.$1 * size.width, s.$2 * size.height), s.$3, p);
    }
  }

  @override
  bool shouldRepaint(_MiniStarPainter o) => o.t != t;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class HomeWeatherWidget extends StatefulWidget {
  final String location;

  const HomeWeatherWidget({super.key, required this.location});

  @override
  State<HomeWeatherWidget> createState() => _HomeWeatherWidgetState();
}

class _HomeWeatherWidgetState extends State<HomeWeatherWidget>
    with TickerProviderStateMixin {
  final _service = WeatherService();
  WeatherData? _weather;
  bool _loading = true;
  bool _failed = false;

  late AnimationController _floatCtrl;
  late AnimationController _bgFastCtrl;  // rain
  late AnimationController _bgMedCtrl;   // stars / sun pulse
  late AnimationController _bgSlowCtrl;  // clouds / sun rotation

  late Animation<double> _floatAnim;

  final _rng = Random();
  late final List<(double, double, double, double, double)> _drops = List.generate(
      28, (_) => (_rng.nextDouble(), _rng.nextDouble(),
          0.35 + _rng.nextDouble() * 0.65, 8 + _rng.nextDouble() * 14,
          0.18 + _rng.nextDouble() * 0.32));

  late final List<(double, double, double, double)> _stars = List.generate(
      40, (_) => (_rng.nextDouble(), _rng.nextDouble() * 0.78,
          0.6 + _rng.nextDouble() * 1.4, _rng.nextDouble() * 2 * pi));

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _bgFastCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _bgMedCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
    _bgSlowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();

    _floatAnim = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _fetchWeather();
  }

  @override
  void didUpdateWidget(HomeWeatherWidget old) {
    super.didUpdateWidget(old);
    if (old.location != widget.location) _fetchWeather();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _bgFastCtrl.dispose();
    _bgMedCtrl.dispose();
    _bgSlowCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    if (widget.location.isEmpty || widget.location == 'Select Location') {
      setState(() { _loading = false; _failed = true; });
      return;
    }
    setState(() { _loading = true; _failed = false; });
    try {
      final data = await _service.fetchWeather(widget.location);
      if (mounted) setState(() { _weather = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  bool _isRain(String d) {
    final l = d.toLowerCase();
    return l.contains('rain') || l.contains('shower') || l.contains('drizzle') || l.contains('thunder');
  }

  bool _isClear(String d) {
    final l = d.toLowerCase();
    return l.contains('clear') || (l.contains('cloud') == false && l.contains('rain') == false && l.contains('fog') == false);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_failed || _weather == null) return _buildFallback();

    final w = _weather!;
    final colors = _palette(w.description, w.isDay);
    final advisory = w.advisories.isNotEmpty ? w.advisories.first : null;
    final showRain = _isRain(w.description);
    final showSun = !showRain && w.isDay && _isClear(w.description);
    final showStars = !w.isDay;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => WeatherPage(location: widget.location),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // ── Animated background layer ─────────────────────────────────

              if (showSun)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_bgMedCtrl, _bgSlowCtrl]),
                      builder: (_, __) => CustomPaint(
                        painter: _MiniSunPainter(_bgMedCtrl.value, _bgSlowCtrl.value),
                      ),
                    ),
                  ),
                ),

              if (showStars)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _bgMedCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _MiniStarPainter(_bgMedCtrl.value, _stars),
                      ),
                    ),
                  ),
                ),

              if (!showRain && !showStars)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _bgSlowCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _MiniCloudPainter(
                          _bgSlowCtrl.value,
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              if (showRain)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _bgFastCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _MiniRainPainter(_bgFastCtrl.value, _drops),
                      ),
                    ),
                  ),
                ),

              // Decorative circles
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: -16,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white60, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.location.split(',').first.trim(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('EEE · h:mm a').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Main row: emoji + temp | H/L
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floating emoji
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: _EmojiGlow(
                              emoji: w.emoji,
                              description: w.description,
                              isDay: w.isDay,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Temp + condition
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${w.currentTemp.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                  height: 0.95,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                w.description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${AppLocalizations.of(context)!.feelsLabel} ${w.feelsLike.toStringAsFixed(0)}°  ·  H:${w.tempHigh.toStringAsFixed(0)}°  L:${w.tempLow.toStringAsFixed(0)}°',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Stats strip (glass)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatPill('💧', '${w.humidity}%', AppLocalizations.of(context)!.humidity),
                              _vDivider(),
                              _StatPill('🌬️',
                                  '${w.windSpeed.toStringAsFixed(0)}m/s', AppLocalizations.of(context)!.wind),
                              _vDivider(),
                              _StatPill('🌧️',
                                  '${w.precipitationProbability}%', AppLocalizations.of(context)!.rain),
                              _vDivider(),
                              _StatPill(
                                  '🔆', WeatherService.uvLabel(w.uvIndex), AppLocalizations.of(context)!.uv),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Advisory pill
                    if (advisory != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: _advisoryBg(advisory.level),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _advisoryBorder(advisory.level),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(advisory.icon,
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    advisory.message,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.dayForecastAvailable(w.daily.isNotEmpty ? w.daily.length : 7),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.fullForecast,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 11),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.18),
      );

  Color _advisoryBg(AlertLevel level) => switch (level) {
        AlertLevel.high => Colors.red.withValues(alpha: 0.22),
        AlertLevel.medium => Colors.orange.withValues(alpha: 0.20),
        AlertLevel.low => Colors.green.withValues(alpha: 0.18),
      };

  Color _advisoryBorder(AlertLevel level) => switch (level) {
        AlertLevel.high => Colors.red.withValues(alpha: 0.5),
        AlertLevel.medium => Colors.orange.withValues(alpha: 0.5),
        AlertLevel.low => Colors.greenAccent.withValues(alpha: 0.5),
      };

  // ─── Loading / fallback ─────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white60,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return GestureDetector(
      onTap: _fetchWeather,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Text('🌤️', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weather',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(
                    widget.location == 'Select Location'
                        ? 'Set your location to see forecast'
                        : 'Tap to load weather',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Emoji with glow ring ─────────────────────────────────────────────────────

class _EmojiGlow extends StatelessWidget {
  final String emoji;
  final String description;
  final bool isDay;
  const _EmojiGlow(
      {required this.emoji, required this.description, required this.isDay});

  Color get _glow {
    if (!isDay) return const Color(0xFF3F51B5);
    final d = description.toLowerCase();
    if (d.contains('thunder')) return const Color(0xFF7B1FA2);
    if (d.contains('rain') || d.contains('shower')) return const Color(0xFF1565C0);
    if (d.contains('cloud')) return const Color(0xFF546E7A);
    return const Color(0xFFFFB300);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _glow.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Text(emoji, style: const TextStyle(fontSize: 52)),
      ],
    );
  }
}

// ─── Stat column ──────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String icon, value, label;
  const _StatPill(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 9)),
      ],
    );
  }
}
