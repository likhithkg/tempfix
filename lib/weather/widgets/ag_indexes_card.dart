import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class AgIndexesCard extends StatelessWidget {
  final AgriculturalIndexes indexes;

  const AgIndexesCard({super.key, required this.indexes});

  Color _sprayColor(SprayingIndex s) {
    switch (s) {
      case SprayingIndex.excellent: return Colors.greenAccent;
      case SprayingIndex.good: return Colors.yellowAccent;
      case SprayingIndex.poor: return Colors.redAccent;
    }
  }

  Color _harvestColor(HarvestIndex h) {
    switch (h) {
      case HarvestIndex.excellent: return Colors.greenAccent;
      case HarvestIndex.good: return Colors.yellowAccent;
      case HarvestIndex.poor: return Colors.redAccent;
    }
  }

  Color _irrigColor(IrrigationNeed n) {
    switch (n) {
      case IrrigationNeed.required_: return Colors.orangeAccent;
      case IrrigationNeed.optional_: return Colors.yellowAccent;
      case IrrigationNeed.notRequired: return Colors.greenAccent;
    }
  }

  Color _fieldColor(FieldWorkIndex f) {
    switch (f) {
      case FieldWorkIndex.excellent: return Colors.greenAccent;
      case FieldWorkIndex.moderate: return Colors.yellowAccent;
      case FieldWorkIndex.poor: return Colors.redAccent;
    }
  }

  String _sprayValue(SprayingIndex s, AppLocalizations l) {
    switch (s) {
      case SprayingIndex.excellent: return l.excellent;
      case SprayingIndex.good: return l.good;
      case SprayingIndex.poor: return l.poor;
    }
  }

  String _harvestValue(HarvestIndex h, AppLocalizations l) {
    switch (h) {
      case HarvestIndex.excellent: return l.excellent;
      case HarvestIndex.good: return l.good;
      case HarvestIndex.poor: return l.poor;
    }
  }

  String _irrigValue(IrrigationNeed n, AppLocalizations l) {
    switch (n) {
      case IrrigationNeed.required_: return l.statusRequired;
      case IrrigationNeed.optional_: return l.statusOptional;
      case IrrigationNeed.notRequired: return l.notNeeded;
    }
  }

  String _fieldValue(FieldWorkIndex f, AppLocalizations l) {
    switch (f) {
      case FieldWorkIndex.excellent: return l.excellent;
      case FieldWorkIndex.moderate: return l.moderate;
      case FieldWorkIndex.poor: return l.poor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSectionHeader(title: l.agriculturalIndexes, emoji: '📊'),
          Row(
            children: [
              Expanded(child: _IndexTile(
                icon: '🌿',
                label: l.spraying,
                value: _sprayValue(indexes.spraying, l),
                color: _sprayColor(indexes.spraying),
              )),
              const SizedBox(width: 8),
              Expanded(child: _IndexTile(
                icon: '🌾',
                label: l.harvest,
                value: _harvestValue(indexes.harvest, l),
                color: _harvestColor(indexes.harvest),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _IndexTile(
                icon: '💧',
                label: l.irrigationLabel,
                value: _irrigValue(indexes.irrigation, l),
                color: _irrigColor(indexes.irrigation),
              )),
              const SizedBox(width: 8),
              Expanded(child: _IndexTile(
                icon: '🚜',
                label: l.fieldWork,
                value: _fieldValue(indexes.fieldWork, l),
                color: _fieldColor(indexes.fieldWork),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndexTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _IndexTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
