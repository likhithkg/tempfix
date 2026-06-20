import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class RainIntelligenceCard extends StatelessWidget {
  final RainIntelligence rain;

  const RainIntelligenceCard({super.key, required this.rain});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionHeader(title: 'RAINFALL INTELLIGENCE', emoji: '🌧️'),
          if (!rain.rainExpected)
            const _StatusRow(
              icon: '☀️',
              label: 'No rain expected in the next 24 hours.',
              color: Colors.greenAccent,
            )
          else ...[
            _StatusRow(
              icon: '🌧️',
              label: rain.hoursUntilRain == 0
                  ? 'Rain is falling now'
                  : 'Rain expected in ${rain.hoursUntilRain} hour${rain.hoursUntilRain == 1 ? '' : 's'}',
              color: Colors.lightBlueAccent,
            ),
            if (rain.rainStartTime != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _StatBox(label: 'Start Time', value: DateFormat('h:mm a').format(rain.rainStartTime!), icon: '⏰')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatBox(label: 'Duration', value: '${rain.durationHours}h', icon: '⏱️')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatBox(label: 'Expected', value: '${rain.expectedRainfallMm.toStringAsFixed(0)} mm', icon: '💧')),
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
  final String icon;
  final String label;
  final Color color;

  const _StatusRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
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
  final String icon;

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
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}
