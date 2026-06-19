// lib/exporter_hub/po_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_service.dart';
import '../l10n/app_localizations.dart';

// ── 13-Status Procurement Workflow ────────────────────────────────────────────

// Canonical step order for the procurement timeline
const List<String> _procurementSteps = [
  'draft',
  'listed',
  'under_review',
  'price_negotiation',
  'po_issued',
  'farmer_accepted',
  'collection_scheduled',
  'collected',
  'qc_pending',
  'qc_approved',
  'ready_for_export',
  'exported',
];

// Statuses that are off the main path (rejection states)
const Set<String> _rejectionStatuses = {'qc_rejected', 'rejected', 'cancelled'};

// Normalize status aliases → canonical key
String _normalizeStatus(String s) {
  final lower = s.toLowerCase();
  switch (lower) {
    case 'issued': return 'po_issued';
    case 'pending': return 'listed';
    case 'accepted': return 'farmer_accepted';
    case 'confirmed': return 'farmer_accepted';
    case 'completed': return 'exported';
    default: return lower;
  }
}


String _localizedPoStatus(AppLocalizations l, String status) {
  switch (_normalizeStatus(status)) {
    case 'draft': return l.statusDraft;
    case 'listed': return l.statusListed;
    case 'under_review': return l.statusUnderReview;
    case 'price_negotiation': return l.statusPriceNegotiation;
    case 'po_issued': return l.statusPoIssued;
    case 'farmer_accepted': return l.statusFarmerAccepted;
    case 'collection_scheduled': return l.statusCollectionScheduled;
    case 'collected': return l.statusCollected;
    case 'qc_pending': return l.statusQcPending;
    case 'qc_approved': return l.statusQcApproved;
    case 'qc_rejected': return l.statusQcRejected;
    case 'ready_for_export': return l.statusReadyForExport;
    case 'exported': return l.statusExported;
    case 'rejected': return l.statusRejected;
    case 'cancelled': return l.statusCancelled;
    default: return status;
  }
}

Color _statusColor(String status) {
  switch (_normalizeStatus(status)) {
    case 'exported': return Colors.green.shade700;
    case 'ready_for_export': return Colors.teal;
    case 'qc_approved': return Colors.green;
    case 'qc_rejected':
    case 'rejected': return Colors.red;
    case 'cancelled': return Colors.red.shade300;
    case 'farmer_accepted':
    case 'collection_scheduled':
    case 'collected': return Colors.blue;
    case 'qc_pending': return Colors.purple;
    case 'po_issued': return Colors.indigo;
    case 'price_negotiation': return Colors.orange;
    case 'under_review': return Colors.amber.shade700;
    case 'listed': return Colors.teal.shade300;
    case 'draft': return Colors.grey;
    default: return Colors.orange;
  }
}

