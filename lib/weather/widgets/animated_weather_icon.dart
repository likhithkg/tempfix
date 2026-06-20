import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedWeatherIcon extends StatefulWidget {
  final String emoji;
  final String description;
  final bool isDay;

  const AnimatedWeatherIcon({
    super.key,
    required this.emoji,
    required this.description,
    required this.isDay,
  });

  @override
  State<AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<AnimatedWeatherIcon>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _rainBounceCtrl;
  late Animation<double> _floatY;
  late Animation<double> _glowRadius;
  late Animation<double> _rainBounce;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rainBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _floatY = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _glowRadius = Tween<double>(begin: 30, end: 55).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _rainBounce = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _rainBounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _rainBounceCtrl.dispose();
    super.dispose();
  }

  bool get _isRain {
    final d = widget.description.toLowerCase();
    return d.contains('rain') || d.contains('drizzle') || d.contains('shower') ||
        d.contains('thunder');
  }

  bool get _isSun => !_isRain && widget.isDay &&
      (widget.description.toLowerCase().contains('clear') ||
          widget.description.toLowerCase().contains('cloud') == false);

  Color get _glowColor {
    if (!widget.isDay) return const Color(0xFF3F51B5);
    final d = widget.description.toLowerCase();
    if (d.contains('thunder')) return const Color(0xFF7B1FA2);
    if (d.contains('rain') || d.contains('shower')) return const Color(0xFF1565C0);
    if (d.contains('cloud')) return const Color(0xFF546E7A);
    if (d.contains('fog')) return const Color(0xFF78909C);
    return const Color(0xFFFFB300);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, _glowCtrl, _rainBounceCtrl]),
      builder: (context, _) {
        final yOffset = _isRain ? _rainBounce.value : _floatY.value;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.38),
                      blurRadius: _glowRadius.value,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.18),
                      blurRadius: _glowRadius.value * 2,
                      spreadRadius: -4,
                    ),
                  ],
                ),
              ),

              // Sun rotating ring (clear day only)
              if (_isSun)
                Transform.rotate(
                  angle: _glowCtrl.value * 2 * pi * 0.3,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFF176).withValues(alpha: 0.25 + _glowCtrl.value * 0.15),
                        width: 2,
                      ),
                    ),
                  ),
                ),

              if (_isSun)
                Transform.rotate(
                  angle: -_glowCtrl.value * 2 * pi * 0.18,
                  child: Container(
                    width: 122,
                    height: 122,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFCC02).withValues(alpha: 0.15 + _glowCtrl.value * 0.1),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Rain drop halo (rain conditions)
              if (_isRain)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.lightBlueAccent.withValues(alpha: 0.2 + _glowCtrl.value * 0.15),
                      width: 1.5,
                    ),
                  ),
                ),

              // Night moon rings
              if (!widget.isDay)
                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF7986CB).withValues(alpha: 0.18 + _glowCtrl.value * 0.12),
                      width: 1.5,
                    ),
                  ),
                ),

              // The emoji itself
              Text(widget.emoji, style: const TextStyle(fontSize: 86)),
            ],
          ),
        );
      },
    );
  }
}
