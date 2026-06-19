// lib/f2b_mart/f2b_wishlist_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../exporter_hub/exporter_model.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';
import 'f2b_product_detail_page.dart';
import 'f2b_wishlist_service.dart';

class F2BWishlistPage extends StatefulWidget {
  const F2BWishlistPage({super.key});

  @override
  State<F2BWishlistPage> createState() => _F2BWishlistPageState();
}

class _F2BWishlistPageState extends State<F2BWishlistPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late Future<List<ExportProduct>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = _uid;
    if (uid == null) {
      _future = Future.value([]);
    } else {
      _future = WishlistService.fetchSaved(uid);
    }
  }

  Future<void> _removeFromWishlist(
      AppLocalizations l, String productId) async {
    final uid = _uid;
    if (uid == null) return;
    await WishlistService.toggle(uid, productId);
    setState(() => _load());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.removedFromWishlist),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? KMColors.backgroundDark : const Color(0xFFF0F7F0),
      appBar: AppBar(title: Text(l.yourWishlist)),
      body: _uid == null
          ? _buildSignInPrompt(l)
          : FutureBuilder<List<ExportProduct>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: KMColors.primary));
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: KMColors.error),
                      const SizedBox(height: 8),
                      const Text('Could not load wishlist'),
                      TextButton(
                        onPressed: () => setState(() => _load()),
                        child: const Text('Retry'),
                      ),
                    ]),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) return _buildEmpty(l);

                return RefreshIndicator(
                  color: KMColors.primary,
                  onRefresh: () async => setState(() => _load()),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final p = items[i];
                      return _WishlistCard(
                        product: p,
                        langCode: langCode,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => F2BProductDetailPage(product: p),
                          ),
                        ),
                        onRemove: () => _removeFromWishlist(l, p.id),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_border_rounded,
            size: 72, color: KMColors.textSecondary),
        const SizedBox(height: 16),
        Text(l.wishlistEmpty,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: KMColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.explore_rounded),
          label: Text(l.browseProducts),
        ),
      ]),
    );
  }

  Widget _buildSignInPrompt(AppLocalizations l) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.person_outline_rounded,
            size: 64, color: KMColors.textSecondary),
        const SizedBox(height: 12),
        Text(l.loginToSave,
            style: const TextStyle(
                fontSize: 15, color: KMColors.textSecondary)),
      ]),
    );
  }
}

// ─── Wishlist card ─────────────────────────────────────────────────────────

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

class _WishlistCard extends StatelessWidget {
  final ExportProduct product;
  final String langCode;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _WishlistCard({
    required this.product, required this.langCode,
    required this.onTap, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentFor(product.category);
    final name = ContentTranslationService.translateCropName(
        product.productName, langCode);
    final loc = ContentTranslationService.translateLocation(
        product.location, langCode);
    final cat = ContentTranslationService.translateExportCategory(
        product.category, langCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? KMColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: KMShadow.card,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(accent))
                    : _placeholder(accent),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 9,
                                color: accent,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text('₹${product.pricePerUnit}  •  ${product.quantity}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: KMColors.primary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: KMColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text('$loc  •  ${product.farmerName}',
                            style: const TextStyle(
                                fontSize: 11, color: KMColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            // Remove (heart) button
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.red),
              tooltip: 'Remove from wishlist',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color accent) => Container(
    color: accent.withValues(alpha: 0.12),
    child: Center(child: Icon(Icons.agriculture_rounded,
        size: 36, color: accent.withValues(alpha: 0.5))),
  );
}
