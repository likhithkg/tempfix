// lib/plant_vendor/plant_list_page.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:krishimithra/plant_vendor/plant_vendor_model.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_service.dart';
import 'package:krishimithra/plant_vendor/plant_list_form_page.dart';
import 'package:krishimithra/plant_vendor/plant_vendor_nearby_page.dart';
import 'package:krishimithra/plant_vendor/plant_detail_page.dart';

import '../services/content_translation_service.dart';
import '../theme.dart';
import '../widgets/km_widgets.dart';
import '../widgets/km_listing_card.dart';
import '../widgets/km_status_chip.dart';
import '../l10n/app_localizations.dart';

/// Shows plant vendor listings filtered by category.
/// category: "Seeds" or "Plant". If null -> defaults to "Plant".
class PlantVendorListPage extends StatefulWidget {
  final String category;

  const PlantVendorListPage({
    super.key,
    this.category = 'Plant',
  });

  @override
  State<PlantVendorListPage> createState() => _PlantVendorListPageState();
}

class _PlantVendorListPageState extends State<PlantVendorListPage> {
  final PlantVendorService _service = PlantVendorService();

  List<PlantVendor> _vendors = [];
  List<PlantVendor> _filtered = [];
  bool _loading = true;

  String _search = '';
  String _sort = 'Newest';
  String _filterCategory = '';

  final _searchCtrl = TextEditingController();

  StreamSubscription<List<PlantVendor>>? _streamSub;

