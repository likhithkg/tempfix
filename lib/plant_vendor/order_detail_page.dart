import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'green_bazaar_models.dart';

// Messages subcollection: gb_orders/{orderId}/messages/{msgId}
// Fields: senderId, senderName, senderRole ('buyer'|'seller'), message, sentAt

class OrderDetailPage extends StatefulWidget {
  final PlantOrder order;
  const OrderDetailPage({super.key, required this.order});
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _db = FirebaseFirestore.instance;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  // vendorId → phone (fetched on init for buyer contact buttons)
  final Map<String, String> _vendorPhones = {};
  bool _loadingPhones = true;

  // Buyer profile info fetched from users/{uid} (fallback for old orders)
  String? _fetchedBuyerPhone;
  String? _fetchedBuyerEmail;
  bool _loadingBuyerInfo = false;

  late final String _currentUid;
  late final String _viewerRole; // 'buyer' | 'seller'
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _msgStream;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _viewerRole =
        widget.order.userId == _currentUid ? 'buyer' : 'seller';

    _msgStream = _db
        .collection('gb_orders')
        .doc(widget.order.id)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots();

    if (_viewerRole == 'buyer') {
      _fetchVendorPhones();
    } else {
      setState(() => _loadingPhones = false);
      // If saved buyer contact is missing (old order), fetch from user profile
      if (widget.order.buyerPhone == null && widget.order.buyerEmail == null) {
        _fetchBuyerProfile();
      }
    }
  }

  Future<void> _fetchVendorPhones() async {
    final uniqueVendorIds =
        widget.order.items.map((i) => i.vendorId).toSet();
    for (final vid in uniqueVendorIds) {
      try {
        final doc =
            await _db.collection('plant_vendors').doc(vid).get();
        if (doc.exists) {
          final phone =
              (doc.data()?['phone'] as String? ?? '').trim();
          if (phone.isNotEmpty) _vendorPhones[vid] = phone;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loadingPhones = false);
  }

  Future<void> _fetchBuyerProfile() async {
    final buyerUid = widget.order.userId;
    if (buyerUid.isEmpty) return;
    setState(() => _loadingBuyerInfo = true);
    try {
      final doc = await _db.collection('users').doc(buyerUid).get();
      if (doc.exists && mounted) {
        final d = doc.data() as Map<String, dynamic>;
        final phone = (d['phone'] as String? ??
                d['phoneNumber'] as String? ??
                d['mobile'] as String? ?? '').trim();
        final email = (d['email'] as String? ?? '').trim();
        setState(() {
          if (phone.isNotEmpty) _fetchedBuyerPhone = phone;
          if (email.isNotEmpty) _fetchedBuyerEmail = email;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingBuyerInfo = false);
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _sending = true);
    try {
      await _db
          .collection('gb_orders')
          .doc(widget.order.id)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'User',
        'senderRole': _viewerRole,
        'message': text,
        'sentAt': FieldValue.serverTimestamp(),
      });
      _msgCtrl.clear();
      // Scroll to bottom after send
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s) {
      case 'placed':           return const Color(0xFFFFA000);
      case 'confirmed':        return const Color(0xFF1565C0);
      case 'ready':            return const Color(0xFF6A1B9A);
      case 'collected':        return const Color(0xFF2E7D32);
      case 'packed':           return const Color(0xFF00838F);
      case 'out_for_delivery': return const Color(0xFF1565C0);
      case 'delivered':        return const Color(0xFF2E7D32);
      case 'cancelled':        return const Color(0xFFB71C1C);
      default:                 return const Color(0xFF757575);
    }
  }

  String get _shortId => '#${widget.order.id.length > 8 ? widget.order.id.substring(0, 8).toUpperCase() : widget.order.id.toUpperCase()}';

  // ─── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final color = _statusColor(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Order Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(_shortId,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        ]),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderHeaderCard(order: order, color: color),
                  const SizedBox(height: 12),
                  if (order.status != 'cancelled') ...[
                    _section(
                      'Order Progress',
                      _StatusTrackerCard(order: order, color: color),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _section('Items (${order.items.length})', _ItemsCard(order: order)),
                  const SizedBox(height: 12),
                  _section('Price Breakdown', _PriceCard(order: order)),
                  const SizedBox(height: 12),
                  if (!order.isTakeaway && order.address != null) ...[
                    _section('Delivery Address', _AddressCard(address: order.address!)),
                    const SizedBox(height: 12),
                  ],
                  _section(
                    _viewerRole == 'buyer' ? 'Seller Contact' : 'Buyer Info',
                    _ContactCard(
                      order: order,
                      viewerRole: _viewerRole,
                      vendorPhones: _vendorPhones,
                      loadingPhones: _loadingPhones,
                      loadingBuyerInfo: _loadingBuyerInfo,
                      fetchedBuyerPhone: _fetchedBuyerPhone,
                      fetchedBuyerEmail: _fetchedBuyerEmail,
                      onCall: _call,
                      onWhatsApp: _whatsapp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section('Messages', _ChatSection(
                    msgStream: _msgStream,
                    currentUid: _currentUid,
                  )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _MessageInput(
            controller: _msgCtrl,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF424242))),
          const SizedBox(height: 8),
          child,
        ],
      );
}

// ─── Order header card ────────────────────────────────────────────────────────

class _OrderHeaderCard extends StatelessWidget {
  final PlantOrder order;
  final Color color;
  const _OrderHeaderCard({required this.order, required this.color});

  String get _dateStr =>
      DateFormat('d MMM yyyy, h:mm a').format(order.createdAt);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            order.isTakeaway
                ? Icons.store_rounded
                : Icons.local_shipping_outlined,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '#${order.id.length > 12 ? order.id.substring(0, 12).toUpperCase() : order.id.toUpperCase()}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(_dateStr,
                style: const TextStyle(
                    fontSize: 10.5, color: Color(0xFF757575))),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.isTakeaway ? 'Takeaway' : 'Delivery',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  PlantOrder.statusLabel(order.status),
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── Status tracker card ──────────────────────────────────────────────────────

class _StatusTrackerCard extends StatelessWidget {
  final PlantOrder order;
  final Color color;
  const _StatusTrackerCard({required this.order, required this.color});

  static String _label(String s) {
    switch (s) {
      case 'placed':           return 'Placed';
      case 'confirmed':        return 'Confirmed';
      case 'ready':            return 'Ready';
      case 'collected':        return 'Collected';
      case 'packed':           return 'Packed';
      case 'out_for_delivery': return 'On Way';
      case 'delivered':        return 'Delivered';
      default:                 return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = PlantOrder.statusStepsForType(order.orderType);
    final current = steps.indexOf(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final filled = current > i ~/ 2;
            return Expanded(
              child: Container(
                  height: 2,
                  color: filled ? color : const Color(0xFFE0E0E0)),
            );
          }
          final si = i ~/ 2;
          final done = current >= si;
          final active = current == si;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 24 : 18,
              height: active ? 24 : 18,
              decoration: BoxDecoration(
                color: done ? color : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 6)
                      ]
                    : null,
              ),
              child: done
                  ? Icon(
                      active
                          ? Icons.radio_button_checked_rounded
                          : Icons.check_rounded,
                      size: active ? 14 : 12,
                      color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 5),
            Text(
              _label(steps[si]),
              style: TextStyle(
                  fontSize: 8.5,
                  fontWeight:
                      active ? FontWeight.w800 : FontWeight.w500,
                  color: done ? color : const Color(0xFFBDBDBD)),
              textAlign: TextAlign.center,
            ),
          ]);
        }),
      ),
    );
  }
}

