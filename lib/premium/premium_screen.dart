import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/razorpay_payment_service.dart';
import 'premium_constants.dart';
import 'premium_service.dart';
import 'payment_result_page.dart';

// ─── page-level colour tokens ────────────────────────────────────────────────
const _cDeep   = Color(0xFF1B5E20); // hero gradient start / CTA button
const _cMid    = Color(0xFF2E7D32); // hero gradient end / text accents
const _cBright = Color(0xFF43A047); // borders, check marks, savings badges
const _cBg     = Color(0xFFF1F8F1); // page scaffold background
const _cLight  = Color(0xFFE8F5E9); // card selected / badge backgrounds

// ─── per-feature icon + accent colours ───────────────────────────────────────
const _kIcons = <String, IconData>{
  kRentHubPremium:    Icons.agriculture_rounded,
  kPlantVendorPremium: Icons.local_florist_rounded,
  kCropDiseasePremium: Icons.biotech_rounded,
};

const _kAccents = <String, Color>{
  kRentHubPremium:    Color(0xFFBF360C), // deep orange
  kPlantVendorPremium: Color(0xFF2E7D32), // green
  kCropDiseasePremium: Color(0xFF1565C0), // blue
};

// ════════════════════════════════════════════════════════════════════════════
// PremiumScreen — only build() and helper widgets are new; all logic unchanged
// ════════════════════════════════════════════════════════════════════════════

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

  // ── unchanged pricing logic ───────────────────────────────────────────────
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

  // ── unchanged Razorpay payment flow ──────────────────────────────────────
  Future<void> _pay() async {
    if (_selected.isEmpty) return;
    setState(() => _paying = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final createResult = await PremiumService.instance.createPayment(
        features: _selected.toList(),
        customerName: user.displayName ?? 'Farmer',
        customerEmail: user.email ?? 'farmer@krishimithra.com',
        customerPhone: user.phoneNumber ?? '9999999999',
      );
      if (!mounted) return;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      appBar: AppBar(
        backgroundColor: _cDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'KrishiMithra Premium',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: _loadingOwned
          ? const Center(child: CircularProgressIndicator(color: _cMid))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    // On web, constrain width and centre; on mobile fill available space.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: kIsWeb ? 580.0 : double.infinity),
        child: Column(
          children: [
            Expanded(child: _buildScroll()),
            _PayBar(
              price: _computedPrice,
              enabled: _selected.isNotEmpty && !_paying,
              loading: _paying,
              onPay: _pay,
              bottomPad: bottomPad,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScroll() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── hero ──
          const _HeroSection(),
          const SizedBox(height: 24),

          // ── feature cards ──
          const _SectionLabel('Choose Your Features'),
          const SizedBox(height: 10),
          ...kAllFeatureIds.map((id) => _FeatureCard(
                id: id,
                owned: _owned.contains(id),
                selected: _selected.contains(id),
                onTap: () => _toggle(id),
              )),

          // ── pricing tier (first-time users only) ──
          if (_ownedCount == 0) ...[
            const SizedBox(height: 22),
            const _SectionLabel('Select a Package'),
            const SizedBox(height: 10),
            _PricingTier(selectedCount: _selected.length),
          ],

          // ── upgrade note (returning users) ──
          if (_ownedCount > 0) ...[
            const SizedBox(height: 20),
            _UpgradeNote(ownedCount: _ownedCount),
          ],

          // ── order summary ──
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionLabel('Order Summary'),
            const SizedBox(height: 10),
            _OrderSummary(
              selected: _selected.toList(),
              ownedCount: _ownedCount,
              price: _computedPrice,
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Hero section — gradient banner with crown icon, title, subtitle, badge
// ════════════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      child: Column(
        children: [
          // frosted-glass crown circle
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28), width: 1.5),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                size: 36, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock KrishiMithra Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get access to powerful tools that help you\nmanage your farming activities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.87),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          // badge pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: Colors.amber),
                SizedBox(width: 5),
                Text(
                  'One-time payment  ·  Lifetime access',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Feature card — icon, name, description, benefit, animated checkbox
// ════════════════════════════════════════════════════════════════════════════

class _FeatureCard extends StatelessWidget {
  final String id;
  final bool owned, selected;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.id,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name    = kFeatureNames[id] ?? id;
    final desc    = kFeatureLongDescriptions[id] ?? kFeatureDescriptions[id] ?? '';
    final benefit = kFeatureBenefits[id] ?? '';
    final icon    = _kIcons[id] ?? Icons.star_rounded;
    final accent  = _kAccents[id] ?? _cBright;
    final active  = selected || owned;

    return GestureDetector(
      onTap: owned ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: active ? _cLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? _cBright : const Color(0xFFE0E0E0),
            width: active ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? _cBright.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: active ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // feature icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              // text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                            height: 1.35)),
                    if (benefit.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.check_circle_rounded,
                                size: 13, color: _cBright),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(benefit,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _cMid,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // owned badge or animated checkbox
              if (owned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _cLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _cBright.withValues(alpha: 0.55)),
                  ),
                  child: const Text('Owned',
                      style: TextStyle(
                          fontSize: 11,
                          color: _cMid,
                          fontWeight: FontWeight.w700)),
                )
              else
                _AnimatedCheckbox(checked: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheckbox extends StatelessWidget {
  final bool checked;
  const _AnimatedCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 210),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? _cBright : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: checked ? _cBright : const Color(0xFFBDBDBD),
          width: 2,
        ),
        boxShadow: checked
            ? [
                BoxShadow(
                    color: _cBright.withValues(alpha: 0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]
            : [],
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Pricing tier — three package cards; auto-highlights based on selection count
// ════════════════════════════════════════════════════════════════════════════

class _PricingTier extends StatelessWidget {
  final int selectedCount;
  const _PricingTier({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PricingCard(
              label: 'Single',
              sub: '1 feature',
              price: '₹99',
              badge: null,
              isSelected: selectedCount == 1,
              isBest: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PricingCard(
              label: 'Duo',
              sub: '2 features',
              price: '₹169',
              badge: 'Save ₹29',
              isSelected: selectedCount == 2,
              isBest: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PricingCard(
              label: 'Bundle',
              sub: '3 features',
              price: '₹229',
              badge: 'Best Value',
              isSelected: selectedCount >= 3,
              isBest: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String label, sub, price;
  final String? badge;
  final bool isSelected, isBest;

  const _PricingCard({
    required this.label,
    required this.sub,
    required this.price,
    required this.badge,
    required this.isSelected,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? _cDeep : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? _cDeep
              : isBest
                  ? _cBright
                  : const Color(0xFFDEDEDE),
          width: isSelected ? 0 : isBest ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _cDeep.withValues(alpha: 0.32)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isSelected ? 14 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // badge or fixed-height spacer so all cards align
          if (badge != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : _cBright.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _cMid,
                ),
              ),
            )
          else
            const SizedBox(height: 23),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF1B1B1B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? Colors.white70
                  : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            price,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : _cDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Upgrade note — shown when the user already owns some features
// ════════════════════════════════════════════════════════════════════════════

class _UpgradeNote extends StatelessWidget {
  final int ownedCount;
  const _UpgradeNote({required this.ownedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBright.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 17, color: _cMid),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You already own $ownedCount premium '
              'feature${ownedCount > 1 ? 's' : ''}. '
              "You'll only pay the upgrade difference.",
              style: const TextStyle(
                  fontSize: 12, color: _cMid, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Order summary card
// ════════════════════════════════════════════════════════════════════════════

class _OrderSummary extends StatelessWidget {
  final List<String> selected;
  final int ownedCount;
  final int price;

  const _OrderSummary({
    required this.selected,
    required this.ownedCount,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    // Bundle savings only make sense for new users (no owned) buying 2+ features.
    final int? bundleSavings = (ownedCount == 0 && selected.length >= 2)
        ? selected.length * 99 - price
        : null;
    // Show individual base price strikethrough only when bundle savings apply.
    final showStrike = bundleSavings != null && bundleSavings > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: _cMid),
              SizedBox(width: 6),
              Text('Order Summary',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // feature rows
          ...selected.map((id) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _cLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _kIcons[id] ?? Icons.star_rounded,
                        size: 16,
                        color: _kAccents[id] ?? _cMid,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        kFeatureNames[id] ?? id,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (showStrike)
                      const Text('₹99',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFBDBDBD),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFFBDBDBD),
                          )),
                  ],
                ),
              )),

          // bundle savings line
          if (bundleSavings != null && bundleSavings > 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_offer_rounded, size: 13, color: _cBright),
                    SizedBox(width: 5),
                    Text('Bundle savings',
                        style: TextStyle(
                            fontSize: 13,
                            color: _cBright,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Text('−₹$bundleSavings',
                    style: const TextStyle(
                        fontSize: 13,
                        color: _cBright,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],

          // upgrade credit line
          if (ownedCount > 0) ...[
            const SizedBox(height: 2),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 13, color: _cBright),
                    SizedBox(width: 5),
                    Text('Upgrade credit',
                        style: TextStyle(
                            fontSize: 13,
                            color: _cBright,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Text('Applied',
                    style: TextStyle(
                        fontSize: 13,
                        color: _cBright,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

          // total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total payable',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Text('₹$price',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _cDeep)),
            ],
          ),
          const SizedBox(height: 10),

          // permanent access pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.all_inclusive_rounded, size: 12, color: _cMid),
                SizedBox(width: 5),
                Text('One-time payment · Permanent access',
                    style: TextStyle(
                        fontSize: 11,
                        color: _cMid,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sticky pay bar — button + trust row
// ════════════════════════════════════════════════════════════════════════════

class _PayBar extends StatelessWidget {
  final int price;
  final bool enabled, loading;
  final VoidCallback onPay;
  final double bottomPad;

  const _PayBar({
    required this.price,
    required this.enabled,
    required this.loading,
    required this.onPay,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CTA button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: enabled ? onPay : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? _cDeep : const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                disabledForegroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: enabled ? 3 : 0,
                shadowColor: _cDeep.withValues(alpha: 0.40),
              ),
              child: loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        ),
                        SizedBox(width: 10),
                        Text('Processing...',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_open_rounded, size: 19),
                        const SizedBox(width: 8),
                        Text(
                          price > 0
                              ? 'Pay ₹$price  ·  Unlock Now'
                              : 'Select features to unlock',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          // trust row
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TrustBadge(icon: Icons.shield_rounded,      label: 'Secured by Razorpay'),
              SizedBox(width: 14),
              _TrustBadge(icon: Icons.all_inclusive_rounded, label: 'Lifetime access'),
              SizedBox(width: 14),
              _TrustBadge(icon: Icons.payments_outlined,   label: 'One-time only'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ── tiny section label ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _cMid,
            letterSpacing: 1.1,
          ),
        ),
      );
}
