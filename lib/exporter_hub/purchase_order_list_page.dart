// lib/exporter_hub/purchase_order_list_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD THIS LINE
import 'exporter_service.dart';
import 'po_detail_page.dart'; // make sure this file exists and defines PODetailPage

class PurchaseOrderListPage extends StatelessWidget {
  final ExporterService svc = ExporterService();
  final String? buyerId;

  PurchaseOrderListPage({super.key, this.buyerId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = buyerId ?? user?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your orders')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Purchase Orders'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: svc.streamPOsForBuyer(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders placed yet.'));
          }

          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final po = orders[index];
              final id = po['id'] ?? '—';
              final total = (po['totalAmount'] ?? 0).toString();
              final status = po['status'] ?? 'unknown';
              final createdAt = po['createdAt'];
              String timeLabel = '';

              try {
                if (createdAt is Map && createdAt.containsKey('_seconds')) {
                  final ts = DateTime.fromMillisecondsSinceEpoch(createdAt['_seconds'] * 1000);
                  timeLabel = '${ts.day}/${ts.month}/${ts.year}';
                } else if (createdAt is Timestamp) {
                  final dt = createdAt.toDate();
                  timeLabel = '${dt.day}/${dt.month}/${dt.year}';
                }
              } catch (_) {
                timeLabel = '';
              }

              return ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.green),
                title: Text('Order ${id.toString().substring(0, id.toString().length >= 6 ? 6 : id.toString().length)}'),
                subtitle: Text('Total: ₹$total  •  Status: $status\n$timeLabel'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PODetailPage(poId: id)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
       