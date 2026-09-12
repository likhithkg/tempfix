// lib/exporter_hub/purchase_order_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_service.dart';
import 'po_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

/// PurchaseOrderListPage
/// - `isAdmin: true` → streams ALL purchase orders (admin oversight mode).
/// - `buyerId` → show orders for that specific buyer.
/// - If both are omitted, uses the signed-in user's UID as buyerId.
class PurchaseOrderListPage extends StatefulWidget {
  final String? buyerId;
  final bool isAdmin;
  const PurchaseOrderListPage({super.key, this.buyerId, this.isAdmin = false});

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
      return Builder(builder: (ctx) => Text(AppLocalizations.of(ctx)!.productNA));
    }
    final first = items[0];
    final productNameField = (first['productName'] ?? first['name'])?.toString();
    final listingId = (first['listingId'] ?? '').toString();

    if (productNameField != null && productNameField.isNotEmpty) {
      return Builder(builder: (ctx) => Text(AppLocalizations.of(ctx)!.productNameItem(productNameField)));
    }

    if (listingId.isEmpty) {
      return Builder(builder: (ctx) => Text(AppLocalizations.of(ctx)!.productNA));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('export_products').doc(listingId).get(),
      builder: (context, snap) {
        final l = AppLocalizations.of(context)!;
        if (snap.connectionState == ConnectionState.waiting) {
          return Text(l.productLoading);
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Text(l.productNotFoundItem);
        }
        final pdata = snap.data!.data() as Map<String, dynamic>;
        final name = (pdata['productName'] ?? pdata['name'] ?? pdata['title'])?.toString() ?? 'Unnamed Product';
        return Text(l.productNameItem(name));
      },
    );
  }

  Widget _statusBadge(String rawStatus) {
    final s = rawStatus.toLowerCase();
    Color color;
    switch (s) {
      case 'exported':            color = Colors.green.shade700; break;
      case 'ready_for_export':    color = Colors.teal; break;
      case 'qc_approved':
      case 'completed':
      case 'accepted':            color = Colors.green; break;
      case 'qc_rejected':
      case 'rejected':            color = Colors.red; break;
      case 'cancelled':           color = Colors.red.shade300; break;
      case 'farmer_accepted':
      case 'collection_scheduled':
      case 'collected':
      case 'confirmed':           color = Colors.blue; break;
      case 'qc_pending':          color = Colors.purple; break;
      case 'po_issued':
      case 'issued':              color = Colors.indigo; break;
      case 'price_negotiation':   color = Colors.orange; break;
      case 'under_review':        color = Colors.amber.shade700; break;
      case 'listed':
      case 'pending':             color = Colors.teal.shade400; break;
      case 'draft':               color = Colors.grey; break;
      default:                    color = Colors.grey;
    }
    return Builder(builder: (ctx) {
      final l = AppLocalizations.of(ctx)!;
      String label;
      switch (s) {
        case 'draft':                label = l.statusDraft; break;
        case 'listed':
        case 'pending':              label = l.statusListed; break;
        case 'under_review':         label = l.statusUnderReview; break;
        case 'price_negotiation':    label = l.statusPriceNegotiation; break;
        case 'po_issued':
        case 'issued':               label = l.statusPoIssued; break;
        case 'farmer_accepted':
        case 'accepted':             label = l.statusFarmerAccepted; break;
        case 'collection_scheduled': label = l.statusCollectionScheduled; break;
        case 'collected':
        case 'confirmed':            label = l.statusCollected; break;
        case 'qc_pending':           label = l.statusQcPending; break;
        case 'qc_approved':
        case 'approved':
        case 'completed':            label = l.statusQcApproved; break;
        case 'qc_rejected':          label = l.statusQcRejected; break;
        case 'ready_for_export':     label = l.statusReadyForExport; break;
        case 'exported':             label = l.statusExported; break;
        case 'rejected':             label = l.statusRejected; break;
        case 'cancelled':            label = l.statusCancelled; break;
        default:                     label = rawStatus;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBuyerId = _effectiveBuyerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'All Purchase Orders' : AppLocalizations.of(context)!.myPurchaseOrdersTitle),
        backgroundColor: Colors.green,
      ),
      body: (!widget.isAdmin && effectiveBuyerId == null)
          ? _buildNotSignedIn(context)
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.isAdmin
                  ? _svc.streamAllPOs()
                  : _svc.streamPOsForBuyer(effectiveBuyerId!),
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
                          Text('${AppLocalizations.of(context)!.errorLoadingOrders}: ${snap.error}', style: const TextStyle(color: Colors.red)),
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
                  return Center(child: Text(AppLocalizations.of(context)!.noOrdersPlacedYet));
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
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PODetailPage(poId: id, isAdmin: widget.isAdmin)));
                          },
                          child: Text(AppLocalizations.of(context)!.viewDetails),
                        );

                        // Build subtitle — show product, total, status badge + date (and optional response snippet)
                        Widget subtitleWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _productNameWidget(po),
                            const SizedBox(height: 6),
                            Text(AppLocalizations.of(context)!.totalAmountValue(total), style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _statusBadge(status),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context)!.dateValue(when), style: const TextStyle(color: Colors.grey)),
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
                              Text(AppLocalizations.of(context)!.totalAmountValue(total), style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _statusBadge(status),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: respColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: respColor),
                                    ),
                                    child: Text(respStatus.toUpperCase(), style: TextStyle(color: respColor, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(snippet.isNotEmpty ? snippet : AppLocalizations.of(context)!.buyerResponsesSection, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(AppLocalizations.of(context)!.dateValue(when), style: const TextStyle(color: Colors.grey)),
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

      backgroundColor: Colors.green.withValues(alpha: 0.12),

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
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PODetailPage(poId: id, isAdmin: widget.isAdmin))),
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
          Text(AppLocalizations.of(context)!.pleaseSignInViewPurchaseOrders, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text(AppLocalizations.of(context)!.goToLogin),
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
