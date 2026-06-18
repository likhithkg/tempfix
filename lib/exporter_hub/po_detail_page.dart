// lib/exporter_hub/po_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_service.dart';
import '../l10n/app_localizations.dart';

String _localizedPoStatus(AppLocalizations l, String status) {
  switch (status.toLowerCase()) {
    case 'pending':   return l.statusPending;
    case 'approved':  return l.statusApproved;
    case 'rejected':  return l.statusRejected;
    case 'accepted':  return l.statusAccepted;
    case 'confirmed': return l.statusConfirmed;
    case 'completed': return l.statusCompleted;
    case 'cancelled': return l.statusCancelled;
    case 'issued':    return l.statusIssued;
    case 'open':      return l.statusOpen;
    case 'closed':    return l.statusClosed;
    default:          return status;
  }
}

/// Purchase Order Detail Page
/// Shows a single PO (real-time) and allows actions:
/// - update PO status (confirmed/completed)
/// - accept / reject the entire PO (seller-level)
/// - manage buyer responses (accept/reject per response)
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

  Future<void> _acceptResponse(BuildContext context, DocumentReference responseRef, Map<String, dynamic> respData, String poFarmerId) async {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }

    final buyerName = respData['buyerName'] ?? respData['from'] ?? 'Buyer';
    final confirmed = await _confirmDialog(context, l.acceptResponseTitle, l.acceptBuyerResponseConfirm(buyerName));
    if (confirmed != true) return;

    final poRef = svc.poRef.doc(poId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(responseRef, {
          'responseStatus': 'accepted',
          'respondedAt': Timestamp.now(),
        });

        tx.update(poRef, {
          'status': 'confirmed',
          'history': FieldValue.arrayUnion([
            {
              'status': 'response accepted',
              'by': user.uid,
              'note': 'Accepted buyer: $buyerName',
              'ts': Timestamp.now(),
            }
          ]),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.buyerResponseAccepted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToAcceptResponse)));
      }
    }
  }

  Future<void> _rejectResponse(BuildContext context, DocumentReference responseRef, Map<String, dynamic> respData) async {
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }

    final buyerName = respData['buyerName'] ?? respData['from'] ?? 'Buyer';
    final confirmed = await _confirmDialog(context, l.rejectResponseTitle, l.rejectBuyerResponseConfirm(buyerName));
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(responseRef, {
          'responseStatus': 'rejected',
          'respondedAt': Timestamp.now(),
        });

        final poRef = svc.poRef.doc(poId);
        tx.update(poRef, {
          'history': FieldValue.arrayUnion([
            {
              'status': 'response rejected',
              'by': user.uid,
              'note': 'Rejected buyer: $buyerName',
              'ts': Timestamp.now(),
            }
          ]),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.buyerResponseRejected)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToRejectResponse)));
      }
    }
  }

  // --- New: PO-level accept (seller accepts the entire purchase order) ---
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

    final confirmed = await _confirmDialog(context, l.acceptPurchaseOrderTitle, l.acceptPurchaseOrderConfirm);
    if (confirmed != true) return;

    final poRef = svc.poRef.doc(poId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(poRef);
        if (!snapshot.exists) throw Exception('PO not found');

        tx.update(poRef, {
          'status': 'accepted',
          'acceptedBy': user.uid,
          'acceptedAt': Timestamp.now(),
          'history': FieldValue.arrayUnion([
            {
              'status': 'order accepted',
              'by': user.uid,
              'note': 'Seller accepted the PO',
              'ts': Timestamp.now(),
            }
          ]),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.purchaseOrderAccepted)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToAcceptPO)));
      }
    }
  }

  // --- New: PO-level reject (seller rejects the entire purchase order) ---
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

    final confirmed = await _confirmDialog(context, l.rejectPurchaseOrderTitle, l.rejectPurchaseOrderConfirm);
    if (confirmed != true) return;

    final poRef = svc.poRef.doc(poId);

    try {
      final responsesSnap = await poRef.collection('buyer_responses').where('responseStatus', isEqualTo: 'pending').get();

      final batch = FirebaseFirestore.instance.batch();

      batch.update(poRef, {
        'status': 'rejected',
        'rejectedBy': user.uid,
        'rejectedAt': Timestamp.now(),
        'history': FieldValue.arrayUnion([
          {
            'status': 'order rejected',
            'by': user.uid,
            'note': 'Seller rejected the PO',
            'ts': Timestamp.now(),
          }
        ]),
      });

      for (final d in responsesSnap.docs) {
        batch.update(d.reference, {
          'responseStatus': 'rejected',
          'respondedAt': Timestamp.now(),
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.purchaseOrderRejectedFull)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToRejectPO)));
      }
    }
  }

  Widget _statusBadge(String rawStatus, {String? displayLabel}) {
    Color color;
    switch (rawStatus.toLowerCase()) {
      case 'completed':
      case 'accepted':
      case 'accepted_by_buyer':
        color = Colors.green;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Builder(builder: (ctx) {
      final label = displayLabel ?? _localizedPoStatus(AppLocalizations.of(ctx)!, rawStatus);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
    });
  }

  // helper: try to extract product/crop name from PO data (items first)
  String? _extractCropNameFromPOData(Map<String, dynamic> data) {
    try {
      final items = (data['items'] as List?)?.cast<dynamic>() ?? [];
      if (items.isNotEmpty) {
        final first = items.first;
        if (first is Map<String, dynamic>) {
          final direct = ['productName', 'product_name', 'crop', 'listingTitle', 'title', 'name'];
          for (final k in direct) {
            if (first.containsKey(k) && first[k] != null && first[k].toString().trim().isNotEmpty) {
              return first[k].toString().trim();
            }
          }
          // sometimes quantity object contains nested listing info
          if (first.containsKey('listing') && first['listing'] is Map) {
            final listing = first['listing'] as Map<String, dynamic>;
            for (final k in ['productName', 'product_name', 'name', 'title']) {
              if (listing.containsKey(k) && listing[k] != null && listing[k].toString().trim().isNotEmpty) return listing[k].toString().trim();
            }
          }
        }
      }

      // also try top-level fields
      for (final k in ['productName', 'product_name', 'crop', 'title']) {
        if (data.containsKey(k) && data[k] != null && data[k].toString().trim().isNotEmpty) return data[k].toString().trim();
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
        // Loading UI while waiting
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.orderDetails),
              backgroundColor: Colors.green,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.orderDetails),
              backgroundColor: Colors.green,
            ),
            body: Center(child: Text(AppLocalizations.of(context)!.orderNotFound)),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final history = (data['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final status = (data['status'] ?? 'unknown').toString();
        final buyerName = data['buyerName'] ?? '—';
        final buyerContact = data['buyerContact'] ?? data['buyerPhone'] ?? '—';
        final farmerId = (data['farmerId'] ?? '').toString();
        final totalAmount = data['totalAmount'] ?? 0;
        final createdAt = data['createdAt'];

        final currentUser = FirebaseAuth.instance.currentUser;
        final currentUid = currentUser?.uid;

        // Determine app bar title (prefer product name from items; if first item has listingId, fetch product doc)
        final inlineName = _extractCropNameFromPOData(data);
        Widget titleWidget;

        if (inlineName != null) {
          titleWidget = Text(inlineName);
        } else if (items.isNotEmpty && (items.first['listingId'] ?? items.first['productId']) != null) {
          final listingId = (items.first['listingId'] ?? items.first['productId']).toString();
          titleWidget = FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('export_products').doc(listingId).get(),
            builder: (context, pSnap) {
              if (pSnap.connectionState == ConnectionState.waiting) {
                return const Text('Loading product...');
              }
              if (!pSnap.hasData || !pSnap.data!.exists) {
                return Text('Order ${poId.length >= 6 ? poId.substring(0, 6) : poId}');
              }
              final productData = pSnap.data!.data() as Map<String, dynamic>;
              final pname = productData['productName'] ?? productData['name'] ?? productData['title'] ?? 'Unnamed Product';
              return Text(pname.toString());
            },
          );
        } else {
          titleWidget = Text('Order ${poId.length >= 6 ? poId.substring(0, 6) : poId}');
        }

        // buyer_responses stream (all responses for this PO)
        final responsesStream = svc.poRef.doc(poId).collection('buyer_responses').orderBy('createdAt', descending: true).snapshots();

        final canActOnPO = currentUid != null && farmerId.isNotEmpty && currentUid == farmerId;
        final poFinalized = ['accepted', 'rejected', 'completed'].contains(status.toLowerCase());

        return Scaffold(
          appBar: AppBar(
            title: titleWidget,
            backgroundColor: Colors.green,
            // keep refresh action
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // simply re-build since Stream is live; show quick feedback
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.refreshing)));
                },
              )
            ],
          ),
          body: SingleChildScrollView(
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
                          // we still show order id below the product name area (not in title)
                          Text(AppLocalizations.of(context)!.orderIdLabel(poId), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text('${AppLocalizations.of(context)!.statusLabel} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                            _statusBadge(status),
                          ]),
                          const SizedBox(height: 6),
                          Text(AppLocalizations.of(context)!.createdAtLabel(_formatTimestamp(createdAt)), style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),

                const SizedBox(height: 12),

                if (canActOnPO && !poFinalized)
                  Row(
                    children: [
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
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ],
                  ),

                if (canActOnPO && poFinalized)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(AppLocalizations.of(context)!.poFinalizedMessage(_localizedPoStatus(AppLocalizations.of(context)!, status).toUpperCase()), style: const TextStyle(color: Colors.grey)),
                  ),

                const SizedBox(height: 16),
                const Divider(),

                // Buyer & Contact
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: Text(buyerName),
                  subtitle: Text(AppLocalizations.of(context)!.buyerContactSubtitle(buyerContact)),
                ),
                const SizedBox(height: 12),

                if (farmerId != '—' && farmerId.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final user = FirebaseAuth.instance.currentUser;
                      final isBuyer = user != null && user.uid != farmerId;

                      if (isBuyer) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(farmerId).get(),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return ListTile(
                                leading: const Icon(Icons.store, color: Colors.green),
                                title: Text(AppLocalizations.of(context)!.loadingSellerInfo),
                              );
                            }
                            if (!snap.hasData || !snap.data!.exists) {
                              return ListTile(
                                leading: const Icon(Icons.store, color: Colors.green),
                                title: Text(AppLocalizations.of(context)!.sellerNotFound),
                                subtitle: Text(AppLocalizations.of(context)!.farmerIdLabel(farmerId)),
                              );
                            }

                            final sellerData = snap.data!.data() as Map<String, dynamic>;
                            final sellerName = sellerData['displayName'] ?? sellerData['name'] ?? 'Unknown Seller';
                            final sellerContact = sellerData['phone'] ?? sellerData['contact'] ?? 'No contact number';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.store, color: Colors.green),
                              title: Text(sellerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(AppLocalizations.of(context)!.contactColonLabel(sellerContact)),
                            );
                          },
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),

                const Divider(),

                // Items list
                Text(AppLocalizations.of(context)!.itemsSection, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...items.map<Widget>((it) {
                  final listingId = it['listingId'] ?? it['productId'] ?? '—';
                  final qty = it['qtyKg'] ?? it['qty'] ?? 0;
                  final price = it['pricePerKg'] ?? it['price'] ?? 0;
                  final itemTs = it['createdAt'];

                  return FutureBuilder<DocumentSnapshot?>(
                    future: (listingId != '—') ? FirebaseFirestore.instance.collection('export_products').doc(listingId.toString()).get() : Future<DocumentSnapshot?>.value(null),
                    builder: (context, snapshot) {
                      String productName = 'Loading...';
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                          final productData = snapshot.data!.data() as Map<String, dynamic>;
                          productName = productData['productName'] ?? productData['name'] ?? 'Unnamed Product';
                        } else {
                          // fallback to inline item name if present
                          productName = it['productName'] ?? it['name'] ?? 'Product not found';
                        }
                      }

                      return Card(
  margin: const EdgeInsets.symmetric(vertical: 6),
  child: ListTile(
    leading: CircleAvatar(
      radius: 28,

      backgroundColor: Colors.green.shade100,

      backgroundImage:
          snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.exists
              ? (() {
                  final productData =
                      snapshot.data!.data()
                          as Map<String, dynamic>;

                  final img =
                      productData['imageUrl'];

                  if (img != null &&
                      img
                          .toString()
                          .isNotEmpty) {
                    return NetworkImage(
                      img.toString(),
                    );
                  }

                  return const AssetImage(
                          'assets/farmer_logo.png')
                      as ImageProvider;
                })()
              : const AssetImage(
                      'assets/farmer_logo.png')
                  as ImageProvider,

      onBackgroundImageError:
          (_, __) {},

      child: null,
    ),

    title: Text(
      productName,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),

    subtitle: Text(
      '$qty kg × ₹$price\n${AppLocalizations.of(context)!.addedAtLabel(_formatTimestamp(itemTs))}',
    ),

    isThreeLine: true,
  ),
);
                    },
                  );
                }),

                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.totalAmountLabel(totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                const Divider(),

                // Buyer responses
                Text(AppLocalizations.of(context)!.buyerResponsesSection, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                StreamBuilder<QuerySnapshot>(
                  stream: responsesStream,
                  builder: (context, rsnap) {
                    if (rsnap.hasError) {
                      return Text(AppLocalizations.of(context)!.errorLoadingResponses, style: const TextStyle(color: Colors.red));
                    }
                    if (!rsnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = rsnap.data!.docs;
                    if (docs.isEmpty) {
                      return Text(AppLocalizations.of(context)!.noBuyerResponsesYet);
                    }

                    return Column(
                      children: docs.map((rd) {
                        final r = rd.data() as Map<String, dynamic>;
                        final buyer = r['buyerName'] ?? r['from'] ?? 'Buyer';
                        final msg = r['message'] ?? '';
                        final respStatus = (r['responseStatus'] ?? 'pending').toString();
                        final created = r['createdAt'];
                        final respRef = rd.reference;

                        final canAct = currentUid != null && farmerId.isNotEmpty && currentUid == farmerId;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: const Icon(Icons.person_outline, color: Colors.green),
                            title: Row(
                              children: [
                                Expanded(child: Text(buyer, style: const TextStyle(fontWeight: FontWeight.w600))),
                                const SizedBox(width: 8),
                                _statusBadge(respStatus),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(msg),
                                const SizedBox(height: 8),
                                Text(AppLocalizations.of(context)!.atDateLabel(_formatTimestamp(created)), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                if (canAct && respStatus.toLowerCase() == 'pending')
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _acceptResponse(context, respRef, r, farmerId.toString()),
                                        icon: const Icon(Icons.check),
                                        label: Text(AppLocalizations.of(context)!.accept),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _rejectResponse(context, respRef, r),
                                        icon: const Icon(Icons.close),
                                        label: Text(AppLocalizations.of(context)!.reject),
                                      ),
                                    ],
                                  ),
                                if (!canAct && respStatus.toLowerCase() == 'pending') const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 18),

                Text(AppLocalizations.of(context)!.historySection, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  Text(AppLocalizations.of(context)!.noHistoryEntries)
                else
                  Column(
                    children: history.reversed.map((h) {
                      final hStatus = h['status'] ?? '';
                      final hBy = h['by'] ?? '';
                      final hNote = h['note'] ?? '';
                      final hTs = h['ts'];
                      final l = AppLocalizations.of(context)!;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history, color: Colors.green),
                        title: Text(hStatus),
                        subtitle: Text('${l.by}: $hBy\n$hNote\n${l.at}: ${_formatTimestamp(hTs)}'),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final sellerPhone = data['sellerContact'] ?? data['farmerPhone'] ?? data['ownerPhone'] ?? 'Not available';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.contactSellerSnackbar(sellerPhone))));
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(AppLocalizations.of(context)!.contactSellerButton),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.refreshing)));
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.refresh),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
