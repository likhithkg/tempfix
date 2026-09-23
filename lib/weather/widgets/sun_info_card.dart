import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';
import '../weather_service.dart';
import 'glass_card.dart';

class SunInfoCard extends StatelessWidget {
  final WeatherData weather;

  const SunInfoCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sunrise = weather.sunrise;
    final sunset = weather.sunset;
    Duration? dayLength;
    if (sunrise != null && sunset != null) {
      dayLength = sunset.difference(sunrise);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(title: l.sunAndUv, emoji: Icons.wb_sunny_rounded),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (sunrise != null)
                _SunStat(
                  icon: Icons.wb_twilight_rounded,
                  label: l.sunrise,
                  value: DateFormat('h:mm a').format(sunrise),
                ),
              if (sunset != null)
                _SunStat(
                  icon: Icons.wb_twilight_rounded,
                  label: l.sunset,
                  value: DateFormat('h:mm a').format(sunset),
                ),
              if (dayLength != null)
                _SunStat(
                  icon: Icons.schedule_rounded,
                  label: l.dayLength,
                  value: '${dayLength.inHours}h ${dayLength.inMinutes % 60}m',
                ),
              _SunStat(
                icon: Icons.wb_sunny_rounded,
                label: l.uvIndex,
                value: '${weather.uvIndex.toStringAsFixed(1)}\n${WeatherService.uvLabel(weather.uvIndex)}',
              ),
            ],
          ),
          if (weather.uvIndex >= 6) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      weather.uvIndex >= 8
                          ? 'Very high UV — avoid sun exposure 10 AM–4 PM.'
                          : 'High UV — use protection when working outdoors.',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SunStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SunStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
