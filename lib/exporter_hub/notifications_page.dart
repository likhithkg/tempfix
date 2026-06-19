// lib/exporter_hub/notifications_page.dart
// Notification Center — reads from Firestore `km_notifications` collection.
// Notifications are written server-side or by role-based operations.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

// Helper to write a notification (call from any service)
class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> send({
    required String userId,     // '' = broadcast to all admins
    required String type,       // see _kTypes
    required String title,
    required String body,
    String? referenceId,
    String? referenceType,
  }) async {
    await _db.collection('km_notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      if (referenceId != null) 'referenceId': referenceId,
      if (referenceType != null) 'referenceType': referenceType,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markRead(String notifId) async {
    await _db.collection('km_notifications').doc(notifId).update({'isRead': true});
  }

  static Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection('km_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_listing': return Icons.add_box_outlined;
      case 'demand_response': return Icons.reply_outlined;
      case 'po_accepted': return Icons.check_circle_outline;
      case 'po_rejected': return Icons.cancel_outlined;
      case 'qc_completed': return Icons.science_outlined;
      case 'shipment_dispatched': return Icons.flight_takeoff;
      case 'shipment_delivered': return Icons.flight_land;
      case 'warehouse_received': return Icons.inventory_2_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_listing': return Colors.teal;
      case 'demand_response': return Colors.blue;
      case 'po_accepted': return Colors.green;
      case 'po_rejected': return Colors.red;
      case 'qc_completed': return Colors.purple;
      case 'shipment_dispatched': return Colors.indigo;
      case 'shipment_delivered': return Colors.green.shade700;
      case 'warehouse_received': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db = FirebaseFirestore.instance;

    // Stream notifications for this user OR broadcast (userId == '')
    final stream = db
        .collection('km_notifications')
        .where('userId', whereIn: [uid, ''])
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationCenter),
        actions: [
          if (uid.isNotEmpty)
            TextButton(
              onPressed: () => NotificationService.markAllRead(uid),
              child: Text(l.markAllRead, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none_outlined, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(l.noNotificationsYet,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final notifId = docs[i].id;
              final type = data['type']?.toString() ?? '';
              final title = data['title']?.toString() ?? '';
              final body = data['body']?.toString() ?? '';
              final isRead = data['isRead'] == true;
              final color = _colorForType(type);
              final ts = data['createdAt'];
              String dateStr = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                dateStr = '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return Dismissible(
                key: Key(notifId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await db.collection('km_notifications').doc(notifId).delete();
                },
                child: ListTile(
                  onTap: () => NotificationService.markRead(notifId),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_iconForType(type), color: color, size: 20),
                  ),
                  title: Text(title,
                      style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14)),
                  subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  trailing: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(dateStr, style: const TextStyle(fontSize: 10)),
                    if (!isRead)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      ),
                  ]),
                  tileColor: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.08),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
