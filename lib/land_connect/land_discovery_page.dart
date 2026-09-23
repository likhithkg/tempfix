import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/distance_service.dart';
import '../theme.dart';
import 'land_listing_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';
import 'land_detail_page.dart';

const _kPrimary = Color(kLcPrimary);

// ── Filter model ──────────────────────────────────────────────────────────────

class _LcFilter {
  final int maxDistanceKm;
  final double minAcres;
  final double maxAcres;
  final String waterSource;
  final String arrangement;
  final String crop;

  const _LcFilter({
    this.maxDistanceKm = 999,
    this.minAcres = 0,
    this.maxAcres = 9999,
    this.waterSource = 'Any',
    this.arrangement = 'Any',
    this.crop = 'Any',
  });

  int get activeCount {
    int c = 0;
    if (maxDistanceKm < 999) c++;
    if (minAcres > 0 || maxAcres < 9999) c++;
    if (waterSource != 'Any') c++;
    if (arrangement != 'Any') c++;
    if (crop != 'Any') c++;
    return c;
  }

  bool matches(LandListing l, double? userLat, double? userLon) {
    if (userLat != null && userLon != null && l.latitude != null && l.longitude != null &&
        maxDistanceKm < 999) {
      final d = DistanceService.haversine(userLat, userLon, l.latitude!, l.longitude!);
      if (d > maxDistanceKm) return false;
    }
    if (l.availableAcres < minAcres || l.availableAcres > maxAcres) return false;
    if (waterSource != 'Any' && l.waterAvailability != waterSource) return false;
    if (arrangement != 'Any' && l.arrangementType != arrangement) return false;
    if (crop != 'Any' &&
        !l.preferredCrops.any((c) => c.toLowerCase().contains(crop.toLowerCase()))) {
      return false;
    }
    return true;
  }
}

// ── Matching score ────────────────────────────────────────────────────────────

int _matchScore(LandListing l, double? userLat, double? userLon) {
  int score = 0;
  if (userLat != null && userLon != null && l.latitude != null && l.longitude != null) {
    final d = DistanceService.haversine(userLat, userLon, l.latitude!, l.longitude!);
    if (d < 5) { score += 30; }
    else if (d < 15) { score += 20; }
    else if (d < 30) { score += 10; }
  }
  if (l.waterAvailability.isNotEmpty && l.waterAvailability != 'Rainfed') score += 20;
  if (l.roadAccess) score += 15;
  if (l.isAvailableNow) score += 20;
  if (l.electricityAvailable) score += 10;
  if (l.preferredCrops.isNotEmpty) score += 5;
  return score;
}

// ── Page ──────────────────────────────────────────────────────────────────────

class LandDiscoveryPage extends StatefulWidget {
  const LandDiscoveryPage({super.key});

  @override
  State<LandDiscoveryPage> createState() => _LandDiscoveryPageState();
}

class _LandDiscoveryPageState extends State<LandDiscoveryPage> {
  Position? _userPos;
  bool _loadingLocation = true;
  bool _loadingListings = true;

