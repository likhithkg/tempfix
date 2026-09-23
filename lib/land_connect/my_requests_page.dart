import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'land_request_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';

const _kPrimary = Color(kLcPrimary);

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _kPrimary,
          title: Text(l.lcMyRequests,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l.lcPendingTab),
              Tab(text: l.lcAcceptedTab),
              const Tab(text: 'Others'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _MyRequestList(statusFilter: 'pending'),
          _MyRequestList(statusFilter: 'accepted'),
          _MyRequestList(statusFilter: 'other'),
        ]),
      ),
    );
  }
}

class _MyRequestList extends StatelessWidget {
  final String statusFilter;
  const _MyRequestList({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LandRequest>>(
      stream: LandConnectService.myCultivatorRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var requests = snap.data ?? [];
        if (statusFilter == 'other') {
          requests = requests
              .where((r) => r.status != 'pending' && r.status != 'accepted')
              .toList();
        } else {
          requests = requests.where((r) => r.status == statusFilter).toList();
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.send_outlined, size: 56,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No ${statusFilter == 'other' ? '' : statusFilter} requests',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _MyRequestCard(request: requests[i]),
        );
      },
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final LandRequest request;
  const _MyRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = request;

    final statusColor = switch (r.status) {
      'pending' => Colors.orange,
      'accepted' => Colors.green,
      'rejected' => Colors.red,
      'withdrawn' => Colors.grey,
      _ => Colors.grey,
    };

    final statusIcon = switch (r.status) {
      'pending' => Icons.hourglass_top_outlined,
      'accepted' => Icons.check_circle_outline,
      'rejected' => Icons.cancel_outlined,
      'withdrawn' => Icons.undo_outlined,
      _ => Icons.help_outline,
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KMShadow.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.landscape_outlined, color: Color(kLcPrimary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.landTitle.isNotEmpty ? r.landTitle : 'Land Listing',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(r.landLocation.isNotEmpty ? r.landLocation : 'Location unknown',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(r.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const Divider(height: 16),

        _Row(Icons.grass_outlined, 'Crop', r.cropName),
        _Row(Icons.crop_square_rounded, 'Acreage', '${r.requestedAcres.toStringAsFixed(1)} acres'),
        _Row(Icons.calendar_month_outlined, 'Duration', '${r.durationMonths} months'),
        _Row(Icons.handshake_outlined, 'Arrangement',
            kArrangementLabels[r.proposedArrangement] ?? r.proposedArrangement),
        if (r.proposedAmount > 0)
          _Row(Icons.currency_rupee, 'Proposed', '₹${r.proposedAmount.toStringAsFixed(0)}'),

        // Accepted — show both contacts
        if (r.status == 'accepted') ...[
          const SizedBox(height: 10),
          _AcceptedContactsCard(request: r),
        ],

        // Withdraw option for pending
        if (r.status == 'pending') ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _confirmWithdraw(context, r.id),
              icon: const Icon(Icons.undo, size: 16),
              label: Text(AppLocalizations.of(context)!.lcWithdrawRequest),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red)),
            ),
          ),
        ],

        // Date
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(_formatDate(r.createdAt),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ),
      ]),
    );
  }

  void _confirmWithdraw(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Request'),
        content: const Text('Are you sure you want to withdraw this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await LandConnectService.withdrawRequest(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request withdrawn')));
              }
            },
            child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _AcceptedContactsCard extends StatelessWidget {
  final LandRequest request;
  const _AcceptedContactsCard({required this.request});

  void _copy(BuildContext context, String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what copied'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: const Row(children: [
            Icon(Icons.handshake_rounded, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text('Request Accepted — Contact Details',
                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w700)),
          ]),
        ),

        // Owner contact
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Landowner', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _contactRow(context, Icons.person_rounded, r.ownerName.isNotEmpty ? r.ownerName : 'Unknown', null),
            const SizedBox(height: 4),
            if (r.ownerPhone.isNotEmpty)
              _contactRow(context, Icons.phone_rounded, r.ownerPhone, () => _copy(context, r.ownerPhone, 'Owner phone'))
            else
              _noPhone(),
            if (r.landLocation.isNotEmpty) ...[
              const SizedBox(height: 4),
              _contactRow(context, Icons.location_on_outlined, r.landLocation, null),
            ],
          ]),
        ),

        Divider(color: Colors.green.shade200, height: 1),

        // Cultivator's own info (what owner can see)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Info (shared with owner)', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _contactRow(context, Icons.person_rounded, r.cultivatorName.isNotEmpty ? r.cultivatorName : 'You', null),
            const SizedBox(height: 4),
            if (r.cultivatorPhone.isNotEmpty)
              _contactRow(context, Icons.phone_rounded, r.cultivatorPhone, () => _copy(context, r.cultivatorPhone, 'Your phone'))
            else
              _noPhone(label: 'Phone not provided — edit your request to add it'),
          ]),
        ),
      ]),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String text, VoidCallback? onTap) {
    final isPhone = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.green.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isPhone ? FontWeight.bold : FontWeight.w500,
                  color: isPhone ? Colors.green.shade700 : null)),
        ),
        if (isPhone) Icon(Icons.copy_rounded, size: 13, color: Colors.green.shade400),
      ]),
    );
  }

  Widget _noPhone({String label = 'No phone number on file'}) {
    return Row(children: [
      Icon(Icons.phone_disabled_outlined, size: 15, color: Colors.grey.shade400),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
    ]);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: const Color(kLcPrimary)),
        const SizedBox(width: 8),
        SizedBox(width: 80,
            child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