// ─── Items card ───────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final PlantOrder order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: order.items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == order.items.length - 1;
          return Column(children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(item.imageUrl!,
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumb())
                    : _thumb(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.plantName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.vendorName,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9E9E9E))),
                      Text('₹${item.price.toStringAsFixed(0)} × ${item.quantity}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9E9E9E))),
                    ]),
              ),
              Text(
                '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32)),
              ),
            ]),
            if (!isLast) const Divider(height: 16),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _thumb() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Center(child: Icon(Icons.eco_rounded, size: 20, color: Color(0xFF2E7D32))),
      );
}

// ─── Price breakdown card ─────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final PlantOrder order;
  const _PriceCard({required this.order});

  String _payLabel(String m) {
    switch (m) {
      case 'cash_on_pickup':   return 'Cash on Pickup';
      case 'cash_on_delivery': return 'Cash on Delivery';
      case 'upi':              return 'UPI';
      default:                 return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        _row('Subtotal', '₹${order.itemsTotal.toStringAsFixed(0)}'),
        const SizedBox(height: 6),
        _row('Delivery',
            order.deliveryCharge > 0
                ? '₹${order.deliveryCharge.toStringAsFixed(0)}'
                : 'Free'),
        const SizedBox(height: 6),
        _row('Payment', _payLabel(order.paymentMethod), isGrey: true),
        const Divider(height: 18),
        Row(children: [
          const Text('Grand Total',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('₹${order.grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20))),
        ]),
      ]),
    );
  }

  Widget _row(String label, String value, {bool isGrey = false}) =>
      Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.5,
                color:
                    isGrey ? const Color(0xFF9E9E9E) : const Color(0xFF424242))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isGrey
                    ? const Color(0xFF757575)
                    : const Color(0xFF212121))),
      ]);
}