// ── Purchase Order Detail Page ─────────────────────────────────────────────────

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

  Future<bool?> _confirmDialog(BuildContext context, String title, String body) {
    final l = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l.yes)),
        ],
      ),
    );
  }

  Future<void> _acceptResponse(BuildContext context, DocumentReference responseRef,
      Map<String, dynamic> respData, String poFarmerId) async {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }

    final buyerName = respData['buyerName'] ?? respData['from'] ?? 'Buyer';
    final confirmed = await _confirmDialog(
        context, l.acceptResponseTitle, l.acceptBuyerResponseConfirm(buyerName));
    if (confirmed != true) return;

    final poRef = svc.poRef.doc(poId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(responseRef, {
          'responseStatus': 'accepted',
          'respondedAt': Timestamp.now(),
        });
        tx.update(poRef, {
          'status': 'farmer_accepted',
          'history': FieldValue.arrayUnion([
            {'status': 'farmer_accepted', 'by': user.uid, 'note': 'Accepted buyer: $buyerName', 'ts': Timestamp.now()}
          ]),
        });
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.buyerResponseAccepted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToAcceptResponse)));
      }
    }
  }

  Future<void> _rejectResponse(
      BuildContext context, DocumentReference responseRef, Map<String, dynamic> respData) async {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }

    final buyerName = respData['buyerName'] ?? respData['from'] ?? 'Buyer';
    final confirmed = await _confirmDialog(
        context, l.rejectResponseTitle, l.rejectBuyerResponseConfirm(buyerName));
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(responseRef, {'responseStatus': 'rejected', 'respondedAt': Timestamp.now()});
        final poRef = svc.poRef.doc(poId);
        tx.update(poRef, {
          'history': FieldValue.arrayUnion([
            {'status': 'response rejected', 'by': user.uid, 'note': 'Rejected buyer: $buyerName', 'ts': Timestamp.now()}
          ]),
        });
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.buyerResponseRejected)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToRejectResponse)));
      }
    }
  }

  Future<void> _acceptPO(BuildContext context, String farmerId) async {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }
    if (user.uid != farmerId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.onlySellerCanPerformAction)));
      return;
    }

    final confirmed =
        await _confirmDialog(context, l.acceptPurchaseOrderTitle, l.acceptPurchaseOrderConfirm);
    if (confirmed != true) return;

    final poRef = svc.poRef.doc(poId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(poRef);
        if (!snapshot.exists) throw Exception('PO not found');
        tx.update(poRef, {
          'status': 'farmer_accepted',
          'acceptedBy': user.uid,
          'acceptedAt': Timestamp.now(),
          'history': FieldValue.arrayUnion([
            {'status': 'farmer_accepted', 'by': user.uid, 'note': 'Farmer accepted the PO', 'ts': Timestamp.now()}
          ]),
        });
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.purchaseOrderAccepted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToAcceptPO)));
      }
    }
  }

  Future<void> _rejectPO(BuildContext context, String farmerId) async {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }
    if (user.uid != farmerId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.onlySellerCanPerformAction)));
      return;
    }

    final confirmed =
        await _confirmDialog(context, l.rejectPurchaseOrderTitle, l.rejectPurchaseOrderConfirm);
    if (confirmed != true) return;

    final poRef = svc.poRef.doc(poId);
    try {
      final responsesSnap = await poRef
          .collection('buyer_responses')
          .where('responseStatus', isEqualTo: 'pending')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      batch.update(poRef, {
        'status': 'rejected',
        'rejectedBy': user.uid,
        'rejectedAt': Timestamp.now(),
        'history': FieldValue.arrayUnion([
          {'status': 'rejected', 'by': user.uid, 'note': 'Farmer rejected the PO', 'ts': Timestamp.now()}
        ]),
      });

      for (final d in responsesSnap.docs) {
        batch.update(d.reference, {'responseStatus': 'rejected', 'respondedAt': Timestamp.now()});
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.purchaseOrderRejectedFull)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToRejectPO)));
      }
    }
  }

  Widget _statusBadge(String rawStatus, {String? displayLabel}) {
    final color = _statusColor(rawStatus);
    return Builder(builder: (ctx) {
      final label = displayLabel ?? _localizedPoStatus(AppLocalizations.of(ctx)!, rawStatus);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(label.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
    });
  }

  String? _extractCropNameFromPOData(Map<String, dynamic> data) {
    try {
      final items = (data['items'] as List?)?.cast<dynamic>() ?? [];
      if (items.isNotEmpty) {
        final first = items.first;
        if (first is Map<String, dynamic>) {
          for (final k in ['productName', 'product_name', 'crop', 'listingTitle', 'title', 'name']) {
            if (first.containsKey(k) && first[k] != null && first[k].toString().trim().isNotEmpty) {
              return first[k].toString().trim();
            }
          }
          if (first.containsKey('listing') && first['listing'] is Map) {
            final listing = first['listing'] as Map<String, dynamic>;
            for (final k in ['productName', 'product_name', 'name', 'title']) {
              if (listing.containsKey(k) && listing[k] != null && listing[k].toString().trim().isNotEmpty) {
                return listing[k].toString().trim();
              }
            }
          }
        }
      }
      for (final k in ['productName', 'product_name', 'crop', 'title']) {
        if (data.containsKey(k) && data[k] != null && data[k].toString().trim().isNotEmpty) {
          return data[k].toString().trim();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final poStream = svc.poRef.doc(poId).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: poStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.orderDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.orderDetails)),
            body: Center(child: Text(AppLocalizations.of(context)!.orderNotFound)),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final history = (data['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final status = (data['status'] ?? 'listed').toString();
        final buyerName = data['buyerName'] ?? '—';
        final buyerContact = data['buyerContact'] ?? data['buyerPhone'] ?? '—';
        final farmerId = (data['farmerId'] ?? '').toString();
        final totalAmount = data['totalAmount'] ?? 0;
        final createdAt = data['createdAt'];
        final currentUser = FirebaseAuth.instance.currentUser;
        final currentUid = currentUser?.uid;

        final inlineName = _extractCropNameFromPOData(data);
        Widget titleWidget;

        if (inlineName != null) {
          titleWidget = Text(inlineName);
        } else if (items.isNotEmpty &&
            (items.first['listingId'] ?? items.first['productId']) != null) {
          final listingId = (items.first['listingId'] ?? items.first['productId']).toString();
          titleWidget = FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('export_products').doc(listingId).get(),
            builder: (context, pSnap) {
              if (pSnap.connectionState == ConnectionState.waiting) return const Text('Loading…');
              if (!pSnap.hasData || !pSnap.data!.exists) {
                return Text('Order ${poId.length >= 6 ? poId.substring(0, 6) : poId}');
              }
              final pd = pSnap.data!.data() as Map<String, dynamic>;
              return Text((pd['productName'] ?? pd['name'] ?? 'Order').toString());
            },
          );
        } else {
          titleWidget = Text('Order ${poId.length >= 6 ? poId.substring(0, 6) : poId}');
        }

        final responsesStream = svc.poRef
            .doc(poId)
            .collection('buyer_responses')
            .orderBy('createdAt', descending: true)
            .snapshots();

        final canActOnPO = currentUid != null && farmerId.isNotEmpty && currentUid == farmerId;
        final isRejected = _rejectionStatuses.contains(_normalizeStatus(status));
        final poFinalized =
            isRejected || ['exported', 'cancelled'].contains(_normalizeStatus(status));

        return Scaffold(
          appBar: AppBar(
            title: titleWidget,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.refreshing))),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.orderIdLabel(poId),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text('${AppLocalizations.of(context)!.statusLabel} ',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            _statusBadge(status),
                          ]),
                          const SizedBox(height: 6),
                          Text(AppLocalizations.of(context)!.createdAtLabel(_formatTimestamp(createdAt)),
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Procurement Timeline ──
                if (!isRejected)
                  _ProcurementTimeline(currentStatus: status),

                if (isRejected)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localizedPoStatus(AppLocalizations.of(context)!, status),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),

                const SizedBox(height: 12),

                // ── Farmer accept / reject actions ──
                if (canActOnPO && !poFinalized)
                  Row(children: [
                    ElevatedButton.icon(
                      onPressed: () => _acceptPO(context, farmerId),
                      icon: const Icon(Icons.thumb_up),
                      label: Text(AppLocalizations.of(context)!.acceptOrderButton),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _rejectPO(context, farmerId),
                      icon: const Icon(Icons.thumb_down),
                      label: Text(AppLocalizations.of(context)!.rejectOrderButton),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  ]),

                if (canActOnPO && poFinalized)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppLocalizations.of(context)!.poFinalizedMessage(
                          _localizedPoStatus(AppLocalizations.of(context)!, status).toUpperCase()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),

                const SizedBox(height: 16),
                const Divider(),

                // ── Buyer & Contact ──
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(buyerName),
                  subtitle: Text(AppLocalizations.of(context)!.buyerContactSubtitle(buyerContact)),
                ),
                const SizedBox(height: 12),

                if (farmerId.isNotEmpty)
                  Builder(builder: (context) {
                    final user = FirebaseAuth.instance.currentUser;
                    final isBuyer = user != null && user.uid != farmerId;
                    if (!isBuyer) return const SizedBox.shrink();
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(farmerId).get(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return ListTile(
                              leading: const Icon(Icons.store, color: Colors.green),
                              title: Text(AppLocalizations.of(context)!.loadingSellerInfo));
                        }
                        if (!snap.hasData || !snap.data!.exists) {
                          return ListTile(
                            leading: const Icon(Icons.store, color: Colors.green),
                            title: Text(AppLocalizations.of(context)!.sellerNotFound),
                            subtitle: Text(AppLocalizations.of(context)!.farmerIdLabel(farmerId)),
                          );
                        }
                        final sd = snap.data!.data() as Map<String, dynamic>;
                        final sellerName = (sd['displayName'] ?? sd['name'] ?? 'Unknown Seller').toString();
                        final sellerContact =
                            (sd['phone'] ?? sd['contact'] ?? 'No contact number').toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.store, color: Colors.green),
                          title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(AppLocalizations.of(context)!.contactColonLabel(sellerContact)),
                        );
                      },
                    );
                  }),

                const Divider(),

                // ── Items list ──
                Text(AppLocalizations.of(context)!.itemsSection,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...items.map<Widget>((it) {
                  final listingId = it['listingId'] ?? it['productId'] ?? '—';
                  final qty = it['qtyKg'] ?? it['qty'] ?? 0;
                  final price = it['pricePerKg'] ?? it['price'] ?? 0;
                  final itemTs = it['createdAt'];

                  return FutureBuilder<DocumentSnapshot?>(
                    future: listingId != '—'
                        ? FirebaseFirestore.instance
                            .collection('export_products')
                            .doc(listingId.toString())
                            .get()
                        : Future<DocumentSnapshot?>.value(null),
                    builder: (context, snapshot) {
                      String productName = 'Loading…';
                      ImageProvider? imgProvider;
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                          final pd = snapshot.data!.data() as Map<String, dynamic>;
                          productName =
                              (pd['productName'] ?? pd['name'] ?? 'Unnamed Product').toString();
                          final imgUrl = pd['imageUrl']?.toString() ?? '';
                          if (imgUrl.isNotEmpty) imgProvider = NetworkImage(imgUrl);
                        } else {
                          productName =
                              (it['productName'] ?? it['name'] ?? 'Product not found').toString();
                        }
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.green.shade100,
                            backgroundImage: imgProvider ??
                                const AssetImage('assets/farmer_logo.png') as ImageProvider,
                            onBackgroundImageError: (_, __) {},
                            child: null,
                          ),
                          title: Text(productName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '$qty kg × ₹$price\n${AppLocalizations.of(context)!.addedAtLabel(_formatTimestamp(itemTs))}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.totalAmountLabel(totalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                const Divider(),

                // ── Buyer responses ──
                Text(AppLocalizations.of(context)!.buyerResponsesSection,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                StreamBuilder<QuerySnapshot>(
                  stream: responsesStream,
                  builder: (context, rsnap) {
                    if (rsnap.hasError) {
                      return Text(AppLocalizations.of(context)!.errorLoadingResponses,
                          style: const TextStyle(color: Colors.red));
                    }
                    if (!rsnap.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = rsnap.data!.docs;
                    if (docs.isEmpty) return Text(AppLocalizations.of(context)!.noBuyerResponsesYet);

                    return Column(
                      children: docs.map((rd) {
                        final r = rd.data() as Map<String, dynamic>;
                        final buyer = (r['buyerName'] ?? r['from'] ?? 'Buyer').toString();
                        final msg = (r['message'] ?? '').toString();
                        final respStatus = (r['responseStatus'] ?? 'pending').toString();
                        final created = r['createdAt'];
                        final respRef = rd.reference;
                        final canAct =
                            currentUid != null && farmerId.isNotEmpty && currentUid == farmerId;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: const Icon(Icons.person_outline, color: Colors.green),
                            title: Row(children: [
                              Expanded(
                                  child: Text(buyer,
                                      style: const TextStyle(fontWeight: FontWeight.w600))),
                              const SizedBox(width: 8),
                              _statusBadge(respStatus),
                            ]),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(msg),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!
                                      .atDateLabel(_formatTimestamp(created)),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                if (canAct && respStatus.toLowerCase() == 'pending')
                                  Row(children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _acceptResponse(context, respRef, r, farmerId),
                                      icon: const Icon(Icons.check),
                                      label: Text(AppLocalizations.of(context)!.accept),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _rejectResponse(context, respRef, r),
                                      icon: const Icon(Icons.close),
                                      label: Text(AppLocalizations.of(context)!.reject),
                                    ),
                                  ]),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ── History ──
                Text(AppLocalizations.of(context)!.historySection,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  Text(AppLocalizations.of(context)!.noHistoryEntries)
                else
                  Column(
                    children: history.reversed.map((h) {
                      final hStatus = (h['status'] ?? '').toString();
                      final hBy = (h['by'] ?? '').toString();
                      final hNote = (h['note'] ?? '').toString();
                      final hTs = h['ts'];
                      final l = AppLocalizations.of(context)!;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _statusColor(hStatus).withValues(alpha: 0.15),
                          child: Icon(Icons.history, color: _statusColor(hStatus), size: 16),
                        ),
                        title: Text(_localizedPoStatus(l, hStatus),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${l.by}: $hBy\n$hNote\n${l.at}: ${_formatTimestamp(hTs)}',
                            style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // ── Contact / Refresh actions ──
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final sellerPhone = data['sellerContact'] ??
                          data['farmerPhone'] ??
                          data['ownerPhone'] ??
                          'Not available';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .contactSellerSnackbar(sellerPhone))));
                    },
                    icon: const Icon(Icons.phone),
                    label: Text(AppLocalizations.of(context)!.contactSellerButton),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.refreshing))),
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.refresh),
                  ),
                ]),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Procurement Timeline Widget ────────────────────────────────────────────────

class _ProcurementTimeline extends StatelessWidget {
  final String currentStatus;
  const _ProcurementTimeline({required this.currentStatus});

  static const List<(String, String)> _steps = [
    ('listed', 'Listed'),
    ('under_review', 'Review'),
    ('po_issued', 'PO Issued'),
    ('farmer_accepted', 'Accepted'),
    ('collection_scheduled', 'Collection'),
    ('collected', 'Collected'),
    ('qc_pending', 'QC'),
    ('qc_approved', 'QC OK'),
    ('ready_for_export', 'Ready'),
    ('exported', 'Exported'),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final normalizedCurrent = _normalizeStatus(currentStatus);
    final currentIdx = _procurementSteps.indexOf(normalizedCurrent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.procurementTimeline,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _steps.length,
            itemBuilder: (context, i) {
              final (stepKey, label) = _steps[i];
              final stepOrderIdx = _procurementSteps.indexOf(stepKey);
              final isDone = currentIdx >= 0 && stepOrderIdx < currentIdx;
              final isCurrent = stepKey == normalizedCurrent ||
                  (stepKey == 'listed' && currentIdx == 0);
              final isFuture = !isDone && !isCurrent;

              final color = isFuture
                  ? Colors.grey.shade300
                  : isCurrent
                      ? _statusColor(stepKey)
                      : Colors.green;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isCurrent ? 28 : 22,
                        height: isCurrent ? 28 : 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFuture ? Colors.transparent : color,
                          border: Border.all(color: color, width: isCurrent ? 2.5 : 1.5),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : isCurrent
                                ? Icon(Icons.circle, size: 10, color: Colors.white.withValues(alpha: 0.9))
                                : null,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 52,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isFuture
                                ? Colors.grey.shade400
                                : isCurrent
                                    ? color
                                    : Colors.green.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (i < _steps.length - 1)
                    SizedBox(
                      width: 20,
                      child: Divider(
                        color: isDone ? Colors.green : Colors.grey.shade300,
                        thickness: 1.5,
                        indent: 0,
                        endIndent: 0,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
