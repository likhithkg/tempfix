import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/distance_service.dart';
import '../theme.dart';
import 'land_listing_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';
import 'send_request_page.dart';

const _kPrimary = Color(kLcPrimary);

class LandDetailPage extends StatefulWidget {
  final LandListing listing;
  final double? userLat;
  final double? userLon;

  const LandDetailPage({
    super.key,
    required this.listing,
    this.userLat,
    this.userLon,
  });

  @override
  State<LandDetailPage> createState() => _LandDetailPageState();
}

class _LandDetailPageState extends State<LandDetailPage> {
  int _imageIndex = 0;
  bool _hasActiveRequest = false;
  bool _checkingRequest = true;
  late PageController _pageCtrl;
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _checkRequest();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkRequest() async {
    if (_uid == null) { setState(() => _checkingRequest = false); return; }
    final has = await LandConnectService.hasActiveRequest(widget.listing.id);
    if (mounted) setState(() { _hasActiveRequest = has; _checkingRequest = false; });
  }

  void _openRequestPage() async {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to send a request')));
      return;
    }
    if (_hasActiveRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have an active request for this land')));
      return;
    }
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => SendRequestPage(listing: widget.listing)),
    );
    if (sent == true && mounted) {
      setState(() => _hasActiveRequest = true);
    }
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => _ReportSheet(listingId: widget.listing.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final isOwner = _uid == l.ownerId;

    double? dist;
    if (widget.userLat != null && widget.userLon != null &&
        l.latitude != null && l.longitude != null) {
      dist = DistanceService.haversine(
          widget.userLat!, widget.userLon!, l.latitude!, l.longitude!);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image carousel in SliverAppBar
          SliverAppBar(
            expandedHeight: l.images.isNotEmpty ? 280 : 120,
            pinned: true,
            backgroundColor: _kPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (!isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) { if (v == 'report') _showReportSheet(); },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'report', child: Text('Report Listing')),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: l.images.isNotEmpty
                  ? Stack(children: [
                      PageView.builder(
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemCount: l.images.length,
                        itemBuilder: (_, i) => Image.network(
                          l.images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.primaryContainer.withValues(alpha: 0.2),
                            child: Icon(Icons.landscape_outlined,
                                size: 60, color: cs.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                      if (l.images.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_imageIndex + 1}/${l.images.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ])
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(kLcDark), Color(kLcPrimary)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                          child: Icon(Icons.landscape_rounded, size: 60, color: Colors.white38)),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Owner name + location
                Text(l.ownerName.isNotEmpty ? l.ownerName : l.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(l.locationDisplay,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ),
                  if (dist != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(DistanceService.format(dist),
                          style: const TextStyle(
                              fontSize: 12, color: Color(kLcPrimary), fontWeight: FontWeight.w600)),
                    ),
                ]),
                const SizedBox(height: 12),

                // Quick stats row
                Row(children: [
                  _StatBox(Icons.crop_square_rounded,
                      '${l.availableAcres.toStringAsFixed(1)} acres', 'Available', _kPrimary),
                  const SizedBox(width: 8),
                  _StatBox(Icons.water_drop_outlined,
                      l.waterAvailability.isNotEmpty ? l.waterAvailability : '—',
                      'Water', Colors.blue),
                  const SizedBox(width: 8),
                  _StatBox(Icons.landscape_outlined,
                      l.soilType.isNotEmpty ? l.soilType : '—', 'Soil', Colors.orange),
                ]),
                const SizedBox(height: 16),

                // Availability status
                if (l.isAvailableNow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text('Available Now',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),

                if (l.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('About this land'),
                  const SizedBox(height: 6),
                  Text(l.description, style: TextStyle(fontSize: 14, color: cs.onSurface)),
                ],

                const SizedBox(height: 16),
                _sectionTitle('Land Details'),
                const SizedBox(height: 8),
                _DetailsGrid(listing: l),

                if (l.preferredCrops.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Suitable Crops'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: l.preferredCrops.map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      backgroundColor: KMColors.primary.withValues(alpha: 0.08),
                      side: BorderSide(color: KMColors.primary.withValues(alpha: 0.2)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 16),
                _sectionTitle('Arrangement'),
                const SizedBox(height: 8),
                _ArrangementCard(listing: l),

                if (!isOwner) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Privacy Notice'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      loc.lcPrivacyNotice,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: KMShadow.elevated,
              ),
              child: SafeArea(
                top: false,
                child: _checkingRequest
                    ? const Center(child: CircularProgressIndicator())
                    : _hasActiveRequest
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(loc.lcRequestAlreadySent,
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ]),
                          )
                        : ElevatedButton.icon(
                            onPressed: _openRequestPage,
                            icon: const Icon(Icons.send_outlined),
                            label: Text(loc.lcRequestCultivate,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) =>
      Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
}

// ── Details grid ──────────────────────────────────────────────────────────────

class _DetailsGrid extends StatelessWidget {
  final LandListing listing;
  const _DetailsGrid({required this.listing});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Acres', '${listing.totalAcres.toStringAsFixed(1)} acres', Icons.straighten),
      ('Available', '${listing.availableAcres.toStringAsFixed(1)} acres', Icons.crop_square_rounded),
      ('Land Type', listing.landType, Icons.terrain_outlined),
      if (listing.irrigationType.isNotEmpty)
        ('Irrigation', listing.irrigationType, Icons.water_outlined),
      ('Electricity', listing.electricityAvailable ? 'Yes' : 'No', Icons.electric_bolt_outlined),
      ('Road Access', listing.roadAccess ? 'Yes' : 'No', Icons.route_outlined),
      ('Equipment', listing.farmEquipmentAvailable ? 'Available' : 'Not available', Icons.agriculture_outlined),
      ('Fencing', listing.fencingAvailable ? 'Yes' : 'No', Icons.fence_outlined),
      ('Storage', listing.storageAvailable ? 'Available' : 'Not available', Icons.warehouse_outlined),
    ];

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: items.map((item) {
        final (label, value, icon) = item;
        final cs = Theme.of(context).colorScheme;
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: const Color(kLcPrimary)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      }).toList(),
    );
  }
}

// ── Arrangement card ──────────────────────────────────────────────────────────

class _ArrangementCard extends StatelessWidget {
  final LandListing listing;
  const _ArrangementCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = kArrangementLabels[listing.arrangementType] ?? 'Negotiable';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(kLcPrimary).withValues(alpha: 0.08),
              const Color(kLcPrimary).withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(kLcPrimary).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
            color: Color(kLcPrimary))),
        if (listing.arrangementType == 'fixed_rent' && listing.expectedRent > 0) ...[
          const SizedBox(height: 4),
          Text('₹${listing.expectedRent.toStringAsFixed(0)} / ${listing.rentPeriod}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
        if (listing.arrangementType == 'revenue_share' && listing.revenueSharePercentage > 0) ...[
          const SizedBox(height: 4),
          Text('${listing.revenueSharePercentage.toStringAsFixed(0)}% of crop revenue',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
        if (listing.arrangementType == 'negotiable') ...[
          const SizedBox(height: 4),
          Text('Terms to be discussed with the landowner',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

// ── Report sheet ──────────────────────────────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  final String listingId;
  const _ReportSheet({required this.listingId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Report Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v),
          child: Column(
            children: kReportReasons.map((r) => RadioListTile<String>(
              value: r,
              title: Text(r),
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(kLcPrimary),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_reason == null || _submitting)
                ? null
                : () async {
                    setState(() => _submitting = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await LandConnectService.reportListing(
                        listingId: widget.listingId, reason: _reason!);
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Report submitted. Thank you.')));
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: _submitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Report'),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
