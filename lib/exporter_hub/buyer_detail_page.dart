// lib/exporter_hub/buyer_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

class BuyerDetailPage extends StatelessWidget {
  final String buyerId;
  final Map<String, dynamic> data;
  const BuyerDetailPage({super.key, required this.buyerId, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = data['companyName']?.toString() ?? '';
    final country = data['country']?.toString() ?? '';
    final contact = data['contactPerson']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final volume = data['annualVolume']?.toString() ?? '';
    final products = (data['productsInterested'] as List? ?? []).cast<String>();
    final grades = (data['preferredGrades'] as List? ?? []).cast<String>();

    return Scaffold(
      appBar: AppBar(title: Text(company)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shipments')
            .where('buyerName', isEqualTo: company)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, shipSnap) {
          final shipments = shipSnap.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Buyer info card
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(company.isNotEmpty ? company[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(country, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(),
                  if (contact.isNotEmpty) _Row(l.contactPerson, contact),
                  if (email.isNotEmpty) _Row(l.emailLabel, email),
                  if (phone.isNotEmpty) _Row(l.phone, phone),
                  if (volume.isNotEmpty) _Row(l.annualVolume, volume),
                  if (grades.isNotEmpty) _Row(l.preferredGradesHint, grades.join(', ')),
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(l.productsInterestedHint,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: products.map((p) =>
                        Chip(label: Text(p, style: const TextStyle(fontSize: 12)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0))).toList()),
                  ],
                ]),
              )),

              const SizedBox(height: 20),

              // Shipment history
              Text(l.previousShipments,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (shipments.isEmpty)
                Text(l.noShipmentsYet,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
              else
                ...shipments.map((doc) {
                  final s = doc.data() as Map<String, dynamic>;
                  final status = s['status']?.toString() ?? '';
                  final weight = (s['totalWeight'] as num?)?.toDouble() ?? 0.0;
                  final value = (s['totalValue'] as num?)?.toDouble() ?? 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.directions_boat_outlined),
                      title: Text(s['shipmentId']?.toString() ?? doc.id,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${weight.toStringAsFixed(0)} kg • ₹${(value / 1000).toStringAsFixed(1)}K'),
                      trailing: _StatusChip(status),
                    ),
                  );
                }),

              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 130, child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == 'delivered' ? Colors.green
        : status == 'shipped' ? Colors.teal
        : status == 'customs_cleared' ? Colors.blue
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color)),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
