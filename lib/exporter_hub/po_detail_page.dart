// lib/exporter_hub/po_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_service.dart';

/// Purchase Order Detail Page
/// Shows a single PO (real-time) and allows simple actions like updating status.
/// This file is standalone; drop it into lib/exporter_hub/po_detail_page.dart
class PODetailPage extends StatelessWidget {
  final String poId;
  final ExporterService svc = ExporterService();

  PODetailPage({super.key, required this.poId});

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return '—';
      if (ts is Timestamp) {
        final d = ts.toDate();
        return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      } else if (ts is Map && ts.containsKey('_seconds')) {
        final d = DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
        return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      } else if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      } else {
        return ts.toString();
      }
    } catch (_) {
      return ts.toString();
    }
  }

  Future<void> _changeStatus(BuildContext context, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to perform this action')));
      return;
    }

    try {
      await svc.updatePOStatus(poId, newStatus, user.uid, note: 'Status changed to $newStatus');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Details'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: svc.poRef.doc(poId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final history = (data['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final status = data['status'] ?? 'unknown';
          final buyerName = data['buyerName'] ?? '—';
          final buyerContact = data['buyerContact'] ?? '—';
          final farmerId = data['farmerId'] ?? '—';
          final totalAmount = data['totalAmount'] ?? 0;
          final createdAt = data['createdAt'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: $poId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Status: $status', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Created: ${_formatTimestamp(createdAt)}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Small actions column
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _changeStatus(context, 'confirmed'),
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _changeStatus(context, 'completed'),
                          icon: const Icon(Icons.done_all),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Buyer & Contact
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(buyerName),
                  subtitle: Text('Buyer • Contact: $buyerContact'),
                ),
                const SizedBox(height: 12),

                // Farmer info (if you want to display farmerId)
                if (farmerId != '—')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.store, color: Colors.green),
                    title: Text('Farmer ID: $farmerId'),
                    subtitle: const Text('Tap to view farmer (not implemented)'),
                    onTap: () {
                      // placeholder for future farmer details navigation
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farmer details not implemented')));
                    },
                  ),

                const Divider(),

                // Items list
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...items.map((it) {
                  final listingId = it['listingId'] ?? '—';
                  final qty = it['qtyKg'] ?? 0;
                  final price = it['pricePerKg'] ?? 0;
                  final itemTs = it['createdAt'];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.local_florist, color: Colors.green),
                      title: Text(listingId.toString()),
                      subtitle: Text('$qty kg × ₹$price\nAdded: ${_formatTimestamp(itemTs)}'),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
                Text('Total: ₹$totalAmount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                // History / Timeline
                const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  const Text('No history entries.')
                else
                  Column(
                    children: history.reversed.map((h) {
                      final hStatus = h['status'] ?? '';
                      final hBy = h['by'] ?? '';
                      final hNote = h['note'] ?? '';
                      final hTs = h['ts'];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history, color: Colors.green),
                        title: Text(hStatus),
                        subtitle: Text('By: $hBy\n$hNote\nAt: ${_formatTimestamp(hTs)}'),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // Actions: Contact buyer (if phone number) and Refresh
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Attempt to open dialer with buyerContact if it's a phone number.
                        // We avoid adding url_launcher dependency here; instead show snackbar as placeholder.
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contact: $buyerContact')));
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact Buyer'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Force rebuild by navigating to self (cheap refresh) or simply show snackbar.
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing...')));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    )
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
