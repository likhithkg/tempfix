// lib/exporter_hub/farmer_score_service.dart
// Computes Farmer Reliability Score from Firestore PO history.
// No new Firestore collection needed — reads existing purchase_orders and qc_reports.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerScore {
  final String farmerId;
  final double totalScore;        // 0–100
  final double acceptanceRate;    // PO acceptance rate
  final double deliveryRate;      // collection completion rate
  final double qcPassRate;        // QC approved / total QC
  final double quantityAccuracy;  // collected qty / promised qty (capped 1.0)
  final int totalPOs;
  final String tier;              // Trusted | Reliable | Average | Review Required

  const FarmerScore({
    required this.farmerId,
    required this.totalScore,
    required this.acceptanceRate,
    required this.deliveryRate,
    required this.qcPassRate,
    required this.quantityAccuracy,
    required this.totalPOs,
    required this.tier,
  });

  static String tierFromScore(double score) {
    if (score >= 90) return 'Trusted Supplier';
    if (score >= 75) return 'Reliable Supplier';
    if (score >= 50) return 'Average Supplier';
    return 'Review Required';
  }
}

class FarmerScoreService {
  final _db = FirebaseFirestore.instance;

  Future<FarmerScore> computeScore(String farmerId) async {
    // 1. Fetch all POs for this farmer
    final poSnap = await _db
        .collection('purchase_orders')
        .where('farmerId', isEqualTo: farmerId)
        .get();

    if (poSnap.docs.isEmpty) {
      return FarmerScore(
        farmerId: farmerId, totalScore: 0, acceptanceRate: 0,
        deliveryRate: 0, qcPassRate: 0, quantityAccuracy: 0,
        totalPOs: 0, tier: 'Review Required',
      );
    }

    final pos = poSnap.docs.map((d) => d.data()).toList();
    final total = pos.length;

    // 2. Acceptance rate (farmer_accepted, collected, qc_*, exported, delivered)
    const acceptedStatuses = {
      'farmer_accepted', 'collection_scheduled', 'collected',
      'qc_pending', 'qc_approved', 'qc_rejected',
      'ready_for_export', 'exported', 'completed', 'delivered',
    };
    final accepted = pos.where((p) => acceptedStatuses.contains(p['status']?.toString() ?? '')).length;
    final acceptanceRate = accepted / total;

    // 3. Delivery rate (reached collected or beyond)
    const deliveredStatuses = {
      'collected', 'qc_pending', 'qc_approved', 'qc_rejected',
      'ready_for_export', 'exported', 'completed', 'delivered',
    };
    final delivered = pos.where((p) => deliveredStatuses.contains(p['status']?.toString() ?? '')).length;
    final deliveryRate = total > 0 ? delivered / total : 0.0;

    // 4. QC pass rate
    final poIds = poSnap.docs.map((d) => d.id).toList();
    double qcPassRate = 1.0; // default to 1 if no QC data
    if (poIds.isNotEmpty) {
      // Firestore 'whereIn' max 30 items
      final batch = poIds.take(30).toList();
      final qcSnap = await _db
          .collection('qc_reports')
          .where('poId', whereIn: batch)
          .get();
      if (qcSnap.docs.isNotEmpty) {
        final qcDocs = qcSnap.docs.map((d) => d.data()).toList();
        final approved = qcDocs.where((d) => d['approvalStatus'] == 'approved').length;
        qcPassRate = approved / qcDocs.length;
      }
    }

    // 5. Quantity accuracy: compare ordered vs actual
    double totalOrdered = 0;
    double totalCollected = 0;
    for (final po in pos) {
      final ordered = _parseQty(po['totalQuantity'] ?? po['quantity']);
      final actual = _parseQty(po['collectedQuantity'] ?? po['actualQuantity']);
      totalOrdered += ordered;
      totalCollected += actual;
    }
    final quantityAccuracy = totalOrdered > 0
        ? (totalCollected / totalOrdered).clamp(0.0, 1.0)
        : 1.0;

    // Weighted score: acceptance 30% | delivery 30% | QC 25% | qty accuracy 15%
    final score = (acceptanceRate * 30 +
            deliveryRate * 30 +
            qcPassRate * 25 +
            quantityAccuracy * 15)
        .clamp(0.0, 100.0);

    return FarmerScore(
      farmerId: farmerId,
      totalScore: score,
      acceptanceRate: acceptanceRate,
      deliveryRate: deliveryRate,
      qcPassRate: qcPassRate,
      quantityAccuracy: quantityAccuracy,
      totalPOs: total,
      tier: FarmerScore.tierFromScore(score),
    );
  }

  double _parseQty(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}

// ── Widget to display farmer score ────────────────────────────────────────────

class FarmerScoreCard extends StatelessWidget {
  final String farmerId;
  final String farmerName;
  const FarmerScoreCard({super.key, required this.farmerId, required this.farmerName});

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Trusted Supplier': return Colors.green.shade700;
      case 'Reliable Supplier': return Colors.teal;
      case 'Average Supplier': return Colors.orange;
      default: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FarmerScore>(
      future: FarmerScoreService().computeScore(farmerId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator()));
        }
        final score = snap.data!;
        final tierColor = _tierColor(score.tier);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: tierColor.withValues(alpha: 0.12),
                  child: Text(score.totalScore.toStringAsFixed(0),
                      style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(farmerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tierColor)),
                    child: Text(score.tier,
                        style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ])),
              ]),
              const SizedBox(height: 12),
              _ScoreRow('PO Acceptance', score.acceptanceRate),
              _ScoreRow('Delivery Rate', score.deliveryRate),
              _ScoreRow('QC Pass Rate', score.qcPassRate),
              _ScoreRow('Qty Accuracy', score.quantityAccuracy),
              const SizedBox(height: 4),
              Text('Based on ${score.totalPOs} purchase orders',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;
  const _ScoreRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final color = pct >= 80 ? Colors.green : (pct >= 60 ? Colors.orange : Colors.red);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )),
        const SizedBox(width: 8),
        Text('$pct%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
