// lib/exporter_hub/po_detail_page.dart
// Simple, user-friendly Order Detail page.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'exporter_service.dart';
import '../theme.dart';

class PODetailPage extends StatelessWidget {
  final String poId;
  final bool isAdmin;
  const PODetailPage({super.key, required this.poId, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final svc = ExporterService();

    return StreamBuilder<Map<String, dynamic>?>(
      stream: svc.streamPOById(poId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
                title: const Text('Order Details'),
                backgroundColor: KMColors.primary,
                foregroundColor: Colors.white),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            appBar: AppBar(
                title: const Text('Order Details'),
                backgroundColor: KMColors.primary,
                foregroundColor: Colors.white),
            body: const Center(child: Text('Order not found')),
          );
        }

        final data = snap.data!;
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final farmerId = (data['farmerId'] ?? '').toString();
        final status = (data['status'] ?? 'pending').toString();
        final isFarmer = currentUid != null && currentUid == farmerId;
        final isNew = status == 'pending' || status == 'issued' || status == 'listed';
        final isActive = const {
          'confirmed',
          'preparing',
          'ready',
          'out_for_delivery',
          'farmer_accepted',
          'collection_scheduled',
          'collected',
          'qc_pending',
          'qc_approved',
          'ready_for_export',
        }.contains(status);
        final isFinalized = const {
          'delivered',
          'exported',
          'completed',
          'cancelled',
          'rejected',
          'qc_rejected',
        }.contains(status);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF7),
          appBar: AppBar(
            title: const Text('Order Details'),
            backgroundColor: KMColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product Summary ──
                _ProductSummaryCard(data: data),
                const SizedBox(height: 16),

                // ── Progress Tracker ──
                _OrderProgressTracker(status: status),
                const SizedBox(height: 16),

                // ── Farmer: accept/reject new orders ──
                if (isFarmer && isNew) ...[
                  _FarmerActionCard(
                    buyerName: (data['buyerName'] ?? '').toString(),
                    onAccept: () async {
                      await svc.updatePOStatus(poId, 'confirmed', currentUid,
                          note: 'Farmer confirmed the order');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Order confirmed'),
                            backgroundColor: Colors.green));
                      }
                    },
                    onReject: () async {
                      final ok = await _confirm(
                          context, 'Reject Order?', 'Are you sure?');
                      if (ok == true && context.mounted) {
                        await svc.updatePOStatus(poId, 'rejected', currentUid,
                            note: 'Farmer rejected the order');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Farmer: update active order status ──
                if (isFarmer && isActive && !isFinalized) ...[
                  _StatusUpdateCard(
                      orderId: poId, currentStatus: status, svc: svc, byUid: currentUid),
                  const SizedBox(height: 16),
                ],

                // ── Admin controls ──
                if (isAdmin && !isFarmer) ...[
                  _AdminStatusCard(
                      orderId: poId,
                      currentStatus: status,
                      svc: svc,
                      currentUid: currentUid),
                  const SizedBox(height: 16),
                ],

                // ── Contact Details ──
                _ContactSection(
                  poData: data,
                  poItems: (data['items'] as List?)
                          ?.cast<Map<String, dynamic>>() ??
                      [],
                ),
                const SizedBox(height: 16),

                // ── Order Info ──
                _OrderInfoCard(data: data),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirm(BuildContext ctx, String title, String msg) =>
      showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Confirm', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
}

// ── Product Summary Card ──────────────────────────────────────────────────────

class _ProductSummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductSummaryCard({required this.data});

  String _productName() {
    final n = (data['productName'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    try {
      final items =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (items.isNotEmpty) {
        return (items.first['productName'] ?? items.first['name'] ?? 'Product')
            .toString();
      }
    } catch (_) {}
    return 'Product';
  }

  String _imageUrl() {
    final img = (data['productImage'] ?? '').toString().trim();
    if (img.isNotEmpty) return img;
    try {
      final items =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (items.isNotEmpty) {
        return (items.first['productImage'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final productName = _productName();
    final imageUrl = _imageUrl();
    final quantity = data['quantity'];
    final unit = (data['unit'] ?? '').toString();
    final pricePerUnit = data['pricePerUnit'];
    final total = data['totalAmount'] ?? 0;
    final delivery = (data['deliveryAddress'] ?? '').toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ImgFallback())
                      : const _ImgFallback(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(productName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2),
                    if (quantity != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          '${quantity.toString()} ${unit.isNotEmpty ? unit : 'units'}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                    if (pricePerUnit != null)
                      Text(
                          '₹$pricePerUnit / ${unit.isNotEmpty ? unit : 'unit'}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ]),
            const Divider(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '₹${total is double ? total.toStringAsFixed(0) : total}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: KMColors.primary),
              ),
            ]),
            if (delivery.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(delivery,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
          child: Icon(Icons.grain, color: Colors.white54, size: 26)),
    );
  }
}

// ── Progress Tracker ──────────────────────────────────────────────────────────

class _OrderProgressTracker extends StatelessWidget {
  final String status;
  const _OrderProgressTracker({required this.status});

  static const _steps = [
    ('pending', 'Order\nPlaced'),
    ('confirmed', 'Confirmed'),
    ('preparing', 'Preparing'),
    ('ready', 'Ready'),
    ('out_for_delivery', 'On\nthe Way'),
    ('delivered', 'Delivered'),
  ];

  String _normalize(String s) {
    switch (s.toLowerCase()) {
      case 'issued':
      case 'listed':
      case 'under_review':
      case 'price_negotiation':
      case 'po_issued':
        return 'pending';
      case 'farmer_accepted':
      case 'accepted':
        return 'confirmed';
      case 'collection_scheduled':
      case 'collected':
      case 'qc_pending':
        return 'preparing';
      case 'qc_approved':
      case 'ready_for_export':
        return 'ready';
      case 'exported':
      case 'completed':
        return 'delivered';
      default:
        return s.toLowerCase();
    }
  }

  int _currentIndex(String s) {
    final n = _normalize(s);
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == n) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final norm = _normalize(status);
    final isCancelled = norm == 'cancelled';
    final isRejected = norm == 'rejected' || norm == 'qc_rejected';

    if (isCancelled || isRejected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(children: [
          const Icon(Icons.cancel_outlined, color: Colors.red),
          const SizedBox(width: 10),
          Text(
            isCancelled ? 'Order Cancelled' : 'Order Rejected by Farmer',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ]),
      );
    }

    final currentIdx = _currentIndex(status);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Status',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final isDone = stepIdx < currentIdx;
                  return Expanded(
                    child: Container(
                        height: 2,
                        color: isDone
                            ? KMColors.primary
                            : Colors.grey.shade200),
                  );
                }
                final stepIdx = i ~/ 2;
                final isDone = stepIdx < currentIdx;
                final isCurrent = stepIdx == currentIdx;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isCurrent ? 28 : 22,
                      height: isCurrent ? 28 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? KMColors.primary
                            : (isCurrent
                                ? KMColors.primary
                                : Colors.transparent),
                        border: (isDone || isCurrent)
                            ? null
                            : Border.all(
                                color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : isCurrent
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle))
                                : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 46,
                      child: Text(
                        _steps[stepIdx].$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (isCurrent || isDone)
                              ? KMColors.primaryDark
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Farmer Action Card ────────────────────────────────────────────────────────

class _FarmerActionCard extends StatelessWidget {
  final String buyerName;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _FarmerActionCard(
      {required this.buyerName,
      required this.onAccept,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.notifications_active_outlined,
              color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('New Order',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.orange)),
        ]),
        const SizedBox(height: 6),
        Text(
          buyerName.isNotEmpty ? 'From: $buyerName' : 'A buyer placed an order',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onAccept,
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onReject,
              child: const Text('Reject'),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Status Update Card ────────────────────────────────────────────────────────

class _StatusUpdateCard extends StatelessWidget {
  final String orderId;
  final String currentStatus;
  final ExporterService svc;
  final String byUid;
  const _StatusUpdateCard(
      {required this.orderId,
      required this.currentStatus,
      required this.svc,
      required this.byUid});

  static const _next = {
    'confirmed': ('preparing', 'Mark as Preparing'),
    'farmer_accepted': ('preparing', 'Mark as Preparing'),
    'preparing': ('ready', 'Mark as Ready'),
    'collection_scheduled': ('ready', 'Mark as Ready'),
    'collected': ('ready', 'Mark as Ready'),
    'qc_pending': ('ready', 'Mark as Ready'),
    'qc_approved': ('ready', 'Mark as Ready'),
    'ready': ('out_for_delivery', 'Mark as Out for Delivery'),
    'ready_for_export': ('out_for_delivery', 'Mark as Out for Delivery'),
    'out_for_delivery': ('delivered', 'Mark as Delivered'),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _next[currentStatus];
    if (entry == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Update Status',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await svc.updatePOStatus(orderId, entry.$1, byUid,
                  note: 'Status updated by farmer');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(entry.$2)));
              }
            },
            child: Text(entry.$2),
          ),
        ],
      ),
    );
  }
}

