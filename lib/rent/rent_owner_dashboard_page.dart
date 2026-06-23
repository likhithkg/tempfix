// lib/rent/rent_owner_dashboard_page.dart — RentHub 3.0 Owner Mode (Rapido Driver Style)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rent_booking_model.dart';
import 'rent_machine_service.dart';

// ─── Status colors ────────────────────────────────────────────────────────────

Color _statusColor(BookingStatus s) {
  switch (s) {
    case BookingStatus.requested:  return const Color(0xFF9E9E9E);
    case BookingStatus.accepted:   return const Color(0xFF1565C0);
    case BookingStatus.onTheWay:   return const Color(0xFFFF9800);
    case BookingStatus.arrived:    return const Color(0xFF4CAF50);
    case BookingStatus.working:    return const Color(0xFF9C27B0);
    case BookingStatus.completed:  return const Color(0xFF2E7D32);
    case BookingStatus.rejected:   return const Color(0xFFD32F2F);
  }
}

String _statusEmoji(BookingStatus s) {
  switch (s) {
    case BookingStatus.requested:  return '📋';
    case BookingStatus.accepted:   return '✅';
    case BookingStatus.onTheWay:   return '🚗';
    case BookingStatus.arrived:    return '📍';
    case BookingStatus.working:    return '⚙️';
    case BookingStatus.completed:  return '🎉';
    case BookingStatus.rejected:   return '❌';
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────

class RentOwnerDashboardPage extends StatefulWidget {
  const RentOwnerDashboardPage({super.key});

  @override
  State<RentOwnerDashboardPage> createState() =>
      _RentOwnerDashboardPageState();
}

class _RentOwnerDashboardPageState extends State<RentOwnerDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _ownerId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _accept(RentBooking b) async {
    await RentMachineService.instance
        .updateBookingStatus(b.id, BookingStatus.accepted);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Booking accepted! Farmer has been notified.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  Future<void> _reject(RentBooking b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Booking?'),
        content: Text(
            'Reject ${b.farmerName}\'s request for ${b.machineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await RentMachineService.instance
          .updateBookingStatus(b.id, BookingStatus.rejected);
    }
  }

  Future<void> _updateStatus(RentBooking b, BookingStatus next) async {
    await RentMachineService.instance.updateBookingStatus(b.id, next);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_statusEmoji(next)} Status updated: ${next.label}'),
          backgroundColor: _statusColor(next),
        ),
      );
    }
  }

  Future<void> _navigateToField(RentBooking b) async {
    if (b.fieldLatitude == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${b.fieldLatitude},${b.fieldLongitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callFarmer(RentBooking b) async {
    final uri = Uri(scheme: 'tel', path: b.ownerPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_ownerId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to access Owner Mode')),
      );
    }

    return StreamBuilder<List<RentBooking>>(
      stream: RentMachineService.instance.streamBookingsByOwner(_ownerId),
      builder: (ctx, snap) {
        final all = snap.data ?? [];
        final pending =
            all.where((b) => b.status == BookingStatus.requested).toList();
        final active = all
            .where((b) => [
                  BookingStatus.accepted,
                  BookingStatus.onTheWay,
                  BookingStatus.arrived,
                  BookingStatus.working,
                ].contains(b.status))
            .toList();
        final history = all
            .where((b) => [
                  BookingStatus.completed,
                  BookingStatus.rejected,
                ].contains(b.status))
            .toList();

        final double totalEarnings = history
            .where((b) => b.status == BookingStatus.completed)
            .fold(0, (sum, b) => sum + b.totalCost);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B1B2F),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Owner Dashboard',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('Manage your machine bookings',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white54)),
                ]),
            actions: [
              if (pending.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${pending.length} new',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
            ],
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFFFF9800),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Requests'),
                        if (pending.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${pending.length}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ]),
                ),
                Tab(text: 'Active (${active.length})'),
                const Tab(text: 'History'),
              ],
            ),
          ),
          body: Column(children: [
            // ── Earnings strip ─────────────────────────────────
            _EarningsStrip(totalEarnings: totalEarnings, completed: history
                .where((b) => b.status == BookingStatus.completed).length),

            // ── Tabs ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  // ── Requests tab ───────────────────────────
                  _RequestsTab(
                    bookings: pending,
                    onAccept: _accept,
                    onReject: _reject,
                  ),
                  // ── Active tab ─────────────────────────────
                  _ActiveTab(
                    bookings: active,
                    onUpdateStatus: _updateStatus,
                    onNavigate: _navigateToField,
                    onCall: _callFarmer,
                  ),
                  // ── History tab ────────────────────────────
                  _HistoryTab(bookings: history),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─── Earnings strip ───────────────────────────────────────────────────────────

class _EarningsStrip extends StatelessWidget {
  final double totalEarnings;
  final int completed;
  const _EarningsStrip(
      {required this.totalEarnings, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B1B2F),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: [
        _EarningsTile('💰', '₹${totalEarnings.toStringAsFixed(0)}',
            'Total Earnings'),
        const SizedBox(width: 16),
        _EarningsTile('✅', '$completed', 'Jobs Done'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
            SizedBox(width: 5),
            Text('Online',
                style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

class _EarningsTile extends StatelessWidget {
  final String emoji, value, label;
  const _EarningsTile(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900)),
      ]),
      Text(label,
          style: const TextStyle(
              color: Colors.white54, fontSize: 10)),
    ]);
  }
}

// ─── Requests tab (Rapido-style accept/reject) ────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final List<RentBooking> bookings;
  final Future<void> Function(RentBooking) onAccept;
  final Future<void> Function(RentBooking) onReject;

  const _RequestsTab({
      required this.bookings,
      required this.onAccept,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🕐', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('No pending requests',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('New booking requests will appear here',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E))),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _RequestCard(
        booking: bookings[i],
        onAccept: () => onAccept(bookings[i]),
        onReject: () => onReject(bookings[i]),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final RentBooking booking;
  final Future<void> Function() onAccept, onReject;
  const _RequestCard(
      {required this.booking,
      required this.onAccept,
      required this.onReject});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
          scale: _pulseAnim.value, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.6),
              width: 2),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          // ── Header ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔔',
                    style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Booking Request!',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFE65100))),
                      Text('from ${b.farmerName}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF616161))),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('NEW',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ]),
          ),

          // ── Details ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _BookingDetailRow(
                  Icons.agriculture_rounded, 'Machine', b.machineName),
              _BookingDetailRow(Icons.access_time_rounded, 'Duration',
                  '${b.hours} hour${b.hours > 1 ? 's' : ''}'),
              _BookingDetailRow(Icons.calendar_today_rounded, 'Date',
                  '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}'),
              _BookingDetailRow(Icons.location_on_rounded, 'Location',
                  b.fieldLocation.isNotEmpty
                      ? b.fieldLocation
                      : 'Not specified'),
              if (b.notes != null && b.notes!.isNotEmpty)
                _BookingDetailRow(
                    Icons.note_rounded, 'Notes', b.notes!),
              const SizedBox(height: 4),
              // Cost summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Earnings',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF616161))),
                            Text('(after travel deduction)',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF9E9E9E))),
                          ]),
                      Text(
                          '₹${b.machineCharge.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32))),
                    ]),
              ),
            ]),
          ),

          // ── Accept / Reject buttons ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              // REJECT
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : widget.onReject,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFD32F2F), width: 1.5),
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('✗  Reject',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              // ACCEPT — big green Rapido-style
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await widget.onAccept();
                          if (mounted) setState(() => _loading = false);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('✓  Accept Booking',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Active tab ───────────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  final List<RentBooking> bookings;
  final Future<void> Function(RentBooking, BookingStatus) onUpdateStatus;
  final Future<void> Function(RentBooking) onNavigate;
  final Future<void> Function(RentBooking) onCall;

  const _ActiveTab({
    required this.bookings,
    required this.onUpdateStatus,
    required this.onNavigate,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🚜', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('No active bookings',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Accepted bookings will appear here',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E))),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _ActiveBookingCard(
        booking: bookings[i],
        onUpdateStatus: (next) => onUpdateStatus(bookings[i], next),
        onNavigate: () => onNavigate(bookings[i]),
        onCall: () => onCall(bookings[i]),
      ),
    );
  }
}

