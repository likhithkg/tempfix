import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme.dart';
import '../services/razorpay_payment_service.dart';
import 'premium_constants.dart';
import 'premium_service.dart';
import 'payment_result_page.dart';

class PremiumScreen extends StatefulWidget {
  final String? initialFeatureId;

  const PremiumScreen({super.key, this.initialFeatureId});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final Set<String> _selected = {};
  List<String> _owned = [];
  bool _loadingOwned = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFeatureId != null) _selected.add(widget.initialFeatureId!);
    _loadOwned();
  }

  Future<void> _loadOwned() async {
    final entitlements = await PremiumService.instance.getEntitlements();
    if (mounted) {
      setState(() {
        _owned = entitlements.map((e) => e.featureId).toList();
        _selected.removeWhere(_owned.contains);
        _loadingOwned = false;
      });
    }
  }

  int get _ownedCount => _owned.length;

  int get _computedPrice {
    if (_selected.isEmpty) return 0;
    final newTotal = (_ownedCount + _selected.length).clamp(0, 3);
    final credit = kPremiumPrices[_ownedCount.clamp(0, 3)] ?? 0;
    return ((kPremiumPrices[newTotal] ?? 0) - credit).clamp(0, 999);
  }

  void _toggle(String id) {
    if (_owned.contains(id)) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _pay() async {
    if (_selected.isEmpty) return;
    setState(() => _paying = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // 1. Create Razorpay order on backend
      final createResult = await PremiumService.instance.createPayment(
        features: _selected.toList(),
        customerName: user.displayName ?? 'Farmer',
        customerEmail: user.email ?? 'farmer@krishimithra.com',
        customerPhone: user.phoneNumber ?? '9999999999',
      );

      if (!mounted) return;

      // 2. Open Razorpay Checkout (Android native SDK or Web JS interop)
      final payResult = await RazorpayPaymentService.instance.startPayment(
        razorpayOrderId: createResult.razorpayOrderId,
        keyId: createResult.keyId,
        amountPaise: createResult.amountPaise,
        description: createResult.description,
        prefillName: createResult.prefillName,
        prefillEmail: createResult.prefillEmail,
        prefillContact: createResult.prefillContact,
      );

      if (!mounted) return;

      if (payResult.isSuccess) {
        // 3. Verify Razorpay signature on backend and grant entitlements
        final verifyResult = await PremiumService.instance.verifyAndActivate(
          razorpayOrderId: payResult.razorpayOrderId ?? createResult.razorpayOrderId,
          razorpayPaymentId: payResult.razorpayPaymentId ?? '',
          razorpaySignature: payResult.razorpaySignature ?? '',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentResultPage(
              txnid: createResult.txnid,
              initialStatus: verifyResult.success ? 'success' : 'failure',
            ),
          ),
        );
      } else if (payResult.isCancelled) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentResultPage(
              txnid: createResult.txnid,
              initialStatus: 'cancelled',
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentResultPage(
              txnid: createResult.txnid,
              initialStatus: 'failure',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? KMColors.backgroundDark : KMColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: KMColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Unlock Premium',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: _loadingOwned
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Select features to unlock',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...kAllFeatureIds.map(
                          (id) => _FeatureCard(
                            id: id,
                            owned: _owned.contains(id),
                            selected: _selected.contains(id),
                            onTap: () => _toggle(id),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _PriceSummary(
                          ownedCount: _ownedCount,
                          selectedCount: _selected.length,
                          price: _computedPrice,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  _BottomBar(
                    price: _computedPrice,
                    enabled: _selected.isNotEmpty && !_paying,
                    loading: _paying,
                    onPay: _pay,
                  ),
                ],
              ),
            ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String id;
  final bool owned, selected, isDark;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.id,
    required this.owned,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = kFeatureNames[id] ?? id;
    final desc = kFeatureDescriptions[id] ?? '';
    final active = selected || owned;

    return GestureDetector(
      onTap: owned ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: owned
              ? Colors.green.withValues(alpha: 0.08)
              : active
                  ? KMColors.primary.withValues(alpha: 0.1)
                  : isDark
                      ? KMColors.cardDark
                      : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: owned
                ? Colors.green.withValues(alpha: 0.5)
                : active
                    ? KMColors.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: owned
                    ? Colors.green.withValues(alpha: 0.15)
                    : KMColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                owned ? Icons.check_rounded : Icons.star_rounded,
                color: owned ? Colors.green : KMColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45)),
                ],
              ),
            ),
            if (owned)
              const Text('Owned',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w700))
            else
              Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                activeColor: KMColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final int ownedCount, selectedCount, price;
  final bool isDark;

  const _PriceSummary({
    required this.ownedCount,
    required this.selectedCount,
    required this.price,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    final newTotal = (ownedCount + selectedCount).clamp(0, 3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KMColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KMColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 10),
          _Row('Features selected', '$selectedCount feature${selectedCount > 1 ? 's' : ''}'),
          if (ownedCount > 0) _Row('Already owned', '$ownedCount feature${ownedCount > 1 ? 's' : ''}'),
          _Row('New total', '$newTotal / 3 features'),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total to pay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Text('₹$price',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: KMColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('One-time payment · Permanent access',
              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _BottomBar extends StatelessWidget {
  final int price;
  final bool enabled, loading;
  final VoidCallback onPay;

  const _BottomBar({
    required this.price,
    required this.enabled,
    required this.loading,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
    color: Theme.of(context).scaffoldBackgroundColor,
    child: ElevatedButton(
      onPressed: enabled ? onPay : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: KMColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Text(
              price > 0 ? 'Pay Now  ₹$price' : 'Select features to unlock',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800),
            ),
    ),
  );
}
