import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ─── Particle Data ────────────────────────────────────────────────────────────

class _Drop {
  final double x, y0, speed, len, opacity;
  _Drop(Random r)
      : x = r.nextDouble(),
        y0 = r.nextDouble(),
        speed = 0.35 + r.nextDouble() * 0.65,
        len = 10 + r.nextDouble() * 22,
        opacity = 0.2 + r.nextDouble() * 0.45;
}

class _Star {
  final double x, y, radius, phase;
  _Star(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble() * 0.72,
        radius = 0.5 + r.nextDouble() * 1.8,
        phase = r.nextDouble() * 2 * pi;
}

class _Cloud {
  final double x0, y, rx, ry, speed, opacity;
  _Cloud(Random r, {double minOpacity = 0.1, double maxOpacity = 0.28})
      : x0 = r.nextDouble(),
        y = 0.03 + r.nextDouble() * 0.2,
        rx = 70 + r.nextDouble() * 130,
        ry = 30 + r.nextDouble() * 45,
        speed = 0.005 + r.nextDouble() * 0.012,
        opacity = minOpacity + r.nextDouble() * (maxOpacity - minOpacity);
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double t;
  final bool heavy;
  _RainPainter(this.drops, this.t, {this.heavy = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = heavy ? 1.8 : 1.2;
    for (final d in drops) {
      final y = ((d.y0 + t * d.speed) % 1.0) * size.height;
      final x = d.x * size.width;
      paint.color = const Color(0xFFB3E5FC).withValues(alpha: d.opacity);
      canvas.drawLine(Offset(x, y), Offset(x + 4, y + d.len), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter o) => o.t != t;
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Moon glow
    final moonPos = Offset(size.width * 0.74, size.height * 0.10);
    final moonPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueGrey.shade100.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: moonPos, radius: 88));
    canvas.drawCircle(moonPos, 88, moonPaint);

    // Stars
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final twinkle = (sin(t * 2 * pi * 0.8 + s.phase) + 1) * 0.5;
      p.color = Colors.white.withValues(alpha: 0.15 + twinkle * 0.75);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter o) => o.t != t;
}

class _CloudPainter extends CustomPainter {
  final List<_Cloud> clouds;
  final double t;
  final Color color;
  _CloudPainter(this.clouds, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final c in clouds) {
      final x = ((c.x0 + t * c.speed) % 1.3 - 0.15) * size.width;
      final y = c.y * size.height;
      p.color = color.withValues(alpha: c.opacity);
      _paintCloud(canvas, p, Offset(x, y), c.rx, c.ry);
    }
  }

  void _paintCloud(Canvas canvas, Paint p, Offset c, double rx, double ry) {
    final path = Path();
    void add(double dx, double dy, double rr) =>
        path.addOval(Rect.fromCircle(center: Offset(c.dx + dx, c.dy + dy), radius: rr));
    add(0, 0, ry * 0.6);
    add(rx * 0.32, ry * 0.08, ry * 0.48);
    add(-rx * 0.28, ry * 0.1, ry * 0.42);
    add(rx * 0.58, ry * 0.22, ry * 0.36);
    add(-rx * 0.52, ry * 0.24, ry * 0.32);
    add(0, ry * 0.42, ry * 0.72);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CloudPainter o) => o.t != t;
}

class _SunGlowPainter extends CustomPainter {
  final double pulse; // 0-1
  final double rotation; // 0-1
  _SunGlowPainter(this.pulse, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, -size.height * 0.04);

    // Outer warm atmosphere
    canvas.drawCircle(
      center,
      size.width * 0.75,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: 0.28 + pulse * 0.12),
            const Color(0xFFFF8F00).withValues(alpha: 0.10 + pulse * 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.75)),
    );

    // Inner bright core
    canvas.drawCircle(
      center,
      size.width * 0.26,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55 + pulse * 0.2),
            const Color(0xFFFFF176).withValues(alpha: 0.30),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.26)),
    );

    // Rotating rays
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * pi);
    final rayPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.14 + pulse * 0.06)
      ..strokeWidth = size.width * 0.022
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 14; i++) {
      final a = i * pi / 7;
      canvas.drawLine(
        Offset(cos(a) * size.width * 0.15, sin(a) * size.width * 0.15),
        Offset(cos(a) * size.width * 0.36, sin(a) * size.width * 0.36),
        rayPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunGlowPainter o) => o.pulse != pulse || o.rotation != rotation;
}

class _FogPainter extends CustomPainter {
  final double t;
  _FogPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final phase = i / 8.0;
      final y = ((phase + t * 0.035) % 1.1) * size.height;
      final baseOpacity = 0.05 + sin(phase * pi).abs() * 0.09;
      p.shader = ui.Gradient.linear(
        Offset(0, y),
        Offset(size.width, y),
        [
          Colors.transparent,
          Colors.white.withValues(alpha: baseOpacity),
          Colors.white.withValues(alpha: baseOpacity * 1.3),
          Colors.white.withValues(alpha: baseOpacity),
          Colors.transparent,
        ],
        [0.0, 0.2, 0.5, 0.8, 1.0],
      );
      canvas.drawRect(Rect.fromLTWH(0, y - 28, size.width, 56), p);
    }
  }

  @override
  bool shouldRepaint(_FogPainter o) => o.t != t;
}

