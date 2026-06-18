import 'package:flutter/material.dart';
import '../theme.dart';

/// Flexible status chip that accepts any label and color.
/// Use this for dynamic status values (pending/approved/rejected,
/// available/busy, seeds/plant, etc.).
///
/// For simple available/unavailable toggles the existing [KMStatusBadge]
/// in km_widgets.dart is sufficient. Use [KMStatusChip] when the color
/// and label are determined at runtime.
class KMStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const KMStatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(KMRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.3,
        ),
      ),
    );
  }
}