// ── Admin Status Card ─────────────────────────────────────────────────────────

class _AdminStatusCard extends StatelessWidget {
  final String orderId;
  final String currentStatus;
  final ExporterService svc;
  final String? currentUid;
  const _AdminStatusCard(
      {required this.orderId,
      required this.currentStatus,
      required this.svc,
      this.currentUid});

  static const _statuses = [
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('preparing', 'Preparing'),
    ('ready', 'Ready'),
    ('out_for_delivery', 'Out for Delivery'),
    ('delivered', 'Delivered'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final finalized = const [
      'delivered',
      'cancelled',
      'rejected',
      'exported',
      'completed',
    ].contains(currentStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 18, color: Colors.amber),
            SizedBox(width: 8),
            Text('Admin Controls',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          if (!finalized)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses
                  .where((s) => s.$1 != currentStatus)
                  .map((s) => OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          if (currentUid == null) return;
                          await svc.updatePOStatus(
                              orderId, s.$1, currentUid!,
                              note: 'Admin updated status');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('→ ${s.$2}')));
                          }
                        },
                        child: Text('→ ${s.$2}',
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            )
          else
            Text('Finalized: $currentStatus',
                style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Contact Section ───────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  final Map<String, dynamic> poData;
  final List<Map<String, dynamic>> poItems;
  const _ContactSection({required this.poData, required this.poItems});

  @override
  Widget build(BuildContext context) {
    final listingId = poItems.isNotEmpty
        ? (poItems.first['listingId'] ?? poItems.first['productId'] ?? '').toString()
        : '';
    final farmerId = (poData['farmerId'] ?? '').toString();
    final buyerName = (poData['buyerName'] ?? '').toString();
    final buyerPhone = (poData['buyerContact'] ?? poData['buyerPhone'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),

        // Farmer card
        if (listingId.isNotEmpty)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('export_products')
                .doc(listingId)
                .get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingCard(Colors.green);
              }
              String name = '', phone = '', location = '';
              if (snap.hasData && snap.data!.exists) {
                final d = snap.data!.data() as Map<String, dynamic>;
                name = (d['farmerName'] ?? d['name'] ?? '').toString();
                phone =
                    (d['farmerMobile'] ?? d['farmerPhone'] ?? '').toString();
                location = (d['location'] ?? '').toString();
              }
              if (name.isEmpty && farmerId.isNotEmpty) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(farmerId)
                      .get(),
                  builder: (ctx, uSnap) {
                    String uName = name, uPhone = phone;
                    if (uSnap.hasData && uSnap.data!.exists) {
                      final ud = uSnap.data!.data() as Map<String, dynamic>;
                      uName =
                          (ud['displayName'] ?? ud['name'] ?? '').toString();
                      uPhone = (ud['phone'] ?? ud['phoneNumber'] ?? '').toString();
                    }
                    return _ContactCard(
                      role: 'Seller (Farmer)',
                      icon: Icons.agriculture_rounded,
                      accent: Colors.green,
                      name: uName.isEmpty ? '—' : uName,
                      phone: uPhone.isEmpty ? null : uPhone,
                      location: null,
                    );
                  },
                );
              }
              return _ContactCard(
                role: 'Seller (Farmer)',
                icon: Icons.agriculture_rounded,
                accent: Colors.green,
                name: name.isEmpty ? '—' : name,
                phone: phone.isEmpty ? null : phone,
                location: location.isEmpty ? null : location,
              );
            },
          )
        else if (farmerId.isNotEmpty)
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(farmerId)
                .get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _loadingCard(Colors.green);
              }
              String name = '', phone = '';
              if (snap.hasData && snap.data!.exists) {
                final d = snap.data!.data() as Map<String, dynamic>;
                name = (d['displayName'] ?? d['name'] ?? '').toString();
                phone =
                    (d['phone'] ?? d['phoneNumber'] ?? '').toString();
              }
              return _ContactCard(
                role: 'Seller (Farmer)',
                icon: Icons.agriculture_rounded,
                accent: Colors.green,
                name: name.isEmpty ? '—' : name,
                phone: phone.isEmpty ? null : phone,
                location: null,
              );
            },
          ),

        const SizedBox(height: 10),

        _ContactCard(
          role: 'Buyer',
          icon: Icons.person_rounded,
          accent: Colors.indigo,
          name: buyerName.isEmpty ? '—' : buyerName,
          phone: buyerPhone.isEmpty ? null : buyerPhone,
          location: null,
        ),
      ],
    );
  }

  Widget _loadingCard(Color accent) => Container(
        height: 60,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
}

