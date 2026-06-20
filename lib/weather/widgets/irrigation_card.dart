import 'package:flutter/material.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class IrrigationCard extends StatelessWidget {
  final String recommendation;
  final IrrigationNeed need;

  const IrrigationCard({
    super.key,
    required this.recommendation,
    required this.need,
  });

  Color get _color {
    switch (need) {
      case IrrigationNeed.required_: return Colors.orangeAccent;
      case IrrigationNeed.optional_: return Colors.yellowAccent;
      case IrrigationNeed.notRequired: return Colors.greenAccent;
    }
  }

  String get _icon {
    switch (need) {
      case IrrigationNeed.required_: return '🚿';
      case IrrigationNeed.optional_: return '💧';
      case IrrigationNeed.notRequired: return '✅';
    }
  }

  String get _statusLabel {
    switch (need) {
      case IrrigationNeed.required_: return 'REQUIRED';
      case IrrigationNeed.optional_: return 'OPTIONAL';
      case IrrigationNeed.notRequired: return 'NOT NEEDED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionHeader(title: 'IRRIGATION', emoji: '💧'),
          Row(
            children: [
              Text(_icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recommendation,
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
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
