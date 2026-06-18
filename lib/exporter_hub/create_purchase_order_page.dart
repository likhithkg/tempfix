import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exporter_model.dart';
import 'exporter_service.dart';
import 'purchase_order_list_page.dart';
import '../l10n/app_localizations.dart';

class CreatePurchaseOrderPage extends StatefulWidget {
  final ExportProduct listingData;
  const CreatePurchaseOrderPage({Key? key, required this.listingData})
      : super(key: key);

  @override
  State<CreatePurchaseOrderPage> createState() =>
      _CreatePurchaseOrderPageState();
}

class _CreatePurchaseOrderPageState extends State<CreatePurchaseOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _buyerNameCtrl = TextEditingController();
  final svc = ExporterService();
  bool _isSubmitting = false;
  double _calculatedTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _prefillBuyer();
    _qtyCtrl.addListener(_updateTotal);
  }

  void _prefillBuyer() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _buyerNameCtrl.text = user.displayName ?? '';
      _contactCtrl.text = user.phoneNumber ?? '';
    }
  }

  void _updateTotal() {
    final qty = _cleanNumber(_qtyCtrl.text);
    final price = _cleanNumber(widget.listingData.pricePerUnit);
    setState(() => _calculatedTotal = qty * price);
  }

  double _cleanNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<void> _submit() async {
    // validate form
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // not signed in — navigate to login
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // parse inputs safely
      final qty = _cleanNumber(_qtyCtrl.text.trim());
      if (qty <= 0) {
        throw Exception('Enter a valid quantity');
      }

      final buyerName = _buyerNameCtrl.text.trim();
      final buyerContact = _contactCtrl.text.trim();
      final price = _cleanNumber(widget.listingData.pricePerUnit);
      if (price <= 0) {
        throw Exception('Invalid listing price');
      }
      final total = qty * price;

      // items: include client-side timestamp (safe inside arrays)
      final items = [
        {
          'listingId': widget.listingData.id,
          'qtyKg': qty,
          'pricePerKg': price,
          'createdAt': Timestamp.now(),
        }
      ];

      // --- IMPORTANT: use createPOForListing so farmerId is resolved automatically ---
      final docRef = await svc.createPOForListing(
        listingId: widget.listingData.id,
        buyerId: user.uid,
        buyerName: buyerName,
        buyerContact: buyerContact,
        items: items,
        totalAmount: total,
        paymentTerms: {'advancePercent': 0},
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // clear the form (optional nicety)
      _qtyCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase order created successfully: ${docRef.id}')),
      );

      // Navigate to the Purchase Order list as buyer
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PurchaseOrderListPage(buyerId: user.uid)),
      );
    } on FirebaseException catch (fe) {
      if (mounted) setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create PO: ${fe.message ?? fe.code}')),
      );
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create PO: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_updateTotal);
    _qtyCtrl.dispose();
    _contactCtrl.dispose();
    _buyerNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.listingData;

    // prepare seller display lines: include mobile if available
    final sellerMobile = product.farmerMobile ?? '';
    final sellerIdOrMobile = sellerMobile.isNotEmpty ? ' • $sellerMobile' : '';
    final sellerLine = 'Seller: ${product.farmerName}$sellerIdOrMobile';

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.purchaseOrderTitle),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    CircleAvatar(
      radius: 35,

      backgroundImage:
          product.imageUrl != null &&
                  product.imageUrl!.isNotEmpty
              ? NetworkImage(product.imageUrl!)
              : const AssetImage(
                      'assets/farmer_logo.png')
                  as ImageProvider,

      onBackgroundImageError: (_, __) {},
    ),

    const SizedBox(width: 14),

    Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            product.productName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          
        ],
      ),
    ),
  ],
),
                const SizedBox(height: 8),
                Text(sellerLine, style: const TextStyle(color: Colors.grey)),
                const Divider(height: 24),

                TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l.quantityLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final parsed = _cleanNumber(val ?? '');
                    if (parsed <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _buyerNameCtrl,
                  decoration: InputDecoration(
                    labelText: l.yourNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _contactCtrl,
                  decoration: InputDecoration(
                    labelText: l.contactNumberLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter contact number' : null,
                ),
                const SizedBox(height: 16),

                Text(
                  'Total: ₹${_calculatedTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                ),
                const SizedBox(height: 24),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(l.placeOrder,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
