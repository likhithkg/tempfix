// lib/exporter_hub/warehouse_transaction_page.dart
import 'package:flutter/material.dart';
import 'warehouse_service.dart';
import 'warehouse_model.dart';
import '../l10n/app_localizations.dart';

class WarehouseTransactionPage extends StatelessWidget {
  const WarehouseTransactionPage({super.key});

  Color _typeColor(String type) {
    switch (type) {
      case 'received': return Colors.green;
      case 'dispatched': return Colors.red;
      case 'reserved': return Colors.orange;
      case 'adjusted': return Colors.blue;
      case 'rejected': return Colors.red.shade300;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'received': return Icons.add_circle_outline;
      case 'dispatched': return Icons.remove_circle_outline;
      case 'reserved': return Icons.lock_outline;
      case 'adjusted': return Icons.tune;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final svc = WarehouseService();

    return Scaffold(
      appBar: AppBar(title: Text(l.stockMovementHistory)),
      body: StreamBuilder<List<WarehouseTransaction>>(
        stream: svc.streamTransactions(limit: 100),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snap.data ?? [];
          if (txs.isEmpty) {
            return Center(child: Text(l.noTransactionsYet,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final tx = txs[i];
              final type = tx.transactionType;
              final color = _typeColor(type);
              final qty = tx.quantity;
              final sign = type == 'received' ? '+' : (type == 'dispatched' ? '-' : '');
              final dt = tx.createdAt;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(_typeIcon(type), color: color, size: 20),
                ),
                title: Row(children: [
                  Expanded(child: Text(tx.cropName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('$sign${qty.toStringAsFixed(1)} ${tx.unit}',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ]),
                subtitle: Text(
                  '${tx.batchId} • $type • ${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}\n${l.byLabel}: ${tx.performedByName}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
