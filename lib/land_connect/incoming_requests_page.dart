import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'land_request_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';

const _kPrimary = Color(kLcPrimary);

class IncomingRequestsPage extends StatelessWidget {
  final String? filterListingId;
  const IncomingRequestsPage({super.key, this.filterListingId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _kPrimary,
          title: Text(l.lcCultivationRequests,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l.lcPendingTab),
              Tab(text: l.lcAcceptedTab),
              Tab(text: l.lcRejectedTab),
            ],
          ),
        ),
        body: TabBarView(children: [
          _RequestList(status: 'pending', filterListingId: filterListingId, label: l.lcPendingTab),
          _RequestList(status: 'accepted', filterListingId: filterListingId, label: l.lcAcceptedTab),
          _RequestList(status: 'rejected', filterListingId: filterListingId, label: l.lcRejectedTab),
        ]),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final String status;
  final String? filterListingId;
  final String label;
  const _RequestList({required this.status, this.filterListingId, required this.label});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LandRequest>>(
      stream: LandConnectService.incomingRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var requests = (snap.data ?? []).where((r) => r.status == status).toList();
        if (filterListingId != null) {
          requests = requests.where((r) => r.listingId == filterListingId).toList();
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_outlined, size: 56,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No $label requests',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _IncomingRequestCard(request: requests[i]),
        );
      },
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final LandRequest request;
  const _IncomingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = request;

    final statusColor = switch (r.status) {
      'pending' => Colors.orange,
      'accepted' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
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
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.1),
            child: Text(r.cultivatorName.isNotEmpty ? r.cultivatorName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(kLcPrimary), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.cultivatorName.isNotEmpty ? r.cultivatorName : 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('For: ${r.landTitle}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(r.status.toUpperCase(),
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Divider(height: 16),

        // Request details
        _Row(Icons.grass_outlined, 'Crop', r.cropName),
        _Row(Icons.crop_square_rounded, 'Required', '${r.requestedAcres.toStringAsFixed(1)} acres'),
        _Row(Icons.calendar_month_outlined, 'Duration', '${r.durationMonths} months'),
        if (r.cultivatorExperience > 0)
          _Row(Icons.work_outline, 'Experience', '${r.cultivatorExperience} years'),
        _Row(Icons.handshake_outlined, 'Arrangement',
            kArrangementLabels[r.proposedArrangement] ?? r.proposedArrangement),
        if (r.proposedAmount > 0)
          _Row(Icons.currency_rupee, 'Proposed Amount', '₹${r.proposedAmount.toStringAsFixed(0)}'),
        if (r.message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Message', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(r.message, style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ],

        // Contact info
        const SizedBox(height: 10),
        if (r.status == 'accepted')
          _AcceptedContactsCard(request: r)
        else
          _ContactCard(
            label: 'Cultivator Contact',
            name: r.cultivatorName,
            phone: r.cultivatorPhone,
            location: r.landLocation.isNotEmpty ? r.landLocation : null,
            accepted: false,
          ),

        if (r.status == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateStatus(context, r.id, 'rejected'),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(context, r.id, 'accepted'),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  void _updateStatus(BuildContext context, String id, String status) {
    final action = status == 'accepted' ? 'accept' : 'reject';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${action.substring(0, 1).toUpperCase()}${action.substring(1)} Request'),
        content: Text('Are you sure you want to $action this cultivation request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await LandConnectService.updateRequestStatus(id, status);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Request $status')));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            child: Text(status == 'accepted' ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
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

        // Cultivator contact
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cultivator', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _row(Icons.person_rounded, r.cultivatorName.isNotEmpty ? r.cultivatorName : 'Unknown', null),
            const SizedBox(height: 4),
            if (r.cultivatorPhone.isNotEmpty)
              _row(Icons.phone_rounded, r.cultivatorPhone, () => _copy(context, r.cultivatorPhone, 'Cultivator phone'))
            else
              _noPhone(),
            if (r.cultivatorExperience > 0) ...[
              const SizedBox(height: 4),
              _row(Icons.work_outline, '${r.cultivatorExperience} years experience', null),
            ],
          ]),
        ),

        Divider(color: Colors.green.shade200, height: 1),

        // Owner's own info (what cultivator sees)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Info (shared with cultivator)', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _row(Icons.person_rounded, r.ownerName.isNotEmpty ? r.ownerName : 'You', null),
            const SizedBox(height: 4),
            if (r.ownerPhone.isNotEmpty)
              _row(Icons.phone_rounded, r.ownerPhone, () => _copy(context, r.ownerPhone, 'Your phone'))
            else
              _noPhone(label: 'No phone on your listing — add one in My Land'),
            if (r.landLocation.isNotEmpty) ...[
              const SizedBox(height: 4),
              _row(Icons.location_on_outlined, r.landLocation, null),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback? onTap) {
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

  Widget _noPhone({String label = 'No phone number provided'}) {
    return Row(children: [
      Icon(Icons.phone_disabled_outlined, size: 15, color: Colors.grey.shade400),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
    ]);
  }
}

class _ContactCard extends StatelessWidget {
  final String label;
  final String name;
  final String phone;
  final String? location;
  final bool accepted;

  const _ContactCard({
    required this.label,
    required this.name,
    required this.phone,
    this.location,
    required this.accepted,
  });

  void _copy(BuildContext context, String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final border = accepted ? Colors.green.shade200 : Colors.brown.shade200;
    final bg = accepted ? Colors.green.shade50 : Colors.brown.shade50;
    final accent = accepted ? Colors.green.shade700 : const Color(kLcPrimary);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(accepted ? Icons.check_circle : Icons.person_outline,
              size: 14, color: accent),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        // Name row
        Row(children: [
          Icon(Icons.person_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name.isNotEmpty ? name : 'Not provided',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 6),
        // Phone row — tappable to copy
        if (phone.isNotEmpty)
          GestureDetector(
            onTap: () => _copy(context, phone, 'Phone number'),
            child: Row(children: [
              Icon(Icons.phone_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(phone,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent)),
              ),
              Icon(Icons.copy_rounded, size: 14, color: accent.withValues(alpha: 0.6)),
            ]),
          )
        else
          Row(children: [
            Icon(Icons.phone_rounded, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text('No phone number provided',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ]),
        // Location row
        if (location != null && location!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.location_on_outlined, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(location!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ]),
        ],
      ]),
    );
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
