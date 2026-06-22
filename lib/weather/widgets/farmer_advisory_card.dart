import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class FarmerAdvisoryCard extends StatelessWidget {
  final List<FarmAdvisory> advisories;

  const FarmerAdvisoryCard({super.key, required this.advisories});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(title: AppLocalizations.of(context)!.farmerAdvisoryTitle, emoji: '🌾'),
          ...advisories.map((a) => _AdvisoryRow(advisory: a)),
        ],
      ),
    );
  }
}

class _AdvisoryRow extends StatelessWidget {
  final FarmAdvisory advisory;
  const _AdvisoryRow({required this.advisory});

  Color get _bgColor {
    switch (advisory.level) {
      case AlertLevel.high:
        return Colors.red.withValues(alpha: 0.25);
      case AlertLevel.medium:
        return Colors.orange.withValues(alpha: 0.20);
      case AlertLevel.low:
        return Colors.green.withValues(alpha: 0.20);
    }
  }

  Color get _borderColor {
    switch (advisory.level) {
      case AlertLevel.high:
        return Colors.red.withValues(alpha: 0.6);
      case AlertLevel.medium:
        return Colors.orange.withValues(alpha: 0.6);
      case AlertLevel.low:
        return Colors.greenAccent.withValues(alpha: 0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(advisory.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              advisory.message,
              style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