  @override
  void initState() {
    super.initState();
    _filterCategory = widget.category;
    _load();
    _streamSub = _service.streamVendors().listen(
      (list) {
        _vendors = list;
        _applyFilters();
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Realtime load error: $e'),
              backgroundColor: KMColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final vendors = await _service.getPlantVendors();
      _vendors = vendors;
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vendors: $e'),
            backgroundColor: KMColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final cat = _filterCategory.trim().toLowerCase();
    final search = _search.trim().toLowerCase();

    _filtered = _vendors.where((v) {
      final rawType = v.type.toString();
      final derivedCategory = rawType.contains(' - ')
          ? rawType.split(' - ').first.toLowerCase()
          : 'plant';

      final catMatches = (cat == 'all') ? true : (derivedCategory == cat);

      final typeText = rawType.contains(' - ')
          ? rawType.split(' - ').sublist(1).join(' - ')
          : rawType;

      final haystack =
          '${v.plantName} $typeText ${v.vendorName} ${v.location}'
              .toLowerCase();
      final searchMatches =
          search.isEmpty ? true : haystack.contains(search);

      return catMatches && searchMatches;
    }).toList();

    switch (_sort) {
      case 'Newest':
        _filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      case 'Oldest':
        _filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      case 'Price: Low':
        _filtered.sort((a, b) => a.price.compareTo(b.price));
      case 'Price: High':
        _filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    if (mounted) setState(() {});
  }

  String _categoryLabel(PlantVendor v) {
    final raw = v.type.toString();
    return raw.contains(' - ') ? raw.split(' - ').first : 'Plant';
  }

  String _typeLabel(PlantVendor v) {
    final raw = v.type.toString();
    return raw.contains(' - ')
        ? raw.split(' - ').sublist(1).join(' - ')
        : raw;
  }

  void _showActions(PlantVendor v) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l.edit),
              onTap: () {
                Navigator.pop(context);
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantListFormPage(existingVendor: v),
                  ),
                ).then((changed) {
                  if (changed == true) _load();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: KMColors.error),
              title: Text(l.delete, style: const TextStyle(color: KMColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(l.deleteListingQ),
                    content: Text(l.permanentlyDeleteListing),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _service.deletePlantVendor(v.id);
                  _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(PlantVendor v) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final owner =
        v.createdBy.isNotEmpty ? v.createdBy : v.ownerId;
    final isOwner = owner.isNotEmpty && owner == uid;

    final safePlantName =
        v.plantName.isNotEmpty ? v.plantName : l.unknownPlant;
    final typeLabel = _typeLabel(v);
    final translatedType = ContentTranslationService.translatePlantCategory(typeLabel, langCode);
    final category = _categoryLabel(v);
    final translatedLocation = v.location.isNotEmpty
        ? ContentTranslationService.translateLocation(v.location, langCode)
        : '';

    final categoryColor = category.toLowerCase() == 'seeds'
        ? KMColors.warning
        : KMColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: KMSpacing.md),
      child: KMListingCard(
        imageUrl: v.imageUrl,
        fallbackIcon: Icons.local_florist,
        imageHeight: 150,
        title: safePlantName,
        subtitle: '${l.priceLabel}: ₹${v.price.toStringAsFixed(2)} • ${l.qtyLabel} ${v.quantity}',
        caption: translatedLocation.isNotEmpty ? '${l.locationLabel}: $translatedLocation' : null,
        statusBadge: KMStatusChip(label: category, color: categoryColor),
        menuButton: isOwner
            ? IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showActions(v),
              )
            : null,
        infoRow: Text(
          '$translatedType • ${v.vendorName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlantDetailPage(vendor: v)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = widget.category.toLowerCase() == 'seeds'
        ? l.seeds
        : l.plantVendors;

    // Sort dropdown items
    final sortItems = [
      DropdownMenuItem(value: 'Newest', child: Text(l.newest)),
      DropdownMenuItem(value: 'Oldest', child: Text(l.oldest)),
      DropdownMenuItem(value: 'Price: Low', child: Text(l.priceLow)),
      DropdownMenuItem(value: 'Price: High', child: Text(l.priceHigh)),
    ];

    // Category filter keys/labels
    final catEntries = [
      MapEntry('all', l.allCategories),
      MapEntry('plant', l.plant),
      MapEntry('seeds', l.seeds),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PlantVendorNearbyPage()),
              );
              _load();
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PlantListFormPage()),
          );
          if (added == true) _load();
        },
        icon: const Icon(Icons.add),
        label: Text(l.add),
      ),

      body: Column(
        children: [
          // ── Search + Sort ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KMSpacing.lg,
              KMSpacing.md,
              KMSpacing.lg,
              KMSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: KMSearchBar(
                    controller: _searchCtrl,
                    hintText: l.searchPlantVendor,
                    onChanged: (s) {
                      _search = s;
                      _applyFilters();
                    },
                    onClear: () {
                      _search = '';
                      _searchCtrl.clear();
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: KMSpacing.sm),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sort,
                    items: sortItems,
                    onChanged: (v) {
                      if (v == null) return;
                      _sort = v;
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Category chips ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KMSpacing.lg,
              vertical: KMSpacing.xs,
            ),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: catEntries.map((entry) {
                  final isSelected =
                      _filterCategory.toLowerCase() == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: KMSpacing.sm),
                    child: KMCategoryChip(
                      label: entry.value,
                      selected: isSelected,
                      onSelected: (_) {
                        _filterCategory =
                            entry.key[0].toUpperCase() + entry.key.substring(1);
                        _applyFilters();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? KMEmptyState(
                        message: l.noListingsFound,
                        icon: Icons.local_florist_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          KMSpacing.md,
                          KMSpacing.xs,
                          KMSpacing.md,
                          KMSpacing.xl + 64,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlantVendorDetailsPage — read-only detail view (unchanged functionality)
// ─────────────────────────────────────────────────────────────────────────────

class PlantVendorDetailsPage extends StatelessWidget {
  final PlantVendor vendor;

  const PlantVendorDetailsPage({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    final safeType = vendor.type.isNotEmpty ? vendor.type : 'Plant';
    final category =
        safeType.contains(' - ') ? safeType.split(' - ').first : 'Plant';
    final typeLabel = safeType.contains(' - ')
        ? safeType.split(' - ').sublist(1).join(' - ')
        : safeType;

    final translatedCategory = ContentTranslationService.translatePlantCategory(category, langCode);
    final translatedTypeLabel = ContentTranslationService.translatePlantCategory(typeLabel, langCode);

    final safePlantName =
        vendor.plantName.isNotEmpty ? vendor.plantName : l.unknownPlant;
    final safeVendorName =
        vendor.vendorName.isNotEmpty ? vendor.vendorName : l.unknownVendor;
    final safeLocation = vendor.location.isNotEmpty
        ? ContentTranslationService.translateLocation(vendor.location, langCode)
        : l.notProvided;
    final safeDescription =
        vendor.description.isNotEmpty ? vendor.description : l.noDescriptionProvided;

    final categoryColor = category.toLowerCase() == 'seeds'
        ? KMColors.warning
        : KMColors.primary;

    return Scaffold(
      appBar: AppBar(title: Text(safePlantName)),
      body: ListView(
        padding: const EdgeInsets.all(KMSpacing.lg),
        children: [
          // ── Hero image ────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(KMRadius.lg),
            child: (vendor.imageUrl != null && vendor.imageUrl!.isNotEmpty)
                ? Image.network(
                    vendor.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.local_florist, size: 64)),
                    ),
                  )
                : Container(
                    height: 200,
                    color: Theme.of(context).cardColor,
                    child: const Center(
                        child: Icon(Icons.local_florist, size: 64)),
                  ),
          ),

          const SizedBox(height: KMSpacing.lg),

          // ── Name + Category ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  safePlantName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: KMSpacing.sm),
              KMStatusChip(label: translatedCategory, color: categoryColor),
            ],
          ),

          const SizedBox(height: KMSpacing.lg),

          _infoRow(context, l.typeLabel, translatedTypeLabel),
          const SizedBox(height: KMSpacing.sm),
          _infoRow(context, l.priceLabel,
              '₹${vendor.price.toStringAsFixed(2)}'),
          const SizedBox(height: KMSpacing.sm),
          _infoRow(context, l.quantityLabel, vendor.quantity.toString()),
          const SizedBox(height: KMSpacing.sm),
          _infoRow(context, l.vendorLabel, safeVendorName),
          const SizedBox(height: KMSpacing.sm),
          _infoRow(context, l.locationLabel, safeLocation),
          const SizedBox(height: KMSpacing.sm),
          _infoRow(context, l.listedOnLabel, formatDate(vendor.timestamp)),

          const SizedBox(height: KMSpacing.xl),

          Text(
            l.descriptionLabel,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: KMSpacing.sm),
          Text(safeDescription),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date formatter (shared utility)
// ─────────────────────────────────────────────────────────────────────────────

String formatDate(DateTime dt) {
  final month = _monthName(dt.month);
  final hour =
      dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$month ${dt.day} $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
}

String _monthName(int m) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[(m - 1).clamp(0, 11)];
}
