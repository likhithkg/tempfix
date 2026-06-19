// lib/exporter_hub/export_readiness_service.dart
// Export Readiness Engine — scores each product for export fitness.
// No new Firestore collection: reads existing export_products + qc_reports.

import 'package:flutter/material.dart';
import 'exporter_model.dart';

class ExportReadiness {
  final double score;           // 0–100
  final String status;          // green | yellow | red
  final List<String> reasons;   // why points were added/deducted

  const ExportReadiness({
    required this.score,
    required this.status,
    required this.reasons,
  });

  static ExportReadiness compute(ExportProduct product, {int qcApproved = 0, int qcTotal = 0}) {
    double score = 0;
    final reasons = <String>[];

    // 1. Grade (25 pts)
    final grade = product.grade?.toUpperCase();
    if (grade == 'A') { score += 25; reasons.add('Grade A (+25)'); }
    else if (grade == 'B') { score += 15; reasons.add('Grade B (+15)'); }
    else if (grade == 'C') { score += 5; reasons.add('Grade C (+5)'); }
    else { reasons.add('No grade (0)'); }

    // 2. Organic status (10 pts)
    if (product.isOrganic) { score += 10; reasons.add('Organic certified (+10)'); }

    // 3. Quantity (20 pts)
    final qty = product.quantityNum;
    if (qty >= 1000) { score += 20; reasons.add('High quantity ≥1MT (+20)'); }
    else if (qty >= 500) { score += 15; reasons.add('Quantity ≥500kg (+15)'); }
    else if (qty >= 100) { score += 10; reasons.add('Quantity ≥100kg (+10)'); }
    else if (qty > 0) { score += 5; reasons.add('Small quantity (+5)'); }
    else { reasons.add('No quantity specified (0)'); }

    // 4. QC history (20 pts)
    if (qcTotal > 0) {
      final qcRate = qcApproved / qcTotal;
      final pts = (qcRate * 20).round().toDouble();
      score += pts;
      reasons.add('QC pass rate ${(qcRate * 100).toStringAsFixed(0)}% (+${pts.toStringAsFixed(0)})');
    } else {
      reasons.add('No QC data (0)');
    }

    // 5. Moisture level (10 pts) — stored as String? in model
    final moistureStr = product.moistureLevel;
    final moistureVal = moistureStr != null ? double.tryParse(moistureStr) : null;
    if (moistureVal != null) {
      if (moistureVal <= 14) { score += 10; reasons.add('Good moisture ≤14% (+10)'); }
      else if (moistureVal <= 18) { score += 5; reasons.add('Acceptable moisture (+5)'); }
      else { reasons.add('High moisture >18% (0)'); }
    } else {
      reasons.add('Moisture not recorded (0)');
    }

    // 6. Product images (10 pts)
    final imgCount = product.imageUrls.length + (product.imageUrl?.isNotEmpty == true ? 1 : 0);
    if (imgCount >= 3) { score += 10; reasons.add('3+ images (+10)'); }
    else if (imgCount >= 1) { score += 5; reasons.add('Has images (+5)'); }
    else { reasons.add('No images (0)'); }

    // 7. Harvest date (5 pts)
    if (product.harvestDate != null) {
      final daysSince = DateTime.now().difference(product.harvestDate!).inDays;
      if (daysSince <= 30) { score += 5; reasons.add('Recently harvested (+5)'); }
      else { reasons.add('Harvest date old (0)'); }
    } else {
      reasons.add('No harvest date (0)');
    }

    final clamped = score.clamp(0.0, 100.0);
    final status = clamped >= 70 ? 'green' : (clamped >= 40 ? 'yellow' : 'red');
    return ExportReadiness(score: clamped, status: status, reasons: reasons);
  }
}

// ── Widget to show readiness badge ────────────────────────────────────────────

class ExportReadinessBadge extends StatelessWidget {
  final ExportProduct product;
  final bool showDetails;
  const ExportReadinessBadge({super.key, required this.product, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    final readiness = ExportReadiness.compute(product);
    final color = readiness.status == 'green'
        ? Colors.green
        : (readiness.status == 'yellow' ? Colors.orange : Colors.red);
    final label = readiness.status == 'green'
        ? 'Export Ready'
        : (readiness.status == 'yellow' ? 'Needs QC' : 'Not Ready');

    if (!showDetails) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icon(readiness.status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_icon(readiness.status), color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text('${readiness.score.toStringAsFixed(0)}/100',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: readiness.score / 100,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          ...readiness.reasons.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Icon(Icons.circle, size: 6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(r, style: const TextStyle(fontSize: 12)),
                ]),
              )),
        ]),
      ),
    );
  }

  IconData _icon(String status) {
    switch (status) {
      case 'green': return Icons.check_circle_outline;
      case 'yellow': return Icons.warning_amber_outlined;
      default: return Icons.cancel_outlined;
    }
  }
}
