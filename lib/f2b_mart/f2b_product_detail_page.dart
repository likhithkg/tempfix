// lib/f2b_mart/f2b_product_detail_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../exporter_hub/exporter_model.dart';
import '../exporter_hub/exporter_service.dart';
import '../exporter_hub/create_purchase_order_page.dart';
import '../exporter_hub/purchase_order_list_page.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';
import 'f2b_wishlist_service.dart';

class F2BProductDetailPage extends StatefulWidget {
  final ExportProduct product;
  const F2BProductDetailPage({super.key, required this.product});

  @override
  State<F2BProductDetailPage> createState() => _F2BProductDetailPageState();
}

class _F2BProductDetailPageState extends State<F2BProductDetailPage> {
  bool _isWishlisted = false;
  StreamSubscription<Set<String>>? _wishlistSub;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_uid != null) {
      _wishlistSub = WishlistService.stream(_uid!).listen((ids) {
        if (mounted) {
          setState(() => _isWishlisted = ids.contains(widget.product.id));
        }
      });
    }
  }

  @override
  void dispose() {
    _wishlistSub?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _contact =>
      (widget.product.farmerMobile?.isNotEmpty == true)
          ? widget.product.farmerMobile!
          : widget.product.farmerId;

  Color _accentFor(String cat) {
    switch (cat.toLowerCase()) {
      case 'fruits':     return const Color(0xFFD84315);
      case 'vegetables': return const Color(0xFF2E7D32);
      case 'grains':     return const Color(0xFFF57F17);
      case 'spices':     return const Color(0xFFAD1457);
      case 'pulses':     return const Color(0xFF6D4C41);
      case 'crops':      return const Color(0xFF1565C0);
      default:           return KMColors.primaryDark;
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/$cleaned');
    if (!await canLaunchUrl(url) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')));
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleWishlist(AppLocalizations l) async {
    if (_uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.loginToSave)));
      return;
    }
    await WishlistService.toggle(_uid!, widget.product.id);
  }

  void _share(AppLocalizations l) {
    final p = widget.product;
    final text =
        '🌾 ${p.productName}\n'
        '💰 ₹${p.pricePerUnit} per unit\n'
        '📦 Available: ${p.quantity}\n'
        '👨‍🌾 Farmer: ${p.farmerName}\n'
        '📍 Location: ${p.location}\n'
        '\nBrowse more on KrishiMithra F2B Mart';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.productInfoCopied),
          duration: const Duration(seconds: 2)),
    );
  }

  void _showMakeOffer(BuildContext context, AppLocalizations l) {
    if (_uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.pleaseSignInToPerformAction)));
      return;
    }

    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser!;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.makeOffer,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                // Current price hint
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: KMColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: KMColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${l.currentPrice}: ₹${widget.product.pricePerUnit}',
                      style: const TextStyle(
                          fontSize: 13, color: KMColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Offer price
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: l.offerPriceLabel,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = double.tryParse(
                        v?.replaceAll(RegExp(r'[^\d.]'), '') ?? '');
                    if (n == null || n <= 0) return l.enterValidOfferPrice;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Quantity
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: l.quantityLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = double.tryParse(
                        v?.replaceAll(RegExp(r'[^\d.]'), '') ?? '');
                    if (n == null || n <= 0) return l.enterQuantity;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => isSubmitting = true);
                            try {
                              final offeredPrice = double.parse(
                                  priceCtrl.text.replaceAll(
                                      RegExp(r'[^\d.]'), ''));
                              final qty = double.parse(
                                  qtyCtrl.text.replaceAll(
                                      RegExp(r'[^\d.]'), ''));
                              final total = offeredPrice * qty;

                              await ExporterService().createPOForListing(
                                listingId: widget.product.id,
                                buyerId: _uid!,
                                buyerName: user.displayName ?? '',
                                buyerContact: user.phoneNumber ?? '',
                                items: [{
                                  'listingId': widget.product.id,
                                  'qtyKg': qty,
                                  'pricePerKg':
                                      double.tryParse(widget.product.pricePerUnit
                                          .replaceAll(RegExp(r'[^\d.]'), '')) ?? 0,
                                  'offeredPricePerKg': offeredPrice,
                                  'createdAt': Timestamp.now(),
                                }],
                                totalAmount: total,
                                paymentTerms: {
                                  'advancePercent': 0,
                                  'isNegotiation': true,
                                  'offeredPricePerUnit': offeredPrice,
                                },
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.offerSubmitted)),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PurchaseOrderListPage(
                                        buyerId: _uid!),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheet(() => isSubmitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed: ${e.toString()}')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(l.submitOffer,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.product;
    final accent = _accentFor(p.category);
    final name = ContentTranslationService.translateCropName(
        p.productName, langCode);
    final cat = ContentTranslationService.translateExportCategory(
        p.category, langCode);
    final loc = ContentTranslationService.translateLocation(p.location, langCode);

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      body: Stack(
        children: [
          // ── Scrollable body ─────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // Hero image with wishlist + share in AppBar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                actions: [
                  // Wishlist heart
                  IconButton(
                    tooltip: l.wishlist,
                    icon: Icon(
                      _isWishlisted
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _isWishlisted ? Colors.red.shade200 : Colors.white,
                    ),
                    onPressed: () => _toggleWishlist(l),
                  ),
                  // Share
                  IconButton(
                    tooltip: l.shareProduct,
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: () => _share(l),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _heroGradient(accent))
                          : _heroGradient(accent),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20, left: 16, right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(cat,
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 6),
                            Text(name,
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 24, fontWeight: FontWeight.w800,
                                    shadows: [Shadow(
                                        color: Colors.black45, blurRadius: 4)])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price + Quantity stats
                      Row(children: [
                        Expanded(child: _StatCard(
                          icon: Icons.currency_rupee_rounded,
                          iconColor: KMColors.primary,
                          label: l.priceLabel,
                          value: '₹${p.pricePerUnit}',
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          icon: Icons.inventory_2_outlined,
                          iconColor: KMColors.accent,
                          label: l.quantityLabel,
                          value: p.quantity,
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // Make Offer button (inline, below stats)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showMakeOffer(context, l),
                          icon: const Icon(Icons.price_change_outlined,
                              size: 18),
                          label: Text(l.makeOffer,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Farmer info
                      _SectionCard(
                        title: l.farmerInfo,
                        child: Column(children: [
                          _InfoRow(
                            icon: Icons.person_rounded,
                            iconColor: KMColors.primary,
                            label: l.farmerLabel.replaceAll(':', ''),
                            value: p.farmerName,
                          ),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            iconColor: KMColors.error,
                            label: l.locationLabel,
                            value: loc,
                          ),
                          if (_contact.isNotEmpty)
                            _InfoRow(
                              icon: Icons.phone_rounded,
                              iconColor: const Color(0xFF1565C0),
                              label: l.mobileLabel.replaceAll(':', ''),
                              value: _contact,
                            ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // Product details
                      _SectionCard(
                        title: l.productDetails,
                        child: Column(children: [
                          _InfoRow(
                            icon: Icons.category_rounded,
                            iconColor: accent,
                            label: l.categoryLabel,
                            value: cat,
                          ),
                          if (p.createdAt != null)
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              iconColor: KMColors.textSecondary,
                              label: l.listedOnLabel,
                              value: _formatDate(p.createdAt!),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      if (p.description.trim().isNotEmpty) ...[
                        _SectionCard(
                          title: l.descriptionLabel,
                          child: Text(p.description,
                              style: const TextStyle(fontSize: 14,
                                  height: 1.65,
                                  color: KMColors.textSecondary)),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Similar products
                      _SimilarSection(
                        category: p.category,
                        excludeId: p.id,
                        langCode: langCode,
                        l: l,
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed bottom action bar ─────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: isDark ? KMColors.surfaceDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, -3)),
                ],
              ),
              child: Row(children: [
                // Call
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _contact.isNotEmpty
                        ? () => _call(_contact)
                        : null,
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: Text(l.contactFarmer,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // WhatsApp
                Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    tooltip: l.whatsApp,
                    onPressed: _contact.isNotEmpty
                        ? () => _whatsApp(context, _contact)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Buy Now
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreatePurchaseOrderPage(
                            listingData: widget.product),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                    label: Text(l.buyNow,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroGradient(Color color) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.55)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Center(child: Icon(Icons.agriculture_rounded, size: 100,
        color: Colors.white.withValues(alpha: 0.28))),
  );
}

// ─── Stat card ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.iconColor,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? KMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KMShadow.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: KMColors.textSecondary)),
        ]),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
                color: KMColors.textPrimary)),
      ]),
    );
  }
}

// ─── Section card ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? KMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KMShadow.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: KMColors.textPrimary)),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

// ─── Info row ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.iconColor,
      required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10,
                    color: KMColors.textSecondary, fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
    );
  }
}

// ─── Similar products section ──────────────────────────────────────────────

class _SimilarSection extends StatefulWidget {
  final String category;
  final String excludeId;
  final String langCode;
  final AppLocalizations l;
  final Color accent;
  const _SimilarSection({required this.category, required this.excludeId,
      required this.langCode, required this.l, required this.accent});

  @override
  State<_SimilarSection> createState() => _SimilarSectionState();
}

class _SimilarSectionState extends State<_SimilarSection> {
  late final Future<List<ExportProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = ExporterService()
        .getExportProducts()
        .first
        .then((all) => all
            .where((p) =>
                p.category.toLowerCase() == widget.category.toLowerCase() &&
                p.id != widget.excludeId)
            .take(8)
            .toList());
  }

  Color _accent(String cat) {
    switch (cat.toLowerCase()) {
      case 'fruits':     return const Color(0xFFD84315);
      case 'vegetables': return const Color(0xFF2E7D32);
      case 'grains':     return const Color(0xFFF57F17);
      case 'spices':     return const Color(0xFFAD1457);
      case 'pulses':     return const Color(0xFF6D4C41);
      case 'crops':      return const Color(0xFF1565C0);
      default:           return KMColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExportProduct>>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final items = snap.data!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(widget.l.similarProducts,
                  style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: KMColors.textPrimary)),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final p = items[i];
                  final color = _accent(p.category);
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(ctx,
                        MaterialPageRoute(builder: (_) =>
                            F2BProductDetailPage(product: p))),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDark ? KMColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: KMShadow.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                            child: SizedBox(
                              height: 90,
                              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                  ? Image.network(p.imageUrl!,
                                      fit: BoxFit.cover, width: 130,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder(color))
                                  : _placeholder(color),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ContentTranslationService.translateCropName(
                                      p.productName, widget.langCode),
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w700),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('₹${p.pricePerUnit}',
                                    style: const TextStyle(fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: KMColors.primary)),
                                const SizedBox(height: 2),
                                Text(p.farmerName,
                                    style: const TextStyle(fontSize: 10,
                                        color: KMColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _placeholder(Color color) => Container(
    width: 130, height: 90,
    color: color.withValues(alpha: 0.12),
    child: Center(child: Icon(Icons.agriculture_rounded, size: 32,
        color: color.withValues(alpha: 0.5))),
  );
}
