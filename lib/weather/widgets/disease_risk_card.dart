import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class DiseaseRiskCard extends StatelessWidget {
  final List<DiseaseRisk> risks;

  const DiseaseRiskCard({super.key, required this.risks});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(title: l.cropDiseaseRiskTitle, emoji: '🔬'),
          ...risks.map((r) => _RiskRow(risk: r)),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final DiseaseRisk risk;
  const _RiskRow({required this.risk});

  String _label(AppLocalizations l) {
    switch (risk.level) {
      case AlertLevel.low: return l.riskLow;
      case AlertLevel.medium: return l.riskMedium;
      case AlertLevel.high: return l.riskHigh;
    }
  }

  Color get _color {
    switch (risk.level) {
      case AlertLevel.low: return Colors.greenAccent;
      case AlertLevel.medium: return Colors.orangeAccent;
      case AlertLevel.high: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(risk.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              risk.name,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          _RiskBadge(label: _label(l), color: _color),
          const SizedBox(width: 8),
          _RiskBar(level: risk.level, color: _color),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RiskBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final AlertLevel level;
  final Color color;
  const _RiskBar({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final filled = level == AlertLevel.low ? 1 : level == AlertLevel.medium ? 2 : 3;
    return Row(
      children: List.generate(3, (i) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          color: i < filled ? color : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      )),
    );
  }
}
