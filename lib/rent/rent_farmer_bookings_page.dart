// lib/rent/rent_farmer_bookings_page.dart — My Bookings (farmer view)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rent_booking_model.dart';
import 'rent_machine_service.dart';
import 'rent_tracking_page.dart';

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

bool _isActive(BookingStatus s) => [
      BookingStatus.requested,
      BookingStatus.accepted,
      BookingStatus.onTheWay,
      BookingStatus.arrived,
      BookingStatus.working,
    ].contains(s);

class RentFarmerBookingsPage extends StatefulWidget {
  const RentFarmerBookingsPage({super.key});

  @override
  State<RentFarmerBookingsPage> createState() =>
      _RentFarmerBookingsPageState();
}

class _RentFarmerBookingsPageState extends State<RentFarmerBookingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _farmerId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_farmerId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your bookings')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E1F00),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Bookings',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            Text('Track your machine requests',
                style: TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFF9800),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: StreamBuilder<List<RentBooking>>(
        stream: RentMachineService.instance.streamBookingsByFarmer(_farmerId),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final active = all.where((b) => _isActive(b.status)).toList();
          final history = all
              .where((b) => !_isActive(b.status))
              .toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _BookingList(
                bookings: active,
                emptyIcon: '🕐',
                emptyTitle: 'No active bookings',
                emptySubtitle: 'Your pending and ongoing bookings appear here',
              ),
              _BookingList(
                bookings: history,
                emptyIcon: '📋',
                emptyTitle: 'No history yet',
                emptySubtitle: 'Completed and rejected bookings appear here',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<RentBooking> bookings;
  final String emptyIcon, emptyTitle, emptySubtitle;

  const _BookingList({
    required this.bookings,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emptyIcon, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(emptyTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E))),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final RentBooking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final color = _statusColor(b.status);
    final active = _isActive(b.status);

    return GestureDetector(
      onTap: active
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => RentTrackingPage(bookingId: b.id)),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.4)
                  : const Color(0xFFE0E0E0),
              width: active ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(children: [
          // ── Status header ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
            ),
            child: Row(children: [
              Text(_statusEmoji(b.status),
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.status.label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: color)),
                      Text(b.machineName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF616161))),
                    ]),
              ),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Track →',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
            ]),
          ),

          // ── Details ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Machine type icon
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(_machineEmoji(b.machineType),
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${b.hours} hr • ${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242))),
                      if (b.fieldLocation.isNotEmpty)
                        Text(b.fieldLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E))),
                      Text('Owner: ${b.ownerName}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E))),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${b.totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32))),
                Text('total',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9E9E9E))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _machineEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'tractor':    return '🚜';
      case 'harvester':  return '🌾';
      case 'rotavator':  return '⚙️';
      case 'cultivator': return '🌿';
      case 'seeder':     return '🌱';
      case 'hitachi':    return '⛏️';
      case 'jcb':        return '🏗️';
      case 'lorry':      return '🚚';
      default:           return '🔧';
    }
  }
}