  List<LandListing> _allListings = [];
  List<LandListing> _displayed = [];
  String _query = '';
  _LcFilter _filter = const _LcFilter();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Location
    final pos = await DistanceService.getUserLocation();
    if (mounted) setState(() { _userPos = pos; _loadingLocation = false; });
    // Listings
    await _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _loadingListings = true);
    try {
      final listings = await LandConnectService.getActiveListings();
      if (mounted) {
        _allListings = listings;
        _applyFilters();
        setState(() => _loadingListings = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingListings = false);
    }
  }

  void _applyFilters() {
    final userLat = _userPos?.latitude;
    final userLon = _userPos?.longitude;

    var filtered = _allListings.where((l) {
      final q = _query.toLowerCase();
      if (q.isNotEmpty) {
        final haystack = '${l.ownerName} ${l.village} ${l.district} ${l.preferredCrops.join(' ')}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return _filter.matches(l, userLat, userLon);
    }).toList();

    // Sort: nearest first (if location available), then by match score
    if (userLat != null && userLon != null) {
      filtered = DistanceService.sortByDistance(
        items: filtered,
        userLat: userLat,
        userLon: userLon,
        getLat: (l) => l.latitude,
        getLon: (l) => l.longitude,
      );
    } else {
      // Without location, sort by match score desc
      filtered.sort((a, b) =>
          _matchScore(b, null, null).compareTo(_matchScore(a, null, null)));
    }

    setState(() => _displayed = filtered);
  }

  void _onQueryChanged(String q) {
    _query = q;
    _applyFilters();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        current: _filter,
        onApply: (f) {
          setState(() => _filter = f);
          _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(l.lcDiscoveryTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(alignment: Alignment.topRight, children: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterSheet,
            ),
            if (_filter.activeCount > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${_filter.activeCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ),
          ]),
        ],
      ),
      body: Column(children: [
        // Search bar
        Container(
          color: _kPrimary,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: l.lcSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onQueryChanged('');
                        })
                    : null,
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),

        // Location notice
        if (!_loadingLocation && _userPos == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: Colors.orange.shade50,
            child: Row(children: [
              const Icon(Icons.location_off, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Enable location to see nearest land first',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
              ),
            ]),
          ),

        // List
        Expanded(
          child: _loadingListings
              ? const Center(child: CircularProgressIndicator())
              : _displayed.isEmpty
                  ? _empty(cs)
                  : RefreshIndicator(
                      onRefresh: _loadListings,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _displayed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _LandCard(
                          listing: _displayed[i],
                          userLat: _userPos?.latitude,
                          userLon: _userPos?.longitude,
                          matchScore: _matchScore(_displayed[i], _userPos?.latitude, _userPos?.longitude),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LandDetailPage(listing: _displayed[i],
                                  userLat: _userPos?.latitude, userLon: _userPos?.longitude),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _empty(ColorScheme cs) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.landscape_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text(_query.isNotEmpty || _filter.activeCount > 0
            ? 'No land matches your search / filters'
            : 'No land listings available yet',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        const SizedBox(height: 8),
        if (_filter.activeCount > 0)
          TextButton(
            onPressed: () {
              setState(() => _filter = const _LcFilter());
              _applyFilters();
            },
            child: const Text('Clear Filters'),
          ),
      ]),
    );
  }
}

// ── Land card ─────────────────────────────────────────────────────────────────

class _LandCard extends StatelessWidget {
  final LandListing listing;
  final double? userLat;
  final double? userLon;
  final int matchScore;
  final VoidCallback onTap;

