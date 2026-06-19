// lib/f2b_mart/f2b_product_detail_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../exporter_hub/exporter_model.dart';
import '../exporter_hub/exporter_service.dart';
import '../exporter_hub/create_purchase_order_page.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';

class F2BProductDetailPage extends StatelessWidget {
  final ExportProduct product;
  const F2BProductDetailPage({super.key, required this.product});

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _contact =>
      (product.farmerMobile?.isNotEmpty == true)
          ? product.farmerMobile!
          : product.farmerId;

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
    final accent = _accentFor(product.category);
    final name = ContentTranslationService.translateCropName(
        product.productName, langCode);
    final cat = ContentTranslationService.translateExportCategory(
        product.category, langCode);
    final loc = ContentTranslationService.translateLocation(
        product.location, langCode);

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      body: Stack(
        children: [
          // ── Scrollable body ─────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // Hero image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _heroGradient(accent))
                          : _heroGradient(accent),
                      // Bottom gradient overlay
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
                      // Name + category overlay
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
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(height: 6),
                            Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4)
                                    ])),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price + Quantity stat row
                      Row(children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.currency_rupee_rounded,
                            iconColor: KMColors.primary,
                            label: l.priceLabel,
                            value: '₹${product.pricePerUnit}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: KMColors.accent,
                            label: l.quantityLabel,
                            value: product.quantity,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Farmer info card
                      _SectionCard(
                        title: l.farmerInfo,
                        child: Column(children: [
                          _InfoRow(
                            icon: Icons.person_rounded,
                            iconColor: KMColors.primary,
                            label: l.farmerLabel.replaceAll(':', ''),
                            value: product.farmerName,
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

                      // Product details card
                      _SectionCard(
                        title: l.productDetails,
                        child: Column(children: [
                          _InfoRow(
                            icon: Icons.category_rounded,
                            iconColor: accent,
                            label: l.categoryLabel,
                            value: cat,
                          ),
                          if (product.createdAt != null)
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              iconColor: KMColors.textSecondary,
                              label: l.listedOnLabel,
                              value: _formatDate(product.createdAt!),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // Description card
                      if (product.description.trim().isNotEmpty) ...[
                        _SectionCard(
                          title: l.descriptionLabel,
                          child: Text(product.description,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.65,
                                  color: KMColors.textSecondary)),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Similar products
                      _SimilarSection(
                        category: product.category,
                        excludeId: product.id,
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
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
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
                // Call button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _contact.isNotEmpty ? () => _call(_contact) : null,
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
                // WhatsApp icon button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    tooltip: l.whatsApp,
                    onPressed: _contact.isNotEmpty
                        ? () => _whatsApp(context, _contact)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Buy Now button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreatePurchaseOrderPage(listingData: product),
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
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.agriculture_rounded, size: 100,
          color: Colors.white.withValues(alpha: 0.28)),
    ),
  );
}

// ─── Stat card ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCard({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: KMColors.textPrimary)),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: KMColors.textPrimary)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ─── Info row ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
  });

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: KMColors.textSecondary,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
  const _SimilarSection({
    required this.category, required this.excludeId,
    required this.langCode, required this.l, required this.accent,
  });

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
                p.category.toLowerCase() ==
                    widget.category.toLowerCase() &&
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
                  style: const TextStyle(
                      fontSize: 17,
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
                    onTap: () => Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            F2BProductDetailPage(product: p),
                      ),
                    ),
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
                              child: p.imageUrl != null &&
                                      p.imageUrl!.isNotEmpty
                                  ? Image.network(p.imageUrl!,
                                      fit: BoxFit.cover, width: 130,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder(color))
                                  : _placeholder(color),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(8, 7, 8, 7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ContentTranslationService.translateCropName(
                                      p.productName, widget.langCode),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text('₹${p.pricePerUnit}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: KMColors.primary)),
                                const SizedBox(height: 2),
                                Text(p.farmerName,
                                    style: const TextStyle(
                                        fontSize: 10,
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
    child: Center(
      child: Icon(Icons.agriculture_rounded, size: 32,
          color: color.withValues(alpha: 0.5)),
    ),
  );
}
