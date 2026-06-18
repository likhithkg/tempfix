// lib/exporter_hub/purchase_order_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_service.dart';
import 'po_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

/// PurchaseOrderListPage
/// - If `buyerId` is provided, it will show orders for that buyerId.
/// - If `buyerId` is null, it will use the currently authenticated user.
/// - If no user is signed in, shows a friendly prompt and a button to open login.
class PurchaseOrderListPage extends StatefulWidget {
  final String? buyerId;
  const PurchaseOrderListPage({Key? key, this.buyerId}) : super(key: key);

  @override
  State<PurchaseOrderListPage> createState() => _PurchaseOrderListPageState();
}

class _PurchaseOrderListPageState extends State<PurchaseOrderListPage> {
  final _svc = ExporterService();
  User? _user;
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
    // capture current user once for immediate decision
    _user = FirebaseAuth.instance.currentUser;
    _authStream.listen((u) {
      if (mounted) {
        setState(() {
          _user = u;
        });
      }
    });
  }

  /// Helper to get effective buyer id: explicit param > signed-in user uid
  String? get _effectiveBuyerId {
    return widget.buyerId ?? _user?.uid;
  }

  String _formatDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) {
        final dt = createdAt.toDate();
        return '${dt.day}/${dt.month}/${dt.year}';
      } else if (createdAt is Map && createdAt.containsKey('_seconds')) {
        final ts = DateTime.fromMillisecondsSinceEpoch((createdAt['_seconds'] as int) * 1000);
        return '${ts.day}/${ts.month}/${ts.year}';
      } else if (createdAt is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
        return '${dt.day}/${dt.month}/${dt.year}';
      } else if (createdAt is String) {
        final dt = DateTime.tryParse(createdAt);
        if (dt != null) return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}
    return '—';
  }

  /// Helper widget: render product name. Tries PO items[0].productName, otherwise fetches export_products doc by listingId.
  Widget _productNameWidget(Map<String, dynamic> po) {
    final items = (po['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (items.isEmpty) {
      return const Text('Product: N/A');
    }
    final first = items[0];
    final productNameField = (first['productName'] ?? first['name'])?.toString();
    final listingId = (first['listingId'] ?? '').toString();

    if (productNameField != null && productNameField.isNotEmpty) {
      return Text('Product: $productNameField');
    }

    if (listingId.isEmpty) {
      return const Text('Product: N/A');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('export_products').doc(listingId).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('Product: loading...');
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('Product: not found');
        }
        final pdata = snap.data!.data() as Map<String, dynamic>;
        final name = (pdata['productName'] ?? pdata['name'] ?? pdata['title'])?.toString() ?? 'Unnamed Product';
        return Text('Product: $name');
      },
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    Color color;
    switch (s) {
      case 'completed':
        color = Colors.green;
        break;
      case 'accepted':
        color = Colors.green.shade700;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'issued':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBuyerId = _effectiveBuyerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myPurchaseOrdersTitle),
        backgroundColor: Colors.green,
      ),
      body: effectiveBuyerId == null
          ? _buildNotSignedIn(context)
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _svc.streamPOsForBuyer(effectiveBuyerId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  // Show helpful error + one-line hint for index/rules issues
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text('Error loading orders: ${snap.error}', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          const Text(
                            'If you see a "requires an index" message, create the composite index in Firebase console for (ownerId or buyerId) + createdAt. '
                            'If you see a permission error, check Firestore rules.',
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final orders = snap.data ?? [];
                if (orders.isEmpty) {
                  return const Center(child: Text('No orders placed yet.'));
                }

                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final po = orders[i];
                    // id might be a string, DocumentReference, or missing — handle defensively
                    final idObj = po['id'];
                    final id = idObj is String ? idObj : idObj?.toString() ?? '—';
                    final total = po['totalAmount'] ?? 0;
                    final status = (po['status'] ?? 'issued').toString();
                    final createdAt = po['createdAt'];
                    final when = _formatDate(createdAt);

                    Color statusColor;
                    switch (status.toLowerCase()) {
                      case 'completed':
                        statusColor = Colors.green;
                        break;
                      case 'confirmed':
                        statusColor = Colors.blue;
                        break;
                      case 'accepted':
                        statusColor = Colors.green.shade700;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.orange;
                    }

                    // Stream for the latest buyer response for this PO.
                    final responsesStream = FirebaseFirestore.instance
                        .collection('purchase_orders')
                        .doc(id)
                        .collection('buyer_responses')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots();

                    // Farmer name fallback logic
                    final farmerName = (po['farmerName'] ?? po['sellerName'] ?? po['ownerName'] ?? po['farmerId'] ?? 'Unknown Farmer').toString();

                    return StreamBuilder<QuerySnapshot>(
                      stream: responsesStream,
                      builder: (context, rs) {
                        Widget trailing = TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PODetailPage(poId: id)));
                          },
                          child: const Text('View Details'),
                        );

                        // Build subtitle — show product, total, status badge + date (and optional response snippet)
                        Widget subtitleWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _productNameWidget(po),
                            const SizedBox(height: 6),
                            Text('Total: ₹$total', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _statusBadge(status),
                                const SizedBox(width: 12),
                                Text('Date: $when', style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        );

                        if (rs.hasError) {
                          // ignore response stream error — keep normal subtitle
                        } else if (rs.connectionState == ConnectionState.active && rs.hasData && rs.data!.docs.isNotEmpty) {
                          final respDoc = rs.data!.docs.first;
                          final respMsg = (respDoc['message'] ?? '').toString();
                          final respStatus = (respDoc['responseStatus'] ?? '').toString().toLowerCase();
                          String snippet = respMsg.length > 40 ? '${respMsg.substring(0, 40)}…' : respMsg;

                          Color respColor;
                          switch (respStatus) {
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

                          subtitleWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _productNameWidget(po),
                              const SizedBox(height: 6),
                              Text('Total: ₹$total', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _statusBadge(status),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: respColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: respColor),
                                    ),
                                    child: Text(respStatus.toUpperCase(), style: TextStyle(color: respColor, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(snippet.isNotEmpty ? snippet : 'Buyer responded', overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Date: $when', style: const TextStyle(color: Colors.grey)),
                            ],
                          );
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: FutureBuilder<DocumentSnapshot?>(
  future: (() {
    final items =
        (po['items'] as List?)
                ?.cast<
                    Map<String, dynamic>>()
            ??
            [];

    if (items.isEmpty) {
      return Future.value(null);
    }

    final first = items.first;

    final listingId =
        (first['listingId'] ??
                first['productId'] ??
                '')
            .toString();

    if (listingId.isEmpty) {
      return Future.value(null);
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
          statusColor.withOpacity(
        0.12,
      ),

      backgroundImage:
          imageProvider,

      onBackgroundImageError:
          (_, __) {},

      child: null,
    );
  },
),
                            title: Text(farmerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Padding(padding: const EdgeInsets.only(top: 6.0), child: subtitleWidget),
                            isThreeLine: true,
                            trailing: trailing,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PODetailPage(poId: id))),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Please sign in to view your purchase orders.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              // Navigate to your app's login route. Adjust if your route name is different.
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Go to Login'),
          )
        ]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