class _ActiveBookingCard extends StatefulWidget {
  final RentBooking booking;
  final Future<void> Function(BookingStatus) onUpdateStatus;
  final VoidCallback onNavigate, onCall;

  const _ActiveBookingCard({
    required this.booking,
    required this.onUpdateStatus,
    required this.onNavigate,
    required this.onCall,
  });

  @override
  State<_ActiveBookingCard> createState() => _ActiveBookingCardState();
}

class _ActiveBookingCardState extends State<_ActiveBookingCard> {
  bool _loading = false;

  BookingStatus? _nextStatus(BookingStatus current) {
    switch (current) {
      case BookingStatus.accepted:   return BookingStatus.onTheWay;
      case BookingStatus.onTheWay:   return BookingStatus.arrived;
      case BookingStatus.arrived:    return BookingStatus.working;
      case BookingStatus.working:    return BookingStatus.completed;
      default: return null;
    }
  }

  String _nextLabel(BookingStatus current) {
    switch (current) {
      case BookingStatus.accepted:   return '🚗  I\'m Heading There';
      case BookingStatus.onTheWay:   return '📍  I\'ve Arrived';
      case BookingStatus.arrived:    return '⚙️  Work Started';
      case BookingStatus.working:    return '🎉  Mark Completed';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final color = _statusColor(b.status);
    final next = _nextStatus(b.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10)
        ],
      ),
      child: Column(children: [
        // Status header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18)),
          ),
          child: Row(children: [
            Text(_statusEmoji(b.status),
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.status.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: color)),
                    Text(b.machineName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF616161))),
                  ]),
            ),
            Text('₹${b.machineCharge.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E7D32))),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // Farmer info
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Text(
                    b.farmerName.isNotEmpty
                        ? b.farmerName[0].toUpperCase()
                        : 'F',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.farmerName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${b.hours} hr • '
                          '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E))),
                    ]),
              ),
              // Call farmer button
              GestureDetector(
                onTap: widget.onCall,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_rounded,
                      size: 18, color: Color(0xFF2E7D32)),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            // Field location
            if (b.fieldLocation.isNotEmpty)
              GestureDetector(
                onTap: widget.onNavigate,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.navigation_rounded,
                        size: 16, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(b.fieldLocation,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600),
                          maxLines: 2),
                    ),
                    const Icon(Icons.open_in_new_rounded,
                        size: 14, color: Color(0xFF1565C0)),
                  ]),
                ),
              ),
            const SizedBox(height: 10),
            // Status update button
            if (next != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await widget.onUpdateStatus(next);
                          if (mounted) setState(() => _loading = false);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_nextLabel(b.status),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ─── History tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<RentBooking> bookings;
  const _HistoryTab({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('📋', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('No history yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];
        final isCompleted = b.status == BookingStatus.completed;
        final color = _statusColor(b.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8)
            ],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12)),
              child: Center(
                  child: Text(_statusEmoji(b.status),
                      style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.machineName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${b.farmerName} • '
                        '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                    Text(b.status.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ]),
            ),
            if (isCompleted)
              Text('₹${b.machineCharge.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32))),
          ]),
        );
      },
    );
  }
}

// ─── Reusable row ─────────────────────────────────────────────────────────────

class _BookingDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _BookingDetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF9E9E9E)),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text('$label:',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E))),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                  maxLines: 3),
            ),
          ]),
    );
  }
}
