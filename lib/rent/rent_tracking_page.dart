// lib/rent/rent_tracking_page.dart — RentHub 3.0 Live Tracking
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rent_booking_model.dart';
import 'rent_machine_service.dart';
import 'rent_farmer_bookings_page.dart';

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
    case BookingStatus.onTheWay:   return '🚚';
    case BookingStatus.arrived:    return '📍';
    case BookingStatus.working:    return '⚙️';
    case BookingStatus.completed:  return '🎉';
    case BookingStatus.rejected:   return '❌';
  }
}

String _typeEmoji(String type) {
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

class RentTrackingPage extends StatefulWidget {
  final String bookingId;
  const RentTrackingPage({super.key, required this.bookingId});

  @override
  State<RentTrackingPage> createState() => _RentTrackingPageState();
}

class _RentTrackingPageState extends State<RentTrackingPage> {
  final _mapCtrl = MapController();

  void _goToMyBookings(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RentFarmerBookingsPage()),
      (route) => route.isFirst,
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp(String phone) async {
    final p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('https://wa.me/$p');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RentBooking?>(
      stream: RentMachineService.instance.streamBookingById(widget.bookingId),
      builder: (ctx, snap) {
        if (!snap.hasData && !snap.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final booking = snap.data;

        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            body: const Center(child: Text('Booking not found')),
          );
        }

        final status = booking.status;
        final color = _statusColor(status);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Map markers
        final markers = <Marker>[];
        if (booking.machineLatitude != null && booking.machineLongitude != null) {
          markers.add(Marker(
            point: LatLng(
                booking.machineLatitude!, booking.machineLongitude!),
            width: 44,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.4), blurRadius: 8)
                ],
              ),
              child: Center(
                child: Text(_typeEmoji(booking.machineType),
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
          ));
        }
        if (booking.fieldLatitude != null && booking.fieldLongitude != null) {
          markers.add(Marker(
            point: LatLng(booking.fieldLatitude!, booking.fieldLongitude!),
            width: 36,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.home_rounded, color: Colors.white, size: 18),
              ),
            ),
          ));
        }

        final mapCenter = booking.machineLatitude != null
            ? LatLng(booking.machineLatitude!, booking.machineLongitude!)
            : booking.fieldLatitude != null
                ? LatLng(booking.fieldLatitude!, booking.fieldLongitude!)
                : const LatLng(13.3379, 76.5616);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goToMyBookings(context);
          },
          child: Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => _goToMyBookings(context),
            ),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Live Tracking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Booking #${widget.bookingId.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
            actions: [
              TextButton.icon(
                onPressed: () => _goToMyBookings(context),
                icon: const Icon(Icons.list_alt_rounded,
                    color: Colors.white, size: 18),
                label: const Text('My Bookings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          body: Column(children: [
            // ── Status banner ──────────────────────────────────
            Container(
              color: color.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Text(_statusEmoji(status),
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status.label,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: color)),
                        Text(_statusSubtitle(status, booking),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF616161))),
                      ]),
                ),
                if (status == BookingStatus.rejected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('REJECTED',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),

            // ── Status timeline ────────────────────────────────
            if (status != BookingStatus.rejected)
              _StatusTimeline(currentStatus: status),

            // ── Map ────────────────────────────────────────────
            Expanded(
              child: Stack(children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.krishimithra.app',
                    ),
                    if (markers.isNotEmpty) MarkerLayer(markers: markers),
                  ],
                ),
                // Map legend
                Positioned(
                  top: 12, right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MapLegendChip(
                          color: color,
                          label: '${_typeEmoji(booking.machineType)} Machine'),
                      const SizedBox(height: 6),
                      const _MapLegendChip(
                          color: Color(0xFF4CAF50),
                          label: '🏠 Your Field'),
                    ],
                  ),
                ),
              ]),
            ),

            // ── Machine + owner info ───────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -3))
                ],
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.12),
                    ),
                    child: Center(
                        child: Text(_typeEmoji(booking.machineType),
                            style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.machineName,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          Text(booking.ownerName,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9E9E9E))),
                        ]),
                  ),
                  // Cost
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${booking.totalCost.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: color)),
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF9E9E9E))),
                  ]),
                ]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Booking details
                Row(children: [
                  _BookingDetail(Icons.access_time_rounded,
                      '${booking.hours} hr${booking.hours > 1 ? 's' : ''}'),
                  _BookingDetail(Icons.calendar_today_rounded,
                      '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}'),
                  if (booking.fieldLocation.isNotEmpty)
                    Expanded(
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(booking.fieldLocation,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Color(0xFF616161)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),
                ]),
                const SizedBox(height: 12),
                // Action buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(booking.ownerPhone),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Call Owner',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color),
                          foregroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _whatsApp(booking.ownerPhone),
                      icon: const Text('📱', style: TextStyle(fontSize: 14)),
                      label: const Text('WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ]),
              ]),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ]),
        ),   // closes Scaffold
        );   // closes PopScope
      },
    );
  }

  String _statusSubtitle(BookingStatus s, RentBooking b) {
    switch (s) {
      case BookingStatus.requested:
          return 'Waiting for ${b.ownerName} to accept';
      case BookingStatus.accepted:
          return 'Booking confirmed! Machine will arrive soon';
      case BookingStatus.onTheWay:
          return 'Machine is on the way to your field';
      case BookingStatus.arrived:
          return 'Machine has arrived at your field';
      case BookingStatus.working:
          return 'Machine is currently working on your field';
      case BookingStatus.completed:
          return 'Work completed successfully!';
      case BookingStatus.rejected:
          return 'Owner could not accept this booking';
    }
  }
}

// ─── Status timeline ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final BookingStatus currentStatus;
  const _StatusTimeline({required this.currentStatus});

  static const _steps = [
    BookingStatus.requested,
    BookingStatus.accepted,
    BookingStatus.onTheWay,
    BookingStatus.arrived,
    BookingStatus.working,
    BookingStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final current = currentStatus.step;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final done = stepIdx < current;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: done
                    ? _statusColor(_steps[stepIdx])
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = _steps[stepIdx];
        final done = stepIdx < current;
        final active = stepIdx == current;
        final stColor = _statusColor(step);

        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? stColor : const Color(0xFFE0E0E0),
              border: active
                  ? Border.all(color: stColor, width: 2)
                  : null,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : Text(step.label[0],
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : const Color(0xFF9E9E9E))),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 40,
            child: Text(step.label,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: active ? stColor : const Color(0xFF9E9E9E)),
                textAlign: TextAlign.center),
          ),
        ]);
      })),
    );
  }
}

class _MapLegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _MapLegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _BookingDetail extends StatelessWidget {
  final IconData icon;
  final String value;
  const _BookingDetail(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