class _ContactCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final Color accent;
  final String name;
  final String? phone;
  final String? location;
  const _ContactCard({
    required this.role,
    required this.icon,
    required this.accent,
    required this.name,
    this.phone,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 10),
              Text(role,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: accent)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.person_rounded, 'Name', name),
                const SizedBox(height: 8),
                _row(Icons.phone_rounded, 'Phone', phone ?? '—'),
                if (location != null) ...[
                  const SizedBox(height: 8),
                  _row(Icons.location_on_rounded, 'Location', location!),
                ],
                if (phone != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _btn(Icons.call_rounded, 'Call',
                            Colors.green, () => _launch('tel:$phone'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _btn(
                            Icons.chat_rounded,
                            'WhatsApp',
                            const Color(0xFF25D366),
                            () => _launch(
                                'https://wa.me/${phone!.replaceAll(RegExp(r'[^0-9+]'), '')}'))),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData ico, String label, String value) => Row(children: [
        Icon(ico, size: 15, color: accent.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        SizedBox(
            width: 58,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500))),
      ]);

  Widget _btn(IconData ico, String label, Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(ico, size: 15, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Order Info Card ───────────────────────────────────────────────────────────

class _OrderInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OrderInfoCard({required this.data});

  String _fmt(dynamic ts) {
    try {
      DateTime? dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(ts);
      } else if (ts is String) {
        dt = DateTime.tryParse(ts);
      }
      if (dt != null) {
        return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final id = (data['id'] ?? '').toString();
    final shortId =
        id.length >= 8 ? '#${id.substring(0, 8).toUpperCase()}' : '#$id';

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Info',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _row('Order ID', shortId),
            const SizedBox(height: 6),
            _row('Placed on', _fmt(data['createdAt'])),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      );
}