// ─── Address card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final DeliveryAddress address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.location_on_rounded,
            size: 18, color: Color(0xFF1B5E20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(address.name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(address.phone,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF757575))),
            const SizedBox(height: 2),
            Text(address.formatted,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF757575))),
          ]),
        ),
      ]),
    );
  }
}

// ─── Contact card ─────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final PlantOrder order;
  final String viewerRole;
  final Map<String, String> vendorPhones;
  final bool loadingPhones;
  final bool loadingBuyerInfo;
  final String? fetchedBuyerPhone;
  final String? fetchedBuyerEmail;
  final Future<void> Function(String) onCall;
  final Future<void> Function(String) onWhatsApp;

  const _ContactCard({
    required this.order,
    required this.viewerRole,
    required this.vendorPhones,
    required this.loadingPhones,
    this.loadingBuyerInfo = false,
    this.fetchedBuyerPhone,
    this.fetchedBuyerEmail,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: viewerRole == 'buyer'
          ? _buyerView()
          : _sellerView(),
    );
  }

  Widget _buyerView() {
    // If order document has seller contact saved (new orders), show that directly
    final savedPhone = order.sellerPhone;
    final savedLocation = order.sellerLocation;

    if (savedPhone != null || savedLocation != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor name from first item
          if (order.items.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.storefront_rounded,
                  size: 15, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Text(order.items.first.vendorName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
          ],
          if (savedPhone != null) ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onCall(savedPhone),
                  icon: const Icon(Icons.call_rounded, size: 15),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onWhatsApp(savedPhone),
                  icon: const Icon(Icons.chat_rounded, size: 15),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
          if (savedLocation != null)
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(savedLocation,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF424242))),
              ),
            ]),
        ],
      );
    }

    // Fallback: fetch phone at runtime (backward compat for old orders)
    if (loadingPhones) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Collect unique (vendorName, phone) pairs
    final seen = <String>{};
    final entries = <MapEntry<String, String>>[];
    for (final item in order.items) {
      final phone = vendorPhones[item.vendorId] ?? '';
      final key = '${item.vendorName}|$phone';
      if (!seen.contains(key)) {
        seen.add(key);
        entries.add(MapEntry(item.vendorName, phone));
      }
    }

    if (entries.isEmpty) {
      return const Text(
        'Seller contact not available',
        style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
      );
    }

    return Column(
      children: entries.map((e) {
        final vendorName = e.key;
        final phone = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.storefront_rounded,
                    size: 15, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text(vendorName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onCall(phone),
                      icon:
                          const Icon(Icons.call_rounded, size: 15),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(
                            color: Color(0xFF2E7D32)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onWhatsApp(phone),
                      icon: const Icon(Icons.chat_rounded,
                          size: 15),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('No phone on file',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sellerView() {
    // Priority: saved in order doc (new orders) → fetched from user profile (old orders)
    final phone = order.buyerPhone ?? fetchedBuyerPhone;
    final location = order.buyerLocation;
    final email = order.buyerEmail ?? fetchedBuyerEmail;

    if (loadingBuyerInfo) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Buyer avatar + name ──────────────────────────────────────────
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Icon(Icons.person_rounded,
                    size: 22, color: Color(0xFF1565C0))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                order.userName.isNotEmpty ? order.userName : 'Buyer',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 12, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} item${order.items.length == 1 ? '' : 's'}'
                  ' • ${order.isTakeaway ? 'Takeaway' : 'Delivery'}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E)),
                ),
              ]),
            ]),
          ),
        ]),

        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),

        // ── Contact details ──────────────────────────────────────────────
        _infoRow(
          icon: Icons.phone_rounded,
          label: 'Phone',
          value: phone ?? '—',
        ),
        const SizedBox(height: 10),
        _infoRow(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: location ?? '—',
        ),
        if (email != null) ...[
          const SizedBox(height: 10),
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
        ],

        // ── Call / WhatsApp buttons (only when phone is known) ────────────
        if (phone != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onCall(phone),
                icon: const Icon(Icons.call_rounded, size: 15),
                label: const Text('Call Buyer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onWhatsApp(phone),
                icon: const Icon(Icons.chat_rounded, size: 15),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9E9E9E))),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: value == '—'
                  ? const Color(0xFFBDBDBD)
                  : const Color(0xFF212121),
            ),
          ),
        ),
      ]);
}

