import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'green_bazaar_models.dart';
import 'green_bazaar_service.dart';
import 'order_tracking_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final double itemsTotal;
  final double deliveryCharge;
  const CheckoutPage({
    super.key,
    required this.items,
    required this.itemsTotal,
    required this.deliveryCharge,
  });
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _svc = GreenBazaarService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();

  String _payment = 'cod'; // 'cod' or 'online'
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _name.text = user.displayName ?? '';
      _phone.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final addr = DeliveryAddress(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        addressLine: _address.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        pincode: _pin.text.trim(),
      );

      final orderItems = widget.items
          .map((ci) => OrderLineItem(
                vendorId: ci.vendorId,
                plantName: ci.plantName,
                vendorName: ci.vendorName,
                price: ci.price,
                quantity: ci.orderQty,
                imageUrl: ci.imageUrl,
                type: ci.type,
              ))
          .toList();

      final order = PlantOrder(
        id: '',
        userId: user.uid,
        userName: _name.text.trim(),
        items: orderItems,
        itemsTotal: widget.itemsTotal,
        deliveryCharge: widget.deliveryCharge,
        paymentMethod: _payment,
        address: addr,
        status: 'placed',
        createdAt: DateTime.now(),
      );

      final orderId = await _svc.placeOrder(order);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingPage(orderId: orderId),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Order failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grand = widget.itemsTotal + widget.deliveryCharge;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: _placing
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF2E7D32)),
                SizedBox(height: 16),
                Text('Placing your order...',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary card
                    _card([
                      const _SecTitle(icon: Icons.receipt_long_rounded,
                          title: 'Order Summary'),
                      const SizedBox(height: 10),
                      ...widget.items.map((i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Expanded(
                                child: Text(
                                    '${i.plantName} × ${i.orderQty}',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Text(
                                '₹${(i.price * i.orderQty).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                          )),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          Text('₹${grand.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2E7D32))),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Delivery address
                    _card([
                      const _SecTitle(
                          icon: Icons.location_on_rounded,
                          title: 'Delivery Address'),
                      const SizedBox(height: 12),
                      _field(_name, 'Full Name', Icons.person_rounded),
                      _field(_phone, 'Phone Number', Icons.phone_rounded,
                          type: TextInputType.phone),
                      _field(_address, 'House / Street / Village',
                          Icons.home_rounded,
                          maxLines: 2),
                      Row(children: [
                        Expanded(child: _field(_city, 'City', Icons.location_city_rounded)),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_state, 'State', Icons.map_rounded)),
                      ]),
                      _field(_pin, 'Pincode', Icons.pin_drop_rounded,
                          type: TextInputType.number,
                          validator: (v) {
                        if ((v ?? '').length < 6) return 'Enter 6-digit pincode';
                        return null;
                      }),
                    ]),

                    const SizedBox(height: 16),

                    // Payment method
                    _card([
                      const _SecTitle(
                          icon: Icons.payment_rounded,
                          title: 'Payment Method'),
                      const SizedBox(height: 10),
                      _PayOption(
                        icon: Icons.money_rounded,
                        label: 'Cash on Delivery',
                        subtitle: 'Pay when your plants arrive',
                        value: 'cod',
                        selected: _payment,
                        onSelect: (v) => setState(() => _payment = v),
                      ),
                      const SizedBox(height: 8),
                      _PayOption(
                        icon: Icons.phone_android_rounded,
                        label: 'Online Payment',
                        subtitle: 'UPI / Card / Net Banking',
                        value: 'online',
                        selected: _payment,
                        onSelect: (v) => setState(() => _payment = v),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _placing ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            _payment == 'cod'
                ? 'Place Order  ₹${grand.toStringAsFixed(2)}'
                : 'Pay Now  ₹${grand.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}

class _SecTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SecTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ]);
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle, value, selected;
  final ValueChanged<String> onSelect;
  const _PayOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? const Color(0xFF2E7D32) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              color: sel ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF1B1B1B))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E))),
            ]),
          ),
          if (sel)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF2E7D32), size: 20),
        ]),
      ),
    );
  }
}
