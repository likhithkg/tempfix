import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../weather_service.dart';
import 'glass_card.dart';

class WindCard extends StatelessWidget {
  final double windSpeed;
  final int windDirection;

  const WindCard({super.key, required this.windSpeed, required this.windDirection});

  String _windLabel(AppLocalizations l) {
    if (windSpeed < 3) return l.windCalm;
    if (windSpeed < 6) return l.windLightBreeze;
    if (windSpeed < 10) return l.moderate;
    if (windSpeed < 15) return l.windStrong;
    return l.windVeryStrong;
  }

  Color get _windColor {
    if (windSpeed < 6) return Colors.greenAccent;
    if (windSpeed < 10) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dir = WeatherService.windDirection(windDirection);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(title: l.wind.toUpperCase(), emoji: '🌬️'),
          Row(
            children: [
              _CompassWidget(direction: windDirection),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${windSpeed.toStringAsFixed(1)} m/s',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _windColor,
                      ),
                    ),
                    Text(
                      '${_windLabel(l)} · $dir',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    if (windSpeed > 8) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          windSpeed > 12
                              ? '⚠️ Very strong winds — avoid spraying and tall crop work.'
                              : '⚠️ Moderate winds — spray early morning for best results.',
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompassWidget extends StatelessWidget {
  final int direction;
  const _CompassWidget({required this.direction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          ...['N', 'E', 'S', 'W'].asMap().entries.map((e) {
            const positions = [
              Alignment(0, -0.85),
              Alignment(0.85, 0),
              Alignment(0, 0.85),
              Alignment(-0.85, 0),
            ];
            return Align(
              alignment: positions[e.key],
              child: Text(
                e.value,
                style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold),
              ),
            );
          }),
          Transform.rotate(
            angle: direction * 3.14159 / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 3, height: 18, color: Colors.redAccent),
                Container(width: 3, height: 18, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