  const _LandCard({
    required this.listing,
    this.userLat,
    this.userLon,
    required this.matchScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    double? dist;
    if (userLat != null && userLon != null &&
        listing.latitude != null && listing.longitude != null) {
      dist = DistanceService.haversine(
          userLat!, userLon!, listing.latitude!, listing.longitude!);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: KMShadow.card,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          if (listing.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 160, width: double.infinity,
                child: Image.network(
                  listing.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(cs),
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : Container(color: Colors.grey.shade200),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(height: 100, width: double.infinity,
                  child: _imagePlaceholder(cs)),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title + match score
              Row(children: [
                Expanded(
                  child: Text(listing.ownerName.isNotEmpty ? listing.ownerName : listing.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                if (matchScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: KMColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$matchScore%',
                        style: const TextStyle(fontSize: 11, color: KMColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 6),

              // Location + distance
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(listing.locationDisplay,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (dist != null) ...[
                  const SizedBox(width: 6),
                  Text(DistanceService.format(dist),
                      style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
                ],
              ]),
              const SizedBox(height: 8),

              // Key attributes
              Wrap(spacing: 6, runSpacing: 4, children: [
                _Pill(Icons.crop_square_rounded, '${listing.availableAcres.toStringAsFixed(1)} acres', Colors.brown),
                if (listing.waterAvailability.isNotEmpty)
                  _Pill(Icons.water_drop_outlined, listing.waterAvailability, Colors.blue),
                if (listing.soilType.isNotEmpty)
                  _Pill(Icons.landscape_outlined, listing.soilType, Colors.orange),
                if (listing.roadAccess)
                  const _Pill(Icons.route_outlined, 'Road', Colors.teal),
              ]),

              // Crops
              if (listing.preferredCrops.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Suitable: ${listing.preferredCrops.take(4).join(' • ')}${listing.preferredCrops.length > 4 ? ' +${listing.preferredCrops.length - 4}' : ''}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],

              const SizedBox(height: 8),
              // Arrangement + CTA
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_arrangementLabel(listing),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                            color: Color(kLcPrimary))),
                    if (listing.isAvailableNow)
                      const Text('Available Now',
                          style: TextStyle(fontSize: 11, color: Colors.green)),
                  ]),
                ),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(kLcPrimary),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _arrangementLabel(LandListing l) {
    switch (l.arrangementType) {
      case 'fixed_rent':
        return l.expectedRent > 0
            ? '₹${l.expectedRent.toStringAsFixed(0)}/${l.rentPeriod}'
            : 'Fixed Rent';
      case 'revenue_share':
        return l.revenueSharePercentage > 0
            ? '${l.revenueSharePercentage.toStringAsFixed(0)}% Revenue Share'
            : 'Revenue Share';
      default:
        return 'Negotiable';
    }
  }

  Widget _imagePlaceholder(ColorScheme cs) => Container(
    color: cs.primaryContainer.withValues(alpha: 0.2),
    child: Center(child: Icon(Icons.landscape_outlined,
        size: 40, color: cs.primary.withValues(alpha: 0.3))),
  );
}

// ── Pill chip ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _LcFilter current;
  final ValueChanged<_LcFilter> onApply;
  const _FilterSheet({required this.current, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _maxDist;
  late double _minAcres;
  late double _maxAcres;
  late String _water;
  late String _arrangement;
  late String _crop;

  @override
  void initState() {
    super.initState();
    _maxDist = widget.current.maxDistanceKm;
    _minAcres = widget.current.minAcres;
    _maxAcres = widget.current.maxAcres;
    _water = widget.current.waterSource;
    _arrangement = widget.current.arrangement;
    _crop = widget.current.crop;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Expanded(child: Text('Filter Land', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            TextButton(
              onPressed: () {
                setState(() {
                  _maxDist = 999; _minAcres = 0; _maxAcres = 9999;
                  _water = 'Any'; _arrangement = 'Any'; _crop = 'Any';
                });
              },
              child: const Text('Reset'),
            ),
          ]),
        ),
        Expanded(
          child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 16), children: [

            // Distance
            const Text('Distance', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final (label, km) in [('5 km', 5), ('10 km', 10), ('25 km', 25), ('50 km', 50), ('Any', 999)])
                ChoiceChip(
                  label: Text(label),
                  selected: _maxDist == km,
                  onSelected: (_) => setState(() => _maxDist = km),
                  selectedColor: _kPrimary.withValues(alpha: 0.15),
                )
            ]),
            const SizedBox(height: 16),

            // Land size
            const Text('Land Size', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final (label, min, max) in [
                ('< 1 acre', 0.0, 1.0),
                ('1–2 acres', 1.0, 2.0),
                ('2–5 acres', 2.0, 5.0),
                ('5–10 acres', 5.0, 10.0),
                ('10+ acres', 10.0, 9999.0),
                ('Any', 0.0, 9999.0),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _minAcres == min && _maxAcres == max,
                  onSelected: (_) => setState(() { _minAcres = min; _maxAcres = max; }),
                  selectedColor: _kPrimary.withValues(alpha: 0.15),
                )
            ]),
            const SizedBox(height: 16),

            // Water
            const Text('Water Source', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final w in ['Any', ...kWaterSources])
                ChoiceChip(
                  label: Text(w),
                  selected: _water == w,
                  onSelected: (_) => setState(() => _water = w),
                  selectedColor: _kPrimary.withValues(alpha: 0.15),
                )
            ]),
            const SizedBox(height: 16),

            // Arrangement
            const Text('Arrangement', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final (label, val) in [
                ('Any', 'Any'), ('Fixed Rent', 'fixed_rent'),
                ('Revenue Share', 'revenue_share'), ('Negotiable', 'negotiable'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _arrangement == val,
                  onSelected: (_) => setState(() => _arrangement = val),
                  selectedColor: _kPrimary.withValues(alpha: 0.15),
                )
            ]),
            const SizedBox(height: 16),

            // Crop
            const Text('Crop', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final c in ['Any', ...kCrops.take(12)])
                ChoiceChip(
                  label: Text(c),
                  selected: _crop == c,
                  onSelected: (_) => setState(() => _crop = c),
                  selectedColor: _kPrimary.withValues(alpha: 0.15),
                )
            ]),
            const SizedBox(height: 24),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_LcFilter(
                    maxDistanceKm: _maxDist,
                    minAcres: _minAcres,
                    maxAcres: _maxAcres,
                    waterSource: _water,
                    arrangement: _arrangement,
                    crop: _crop,
                  ));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
