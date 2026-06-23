// lib/rent/rent_map_page.dart — RentHub 3.0 Full-Screen Map
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rent_model.dart';
import 'rent_machine_details_page.dart';
import 'rent_booking_flow_page.dart';

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'tractor':    return const Color(0xFFE65100);
    case 'harvester':  return const Color(0xFF1B5E20);
    case 'rotavator':  return const Color(0xFF4CAF50);
    case 'cultivator': return const Color(0xFF2E7D32);
    case 'seeder':     return const Color(0xFF00695C);
    case 'hitachi':    return const Color(0xFFFF8F00);
    case 'jcb':        return const Color(0xFFF9A825);
    case 'lorry':      return const Color(0xFF1565C0);
    default:           return const Color(0xFF455A64);
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

Color _availColor(MachineAvailability a) {
  switch (a) {
    case MachineAvailability.available:        return const Color(0xFF4CAF50);
    case MachineAvailability.busy:             return const Color(0xFFFF9800);
    case MachineAvailability.underMaintenance: return const Color(0xFFFF5722);
    case MachineAvailability.offline:          return const Color(0xFF9E9E9E);
  }
}

class RentMapPage extends StatefulWidget {
  final List<RentMachine> machines;
  final double? userLat;
  final double? userLon;

  const RentMapPage({
    super.key,
    required this.machines,
    this.userLat,
    this.userLon,
  });

  @override
  State<RentMapPage> createState() => _RentMapPageState();
}

class _RentMapPageState extends State<RentMapPage> {
  final _mapCtrl = MapController();
  RentMachine? _selected;
  String _filterType = 'All';

  static const _kCats = [
    'All', 'Tractor', 'Harvester', 'Rotavator',
    'Cultivator', 'Seeder', 'Hitachi', 'JCB', 'Lorry',
  ];

  List<RentMachine> get _filtered {
    return widget.machines.where((m) {
      if (m.availability == MachineAvailability.offline) return false;
      if (_filterType != 'All' &&
          m.type.toLowerCase() != _filterType.toLowerCase()) return false;
      return true;
    }).toList();
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _focusMachine(RentMachine m) {
    if (m.latitude != 0) {
      _mapCtrl.move(LatLng(m.latitude, m.longitude), 15.0);
    }
    setState(() => _selected = m);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    final mapCenter = widget.userLat != null
        ? LatLng(widget.userLat!, widget.userLon!)
        : filtered.isNotEmpty && filtered.first.latitude != 0
            ? LatLng(filtered.first.latitude, filtered.first.longitude)
            : const LatLng(13.3379, 76.5616);

    // Build markers
    final markers = <Marker>[];

    // User location
    if (widget.userLat != null) {
      markers.add(Marker(
        point: LatLng(widget.userLat!, widget.userLon!),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                      blurRadius: 8)
                ],
              ),
            ),
          ),
        ),
      ));
    }

    // Machine markers
    for (final m in filtered) {
      if (m.latitude == 0) continue;
      final isSelected = _selected?.id == m.id;
      final color = _typeColor(m.type);

      markers.add(Marker(
        point: LatLng(m.latitude, m.longitude),
        width: isSelected ? 56 : 44,
        height: isSelected ? 56 : 44,
        child: GestureDetector(
          onTap: () => _focusMachine(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: m.availability == MachineAvailability.available
                  ? color.withValues(alpha: 0.95)
                  : const Color(0xFF9E9E9E).withValues(alpha: 0.95),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white, width: isSelected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(
                        alpha: isSelected ? 0.6 : 0.35),
                    blurRadius: isSelected ? 14 : 8)
              ],
            ),
            child: Center(
              child: Text(_typeEmoji(m.type),
                  style: TextStyle(
                      fontSize: isSelected ? 26 : 20)),
            ),
          ),
        ),
      ));
    }

    return Scaffold(
      body: Stack(children: [
        // ── Map ─────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: 12.0,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.krishimithra.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // ── Top overlay ─────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Column(children: [
            // Back + title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12)
                ],
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nearby Machines',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        Text('Tap a marker to view details',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF9E9E9E))),
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${filtered.length} shown',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100))),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Category filter
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _kCats.length,
                itemBuilder: (_, i) {
                  final cat = _kCats[i];
                  final sel = _filterType == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filterType = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFE65100)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6)
                        ],
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF616161))),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        // ── Machine detail bottom sheet ──────────────────────────
        if (_selected != null)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: _MachineBottomCard(
              machine: _selected!,
              onDismiss: () => setState(() => _selected = null),
              onCall: () => _call(_selected!.phone),
              onDetails: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RentMachineDetailsPage(machine: _selected!))),
              onBook: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RentBookingFlowPage(machine: _selected!))),
            ),
          ),

        // ── Re-center button ─────────────────────────────────────
        if (widget.userLat != null)
          Positioned(
            bottom: (_selected != null ? 180 : 24) +
                MediaQuery.of(context).padding.bottom,
            right: 16,
            child: GestureDetector(
              onTap: () => _mapCtrl.move(
                  LatLng(widget.userLat!, widget.userLon!), 13.0),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8)
                  ],
                ),
                child: const Icon(Icons.my_location_rounded,
                    color: Color(0xFF1565C0)),
              ),
            ),
          ),
      ]),
    );
  }
}

// ─── Machine bottom card ──────────────────────────────────────────────────────

class _MachineBottomCard extends StatelessWidget {
  final RentMachine machine;
  final VoidCallback onDismiss, onCall, onDetails, onBook;

  const _MachineBottomCard({
    required this.machine,
    required this.onDismiss,
    required this.onCall,
    required this.onDetails,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(machine.type);
    final emoji = _typeEmoji(machine.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(children: [
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70, height: 70,
                  child: machine.imageUrl.isNotEmpty
                      ? Image.network(machine.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                color: color.withValues(alpha: 0.15),
                                child: Center(
                                    child: Text(emoji,
                                        style: const TextStyle(
                                            fontSize: 30)))))
                      : Container(
                          color: color.withValues(alpha: 0.15),
                          child: Center(
                              child: Text(emoji,
                                  style:
                                      const TextStyle(fontSize: 30)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(machine.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('$emoji ${machine.type}',
                          style: TextStyle(
                              fontSize: 12, color: color,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFC107)),
                        const SizedBox(width: 2),
                        Text(machine.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: _availColor(machine.availability),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 3),
                        Text(machine.availability.label,
                            style: TextStyle(
                                fontSize: 11,
                                color: _availColor(machine.availability),
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 3),
                      Text(
                          '₹${machine.effectiveHourlyRate.toStringAsFixed(0)}/hr  '
                          '₹${machine.pricePerDay.toStringAsFixed(0)}/day',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ]),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close_rounded,
                    size: 20, color: Color(0xFF9E9E9E)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_rounded, size: 15),
                  label: const Text('Call',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color),
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      foregroundColor: const Color(0xFF424242),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Details',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: machine.availability ==
                          MachineAvailability.available
                      ? onBook
                      : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Book Now →',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
