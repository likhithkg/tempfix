// lib/exporter_hub/create_purchase_order_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exporter_model.dart';
import 'exporter_service.dart';
import 'notifications_page.dart';
import 'purchase_order_list_page.dart';
import '../theme.dart';

class CreatePurchaseOrderPage extends StatefulWidget {
  final ExportProduct listingData;
  const CreatePurchaseOrderPage({super.key, required this.listingData});

  @override
  State<CreatePurchaseOrderPage> createState() => _CreatePurchaseOrderPageState();
}

class _CreatePurchaseOrderPageState extends State<CreatePurchaseOrderPage> {
  final _svc = ExporterService();
  final _deliveryCtrl = TextEditingController();
  bool _isSubmitting = false;
  double _quantity = 1.0;

  @override
  void dispose() {
    _deliveryCtrl.dispose();
    super.dispose();
  }

  ExportProduct get p => widget.listingData;

  String get _unit {
    final q = p.quantity.toLowerCase();
    if (q.contains('kg')) return 'kg';
    if (q.contains('piece') || q.contains('pcs')) return 'pieces';
    if (q.contains('tonne') || q.contains('ton')) return 'tonnes';
    if (q.contains('quintal')) return 'quintals';
    if (q.contains('litre') || q.contains('ltr')) return 'litres';
    return 'units';
  }

  double get _pricePerUnit =>
      double.tryParse(p.pricePerUnit.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  double get _total => _quantity * _pricePerUnit;

  void _increment() => setState(() => _quantity += 1);
  void _decrement() {
    if (_quantity > 1) setState(() => _quantity -= 1);
  }

  Future<void> _confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final buyerName = user.displayName ?? user.email ?? 'Buyer';
      final buyerPhone = user.phoneNumber ?? '';

      final docRef = await _svc.createDirectOrder(
        listingId: p.id,
        buyerId: user.uid,
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        quantity: _quantity,
        unit: _unit,
        pricePerUnit: _pricePerUnit,
        totalAmount: _total,
        deliveryAddress: _deliveryCtrl.text.trim().isEmpty ? null : _deliveryCtrl.text.trim(),
        productName: p.productName,
        productImage: p.primaryImage,
      );

      if (p.sellerUid.isNotEmpty) {
        NotificationService.send(
          userId: p.sellerUid,
          type: 'new_order',
          title: 'New Order Received',
          body:
              '${buyerName.isNotEmpty ? buyerName : 'A buyer'} ordered ${_quantity.toStringAsFixed(0)} $_unit of ${p.productName}.',
          referenceId: docRef.id,
          referenceType: 'order',
        ).catchError((_) {});
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Order Placed!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your order for ${p.productName} has been sent to the farmer.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KMColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PurchaseOrderListPage(buyerId: user.uid)),
                  );
                },
                child: const Text('View My Orders'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = p.primaryImage.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF7),
      appBar: AppBar(
        title: const Text('Buy Now'),
        backgroundColor: KMColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Card ──
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: hasImage
                            ? Image.network(p.primaryImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const _ProductFallback())
                            : const _ProductFallback(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.productName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(p.farmerName,
                                style:
                                    const TextStyle(color: Colors.grey, fontSize: 13)),
                          ]),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Price Banner ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KMColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KMColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, color: KMColors.primary, size: 22),
                  Text(
                    '${p.pricePerUnit} / $_unit',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: KMColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text('Available: ${p.quantity}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Quantity Selector ──
            const Text('Quantity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                _QtyButton(icon: Icons.remove, onTap: _decrement),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        _quantity.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _QtyButton(icon: Icons.add, onTap: _increment),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _unit,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Delivery Address ──
            const Text('Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _deliveryCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter delivery address (optional)',
                prefixIcon:
                    const Icon(Icons.location_on_outlined, color: KMColors.primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide:
                        BorderSide(color: KMColors.primary, width: 2)),
              ),
            ),

            const SizedBox(height: 24),

            // ── Order Summary ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: p.productName,
                    value:
                        '₹${_pricePerUnit.toStringAsFixed(0)} × ${_quantity.toStringAsFixed(0)} $_unit',
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Subtotal',
                    value: '₹${_total.toStringAsFixed(0)}',
                    bold: true,
                  ),
                  const _SummaryRow(
                    label: 'Delivery',
                    value: 'To be arranged',
                    valueColor: Colors.grey,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Total',
                    value: '₹${_total.toStringAsFixed(0)}',
                    bold: true,
                    large: true,
                    valueColor: KMColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Confirm Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KMColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _confirmOrder,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Confirm Order',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: KMColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.large = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: large ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 18 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? (bold ? Colors.black87 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback();

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
          child: Icon(Icons.grain, color: Colors.white54, size: 30)),
    );
  }
}
