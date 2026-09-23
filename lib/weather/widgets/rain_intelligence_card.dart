import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class RainIntelligenceCard extends StatelessWidget {
  final RainIntelligence rain;

  const RainIntelligenceCard({super.key, required this.rain});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(title: l.rainfallIntelligence, emoji: Icons.water_drop_rounded),
          if (!rain.rainExpected)
            _StatusRow(
              icon: Icons.wb_sunny_rounded,
              label: l.noRainNext24Hours,
              color: Colors.greenAccent,
            )
          else ...[
            _StatusRow(
              icon: Icons.water_drop_rounded,
              label: rain.hoursUntilRain == 0
                  ? l.rainFallingNow
                  : l.rainExpectedSoon(rain.hoursUntilRain),
              color: Colors.lightBlueAccent,
            ),
            if (rain.rainStartTime != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _StatBox(label: l.startTime, value: DateFormat('h:mm a').format(rain.rainStartTime!), icon: Icons.schedule_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatBox(label: l.rainDuration, value: '${rain.durationHours}h', icon: Icons.timer_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatBox(label: l.expectedLabel, value: '${rain.expectedRainfallMm.toStringAsFixed(0)} mm', icon: Icons.water_drop)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: Colors.lightBlueAccent),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}
