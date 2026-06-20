import 'package:flutter/material.dart';
import '../weather_model.dart';
import 'glass_card.dart';

class AgIndexesCard extends StatelessWidget {
  final AgriculturalIndexes indexes;

  const AgIndexesCard({super.key, required this.indexes});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassSectionHeader(title: 'AGRICULTURAL INDEXES', emoji: '📊'),
          Row(
            children: [
              Expanded(child: _IndexTile(
                icon: '🌿',
                label: 'Spraying',
                value: _sprayLabel(indexes.spraying),
                color: _sprayColor(indexes.spraying),
              )),
              const SizedBox(width: 8),
              Expanded(child: _IndexTile(
                icon: '🌾',
                label: 'Harvest',
                value: _harvestLabel(indexes.harvest),
                color: _harvestColor(indexes.harvest),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _IndexTile(
                icon: '💧',
                label: 'Irrigation',
                value: _irrigLabel(indexes.irrigation),
                color: _irrigColor(indexes.irrigation),
              )),
              const SizedBox(width: 8),
              Expanded(child: _IndexTile(
                icon: '🚜',
                label: 'Field Work',
                value: _fieldLabel(indexes.fieldWork),
                color: _fieldColor(indexes.fieldWork),
              )),
            ],
          ),
        ],
      ),
    );
  }

  String _sprayLabel(SprayingIndex s) {
    switch (s) {
      case SprayingIndex.excellent: return 'Excellent';
      case SprayingIndex.good: return 'Good';
      case SprayingIndex.poor: return 'Poor';
    }
  }

  Color _sprayColor(SprayingIndex s) {
    switch (s) {
      case SprayingIndex.excellent: return Colors.greenAccent;
      case SprayingIndex.good: return Colors.yellowAccent;
      case SprayingIndex.poor: return Colors.redAccent;
    }
  }

  String _harvestLabel(HarvestIndex h) {
    switch (h) {
      case HarvestIndex.excellent: return 'Excellent';
      case HarvestIndex.good: return 'Good';
      case HarvestIndex.poor: return 'Poor';
    }
  }

  Color _harvestColor(HarvestIndex h) {
    switch (h) {
      case HarvestIndex.excellent: return Colors.greenAccent;
      case HarvestIndex.good: return Colors.yellowAccent;
      case HarvestIndex.poor: return Colors.redAccent;
    }
  }

  String _irrigLabel(IrrigationNeed n) {
    switch (n) {
      case IrrigationNeed.required_: return 'Required';
      case IrrigationNeed.optional_: return 'Optional';
      case IrrigationNeed.notRequired: return 'Not Needed';
    }
  }

  Color _irrigColor(IrrigationNeed n) {
    switch (n) {
      case IrrigationNeed.required_: return Colors.orangeAccent;
      case IrrigationNeed.optional_: return Colors.yellowAccent;
      case IrrigationNeed.notRequired: return Colors.greenAccent;
    }
  }

  String _fieldLabel(FieldWorkIndex f) {
    switch (f) {
      case FieldWorkIndex.excellent: return 'Excellent';
      case FieldWorkIndex.moderate: return 'Moderate';
      case FieldWorkIndex.poor: return 'Poor';
    }
  }

  Color _fieldColor(FieldWorkIndex f) {
    switch (f) {
      case FieldWorkIndex.excellent: return Colors.greenAccent;
      case FieldWorkIndex.moderate: return Colors.yellowAccent;
      case FieldWorkIndex.poor: return Colors.redAccent;
    }
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
