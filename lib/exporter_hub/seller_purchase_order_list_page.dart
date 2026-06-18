// lib/exporter_hub/seller_purchase_order_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'po_detail_page.dart';
import '../l10n/app_localizations.dart';

class SellerPurchaseOrderListPage extends StatefulWidget {
  const SellerPurchaseOrderListPage({super.key});

  @override
  State<SellerPurchaseOrderListPage> createState() => _SellerPurchaseOrderListPageState();
}

String _localizedStatus(AppLocalizations l, String status) {
  switch (status.toLowerCase()) {
    case 'pending':   return l.statusPending;
    case 'approved':  return l.statusApproved;
    case 'rejected':  return l.statusRejected;
    case 'accepted':  return l.statusAccepted;
    case 'confirmed': return l.statusConfirmed;
    case 'completed': return l.statusCompleted;
    case 'cancelled': return l.statusCancelled;
    case 'issued':    return l.statusIssued;
    default:          return status;
  }
}

class _SellerPurchaseOrderListPageState extends State<SellerPurchaseOrderListPage> {
  User? _user;
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    _user = FirebaseAuth.instance.currentUser;
    _authStream.listen((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _user;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myListingsTab),
        backgroundColor: Colors.green,
      ),
      body: current == null
          ? _buildNotSignedIn(context)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('purchase_orders')
                  .where('farmerId', isEqualTo: current.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading orders: ${snap.error}', style: const TextStyle(color: Colors.red)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noOrdersForListingsYet));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final m = d.data() as Map<String, dynamic>;
                    final id = d.id;
                    final total = m['totalAmount'] ?? 0;
                    final status = (m['status'] ?? 'pending').toString();
                    final createdAt = m['createdAt'];

                    // 🔹 Extract crop/product name
                    String extractCropName(Map<String, dynamic> order) {
                      String? getStr(dynamic v) {
                        if (v is String && v.trim().isNotEmpty) return v.trim();
                        return null;
                      }

                      // Common direct keys
                      final directKeys = ['productName', 'product_name', 'crop', 'listingTitle', 'title', 'name'];
                      for (final k in directKeys) {
                        final s = getStr(order[k]);
                        if (s != null) return s;
                      }

                      // nested listingData
                      final listing = order['listingData'];
                      if (listing is Map<String, dynamic>) {
                        for (final k in directKeys) {
                          final s = getStr(listing[k]);
                          if (s != null) return s;
                        }
                      }

                      // items array (take first)
                      final items = order['items'];
                      if (items is List && items.isNotEmpty) {
                        final first = items.first;
                        if (first is Map<String, dynamic>) {
                          for (final k in directKeys) {
                            final s = getStr(first[k]);
                            if (s != null) return s;
                          }
                        } else {
                          final s = getStr(first);
                          if (s != null) return s;
                        }
                      }

                      // fallback
                      return 'Order ${id.length >= 6 ? id.substring(0, 6) : id}';
                    }

                    final cropName = extractCropName(m);

                    // date formatting
                    String when = '';
                    try {
                      if (createdAt is Timestamp) {
                        final ts = createdAt.toDate();
                        when = '${ts.day}/${ts.month}/${ts.year}';
                      } else if (createdAt is Map && createdAt.containsKey('_seconds')) {
                        final ts = DateTime.fromMillisecondsSinceEpoch(createdAt['_seconds'] * 1000);
                        when = '${ts.day}/${ts.month}/${ts.year}';
                      } else if (createdAt is String) {
                        final dt = DateTime.tryParse(createdAt);
                        if (dt != null) when = '${dt.day}/${dt.month}/${dt.year}';
                      }
                    } catch (_) {}

                    Color statusColor;
                    switch (status.toLowerCase()) {
                      case 'accepted':
                      case 'completed':
                        statusColor = Colors.green;
                        break;
                      case 'confirmed':
                        statusColor = Colors.blue;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.orange;
                    }

                    // buyer response stream
                    final respStream = FirebaseFirestore.instance
                        .collection('purchase_orders')
                        .doc(id)
                        .collection('buyer_responses')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots();

                    return StreamBuilder<QuerySnapshot>(
                      stream: respStream,
                      builder: (context, rs) {
                        final l = AppLocalizations.of(context)!;
                        Widget subtitle = Text('${l.totalLabel} ₹$total  •  ${l.statusLabel} ${_localizedStatus(l, status)}\n$when');

                        if (rs.hasData && rs.data!.docs.isNotEmpty) {
                          final rd = rs.data!.docs.first;
                          final r = rd.data() as Map<String, dynamic>;
                          final respStatus = (r['responseStatus'] ?? 'pending').toString();
                          final msg = (r['message'] ?? '').toString();
                          final snippet = msg.isNotEmpty ? (msg.length > 60 ? '${msg.substring(0, 60)}…' : msg) : 'Buyer responded';
                          Color respColor;
                          switch (respStatus.toLowerCase()) {
                            case 'accepted':
                              respColor = Colors.green;
                              break;
                            case 'rejected':
                              respColor = Colors.red;
                              break;
                            case 'pending':
                              respColor = Colors.orange;
                              break;
                            default:
                              respColor = Colors.grey;
                          }

                          subtitle = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${l.totalLabel} ₹$total  •  ${l.statusLabel} ${_localizedStatus(l, status)}'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: respColor.withValues(alpha: 0.12),
                                      border: Border.all(color: respColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _localizedStatus(l, respStatus).toUpperCase(),
                                      style: TextStyle(color: respColor, fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(snippet, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(when, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          );
                        }

                        return ListTile(
                         leading: FutureBuilder<DocumentSnapshot?>(
  future: (() async {
    final items =
        (m['items'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

    if (items.isEmpty) {
      return null;
    }

    final first = items.first;

    final listingId =
        (first['listingId'] ??
                first['productId'] ??
                '')
            .toString();

    if (listingId.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('export_products')
        .doc(listingId)
        .get();
  })(),

  builder: (context, snap) {
    ImageProvider imageProvider =
        const AssetImage(
      'assets/farmer_logo.png',
    );

    if (snap.hasData &&
        snap.data != null &&
        snap.data!.exists) {
      final pdata =
          snap.data!.data()
              as Map<String, dynamic>;

      final img = pdata['imageUrl'];

      if (img != null &&
          img.toString().isNotEmpty) {
        imageProvider = NetworkImage(
          img.toString(),
        );
      }
    }

    return CircleAvatar(
      radius: 28,

      backgroundColor:
          statusColor.withValues(alpha: 0.12),

      backgroundImage:
          imageProvider,

      onBackgroundImageError:
          (_, __) {},

      child: null,
    );
  },
),
                          title: Text(
                            cropName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: subtitle,
                          isThreeLine: true,
                          trailing: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PODetailPage(poId: id)),
                            ),
                            child: Text(AppLocalizations.of(context)!.view),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PODetailPage(poId: id)),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotSignedIn(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.pleaseSignInToViewSeller, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text(AppLocalizations.of(context)!.goToLogin),
            )
          ],
        ),
      ),
    );
  }
}