class _LightningPainter extends CustomPainter {
  final double opacity;
  _LightningPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    // Screen flash
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.12),
    );

    // Bolt
    final boltPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.95)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final cx = size.width * 0.68;
    final path = Path()
      ..moveTo(cx, size.height * 0.0)
      ..lineTo(cx - 18, size.height * 0.16)
      ..lineTo(cx + 12, size.height * 0.21)
      ..lineTo(cx - 22, size.height * 0.40);

    // Glow effect
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.lightBlueAccent.withValues(alpha: opacity * 0.4)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(path, boltPaint);
  }

  @override
  bool shouldRepaint(_LightningPainter o) => o.opacity != opacity;
}

// ─── Condition Helper ─────────────────────────────────────────────────────────

enum _Kind { clear, cloudy, rain, thunder, snow, fog, night }

_Kind _weatherKind(String description, bool isDay) {
  if (!isDay) return _Kind.night;
  final d = description.toLowerCase();
  if (d.contains('thunder') || d.contains('storm')) return _Kind.thunder;
  if (d.contains('rain') || d.contains('shower') || d.contains('drizzle')) return _Kind.rain;
  if (d.contains('snow')) return _Kind.snow;
  if (d.contains('fog') || d.contains('mist') || d.contains('haze')) return _Kind.fog;
  if (d.contains('cloud') || d.contains('overcast')) return _Kind.cloudy;
  return _Kind.clear;
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

class WeatherBackground extends StatefulWidget {
  final String description;
  final bool isDay;
  final List<Color> gradientColors;
  final ValueNotifier<double> scrollNotifier;

  const WeatherBackground({
    super.key,
    required this.description,
    required this.isDay,
    required this.gradientColors,
    required this.scrollNotifier,
  });

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with TickerProviderStateMixin {
  // Fast: rain drops / 2s loop
  late AnimationController _fastCtrl;
  // Medium: star twinkle / 5s loop
  late AnimationController _medCtrl;
  // Slow: cloud float + sun rotation / 28s loop
  late AnimationController _slowCtrl;
  // Event: lightning flash / 280ms one-shot
  late AnimationController _flashCtrl;

  late final List<_Drop> _drops = List.generate(65, (_) => _Drop(_rng));
  late final List<_Star> _stars = List.generate(78, (_) => _Star(_rng));
  late final List<_Cloud> _clouds = List.generate(6, (_) => _Cloud(_rng, minOpacity: 0.13, maxOpacity: 0.3));
  late final List<_Cloud> _bgClouds = List.generate(4, (_) => _Cloud(_rng, minOpacity: 0.08, maxOpacity: 0.2));

  final _rng = Random();
  bool _lightningPending = false;

  @override
  void initState() {
    super.initState();
    _fastCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _medCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _slowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();
    _flashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scheduleLightning();
  }

  void _scheduleLightning() {
    final kind = _weatherKind(widget.description, widget.isDay);
    if (kind != _Kind.thunder || _lightningPending) return;
    _lightningPending = true;
    Future.delayed(Duration(seconds: 2 + _rng.nextInt(6)), () {
      if (!mounted) return;
      _flashCtrl.forward().then((_) {
        _flashCtrl.reverse().then((_) {
          _lightningPending = false;
          _scheduleLightning();
        });
      });
    });
  }

  @override
  void didUpdateWidget(WeatherBackground old) {
    super.didUpdateWidget(old);
    _scheduleLightning();
  }

  @override
  void dispose() {
    _fastCtrl.dispose();
    _medCtrl.dispose();
    _slowCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = _weatherKind(widget.description, widget.isDay);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Gradient background ────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // ── Sun glow ───────────────────────────────────────────────────────
        if (kind == _Kind.clear)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_medCtrl, _slowCtrl]),
              builder: (_, __) => CustomPaint(
                painter: _SunGlowPainter(_medCtrl.value, _slowCtrl.value),
              ),
            ),
          ),

        // ── Stars + moon (night) ───────────────────────────────────────────
        if (kind == _Kind.night)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _medCtrl,
              builder: (_, __) => CustomPaint(
                painter: _StarPainter(_stars, _medCtrl.value),
              ),
            ),
          ),

        // ── Cloud layer (parallax) ─────────────────────────────────────────
        if (kind == _Kind.clear || kind == _Kind.cloudy || kind == _Kind.rain || kind == _Kind.night)
          ValueListenableBuilder<double>(
            valueListenable: widget.scrollNotifier,
            builder: (_, offset, child) => Transform.translate(
              offset: Offset(-offset * 0.14, offset * 0.04),
              child: child,
            ),
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _slowCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _CloudPainter(
                    kind == _Kind.cloudy ? _clouds : _bgClouds,
                    _slowCtrl.value,
                    switch (kind) {
                      _Kind.night => const Color(0xFF1A237E),
                      _Kind.rain => Colors.blueGrey.shade300,
                      _ => Colors.white,
                    },
                  ),
                ),
              ),
            ),
          ),

        // ── Rain / snow ────────────────────────────────────────────────────
        if (kind == _Kind.rain || kind == _Kind.thunder || kind == _Kind.snow)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _fastCtrl,
              builder: (_, __) => CustomPaint(
                painter: _RainPainter(
                  _drops,
                  _fastCtrl.value,
                  heavy: kind == _Kind.thunder,
                ),
              ),
            ),
          ),

        // ── Fog layers ─────────────────────────────────────────────────────
        if (kind == _Kind.fog)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _slowCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FogPainter(_slowCtrl.value),
              ),
            ),
          ),

        // ── Lightning ──────────────────────────────────────────────────────
        if (kind == _Kind.thunder)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _flashCtrl,
              builder: (_, __) {
                final v = _flashCtrl.value;
                return CustomPaint(
                  painter: _LightningPainter(v * (1 - v) * 4),
                );
              },
            ),
          ),
      ],
    );
  }
}