// ─── Chat section ─────────────────────────────────────────────────────────────

class _ChatSection extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> msgStream;
  final String currentUid;
  const _ChatSection(
      {required this.msgStream, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: msgStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 60,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 32, color: Color(0xFF9E9E9E)),
                  SizedBox(height: 8),
                  Text('No messages yet',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E))),
                  SizedBox(height: 4),
                  Text('Send a message to start the conversation',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFBDBDBD))),
                ]),
              ),
            );
          }
          return Column(
            children: docs.map((doc) {
              final d = doc.data();
              final isMe = (d['senderId'] as String? ?? '') == currentUid;
              final sentAt = d['sentAt'] is Timestamp
                  ? (d['sentAt'] as Timestamp).toDate()
                  : null;
              final timeStr = sentAt != null
                  ? DateFormat('h:mm a').format(sentAt)
                  : '';
              final role = d['senderRole'] as String? ?? '';
              final roleLabel = role == 'buyer' ? 'Buyer' : 'Seller';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe) ...[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1565C0)
                            .withValues(alpha: 0.15),
                        child: Text(
                          roleLabel[0],
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1565C0)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4, bottom: 2),
                              child: Text(
                                '${d['senderName'] ?? roleLabel} · $roleLabel',
                                style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF9E9E9E)),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF1B5E20)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    const Radius.circular(14),
                                topRight:
                                    const Radius.circular(14),
                                bottomLeft: isMe
                                    ? const Radius.circular(14)
                                    : const Radius.circular(3),
                                bottomRight: isMe
                                    ? const Radius.circular(3)
                                    : const Radius.circular(14),
                              ),
                            ),
                            child: Text(
                              d['message'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isMe
                                      ? Colors.white
                                      : const Color(0xFF212121)),
                            ),
                          ),
                          if (timeStr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 3, left: 4, right: 4),
                              child: Text(timeStr,
                                  style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFFBDBDBD))),
                            ),
                        ],
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1B5E20)
                            .withValues(alpha: 0.15),
                        child: const Text(
                          'Me',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B5E20)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ─── Message input bar ────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _MessageInput(
      {required this.controller,
      required this.sending,
      required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Type a message…',
              hintStyle: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
            maxLines: 3,
            minLines: 1,
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 8),
        sending
            ? const SizedBox(
                width: 42,
                height: 42,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
      ]),
    );
  }
}
