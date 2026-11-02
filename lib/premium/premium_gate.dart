import 'package:flutter/material.dart';

import '../theme.dart';
import 'premium_constants.dart';
import 'premium_service.dart';
import 'premium_screen.dart';

class PremiumGate extends StatefulWidget {
  final String featureId;
  final Widget child;

  const PremiumGate({super.key, required this.featureId, required this.child});

  @override
  State<PremiumGate> createState() => _PremiumGateState();
}

class _PremiumGateState extends State<PremiumGate> {
  bool _loading = true;
  bool _entitled = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final entitled = await PremiumService.instance.hasEntitlement(widget.featureId);
    if (mounted) setState(() { _loading = false; _entitled = entitled; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_entitled) return widget.child;
    return _PaywallPage(featureId: widget.featureId, onUnlocked: _check);
  }
}

class _PaywallPage extends StatelessWidget {
  final String featureId;
  final VoidCallback onUnlocked;

  const _PaywallPage({required this.featureId, required this.onUnlocked});

  @override
  Widget build(BuildContext context) {
    final name = kFeatureNames[featureId] ?? featureId;
    final desc = kFeatureDescriptions[featureId] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? KMColors.backgroundDark : KMColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: KMColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(name),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KMColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: KMColors.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lock_rounded, size: 52, color: KMColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KMColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'One-time unlock · Permanent access',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Pricing',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black45,
                    letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              _PricingRow(label: '1 Feature', price: '₹99'),
              _PricingRow(label: '2 Features', price: '₹169'),
              _PricingRow(label: '3 Features', price: '₹229', highlight: true),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PremiumScreen(initialFeatureId: featureId),
                    ),
                  );
                  onUnlocked();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KMColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Unlock Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String price;
  final bool highlight;

  const _PricingRow({required this.label, required this.price, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600),
          ),
          Text(
            price,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: KMColors.primary),
          ),
        ],
      ),
    );
  }
}
