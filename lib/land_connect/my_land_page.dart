import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'land_listing_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';
import 'land_listing_form_page.dart';
import 'incoming_requests_page.dart';

const _kPrimary = Color(kLcPrimary);

class MyLandPage extends StatelessWidget {
  const MyLandPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _kPrimary,
          title: Text(l.lcMyListings,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l.lcActiveTab),
              Tab(text: l.lcPausedTab),
              const Tab(text: 'All'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ListingsList(statusFilter: 'active'),
            _ListingsList(statusFilter: 'paused'),
            _ListingsList(statusFilter: null),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LandListingFormPage())),
          backgroundColor: _kPrimary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(l.lcAddListing, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _ListingsList extends StatelessWidget {
  final String? statusFilter;
  const _ListingsList({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LandListing>>(
      stream: LandConnectService.myListings(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        var listings = snap.data ?? [];
        if (statusFilter != null) {
          listings = listings.where((l) => l.status == statusFilter).toList();
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.landscape_outlined, size: 56,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(statusFilter == 'active'
                  ? 'No active land listings'
                  : statusFilter == 'paused'
                      ? 'No paused listings'
                      : 'No land listings yet',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              if (statusFilter == null || statusFilter == 'active')
                TextButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LandListingFormPage())),
                  icon: const Icon(Icons.add),
                  label: const Text('List Your Land'),
                ),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _MyLandCard(listing: listings[i]),
        );
      },
    );
  }
}

class _MyLandCard extends StatelessWidget {
  final LandListing listing;
  const _MyLandCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final statusColor = switch (listing.status) {
      'active' => Colors.green,
      'paused' => Colors.orange,
      'occupied' => Colors.blue,
      _ => Colors.grey,
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KMShadow.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Image preview
        if (listing.images.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 120, width: double.infinity,
              child: Image.network(listing.images.first, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(cs)),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(listing.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(listing.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 4),
            Text('${listing.availableAcres.toStringAsFixed(1)} acres • ${listing.locationDisplay}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),

            Row(children: [
              _ActionBtn(
                icon: Icons.inbox_outlined,
                label: 'Requests',
                color: _kPrimary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => IncomingRequestsPage(
                        filterListingId: listing.id))),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: Colors.indigo,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => LandListingFormPage(existing: listing))),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: listing.status == 'active'
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                label: listing.status == 'active' ? 'Pause' : 'Resume',
                color: Colors.orange,
                onTap: () => _toggleStatus(context, listing),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.red,
                onTap: () => _confirmDelete(context, listing),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _toggleStatus(BuildContext context, LandListing l) async {
    final newStatus = l.status == 'active' ? 'paused' : 'active';
    await LandConnectService.updateListingStatus(l.id, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing ${newStatus == 'active' ? 'resumed' : 'paused'}')));
    }
  }

  void _confirmDelete(BuildContext context, LandListing l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await LandConnectService.deleteListing(l.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
    color: cs.primaryContainer.withValues(alpha: 0.2),
    child: Center(child: Icon(Icons.landscape_outlined,
        size: 36, color: cs.primary.withValues(alpha: 0.3))),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: color)),
      ]),
    );
  }
}
