// lib/rent/rent_booking_flow_page.dart — RentHub 3.0 Booking Wizard
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'rent_model.dart';
import 'rent_booking_model.dart';
import 'rent_machine_service.dart';
import 'rent_tracking_page.dart';

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

class RentBookingFlowPage extends StatefulWidget {
  final RentMachine machine;
  final double? distanceKm;
  final String? initialNotes;

  const RentBookingFlowPage({
    super.key,
    required this.machine,
    this.distanceKm,
    this.initialNotes,
  });

  @override
  State<RentBookingFlowPage> createState() => _RentBookingFlowPageState();
}

class _RentBookingFlowPageState extends State<RentBookingFlowPage>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  int _hours = 4;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _fieldLocation = '';
  double? _fieldLat, _fieldLon;
  String _notes = '';
  bool _submitting = false;
  Position? _position;

  final _locationIQKey = 'pk.56ccd9d8fb2cd5f3e9d7a656e3b52566';
  final _notesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _notes = widget.initialNotes ?? '';
    _notesCtrl.text = _notes;
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
    _fetchLocation();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      if (mounted) setState(() => _position = pos);
    } catch (_) {}
  }

  double get _machineCharge {
    return widget.machine.effectiveHourlyRate * _hours;
  }

  double get _travelCharge {
    final dist = widget.distanceKm ?? 0;
    return (200 + dist * 25).roundToDouble();
  }

  double get _totalCost => _machineCharge + _travelCharge;

  void _nextStep() {
    if (_step == 2 && _date.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future date')));
      return;
    }
    if (_step == 3 && _fieldLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your field location')));
      return;
    }
    if (_step < 4) {
      _animCtrl.reset();
      setState(() => _step++);
      _animCtrl.forward();
    } else {
      _submitBooking();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      _animCtrl.reset();
      setState(() => _step--);
      _animCtrl.forward();
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final booking = RentBooking(
        id: '',
        machineId: widget.machine.id,
        machineName: widget.machine.name,
        machineType: widget.machine.type,
        machineImageUrl: widget.machine.imageUrl.isNotEmpty
            ? widget.machine.imageUrl
            : null,
        farmerId: user?.uid ?? '',
        farmerName: user?.displayName ?? user?.email ?? 'Farmer',
        ownerId: widget.machine.ownerId,
        ownerName: widget.machine.ownerName,
        ownerPhone: widget.machine.phone,
        hours: _hours,
        bookingDate: _date,
        fieldLatitude: _fieldLat ?? _position?.latitude,
        fieldLongitude: _fieldLon ?? _position?.longitude,
        fieldLocation: _fieldLocation,
        machineCharge: _machineCharge,
        travelCharge: _travelCharge,
        totalCost: _totalCost,
        status: BookingStatus.requested,
        notes: _notes.isNotEmpty ? _notes : null,
        createdAt: DateTime.now(),
        machineLatitude: widget.machine.latitude != 0
            ? widget.machine.latitude
            : null,
        machineLongitude: widget.machine.longitude != 0
            ? widget.machine.longitude
            : null,
      );

      final bookingId =
          await RentMachineService.instance.createBooking(booking);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => RentTrackingPage(bookingId: bookingId)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }

  Future<void> _openLocationSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        List<dynamic> results = [];
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Set Field Location'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search your village/area...'),
                  onChanged: (val) async {
                    if (val.length < 3) return;
                    final url =
                        'https://us1.locationiq.com/v1/search.php?key=$_locationIQKey&q=$val&format=json';
                    try {
                      final res = await http.get(Uri.parse(url));
                      if (res.statusCode == 200) {
                        setS(() => results = json.decode(res.body));
                      }
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(r['display_name'],
                            style: const TextStyle(fontSize: 13)),
                        onTap: () => Navigator.pop(ctx, {
                          'name': r['display_name'],
                          'lat': double.tryParse(r['lat'] ?? '0') ?? 0,
                          'lon': double.tryParse(r['lon'] ?? '0') ?? 0,
                        }),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _fieldLocation = result['name'];
        _fieldLat = result['lat'];
        _fieldLon = result['lon'];
        _locationCtrl.text = _fieldLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(widget.machine.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Book ${widget.machine.name}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _step == 0 ? () => Navigator.pop(context) : _prevStep,
        ),
      ),
      body: Column(children: [
        // ── Step indicator ─────────────────────────────────────
        _StepIndicator(step: _step, color: color),
        // ── Step content ───────────────────────────────────────
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: _buildStepContent(color, isDark),
            ),
          ),
        ),
        // ── Bottom action ──────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3))
            ],
          ),
          child: Row(children: [
            if (_step > 0) ...[
              OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color),
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _submitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _step == 4
                            ? 'Confirm Booking'
                            : 'Next  →',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStepContent(Color color, bool isDark) {
    switch (_step) {
      case 0: return _buildStep1Machine(color, isDark);
      case 1: return _buildStep2Hours(color, isDark);
      case 2: return _buildStep3Date(color, isDark);
      case 3: return _buildStep4Location(color, isDark);
      case 4: return _buildStep5Confirm(color, isDark);
      default: return const SizedBox.shrink();
    }
  }

  // Step 1 — Machine overview
  Widget _buildStep1Machine(Color color, bool isDark) {
    final m = widget.machine;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Selected Machine',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Review the machine details before proceeding',
          style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07), blurRadius: 10)
          ],
        ),
        child: Row(children: [
          // Image / placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 80,
              height: 80,
              child: m.imageUrl.isNotEmpty
                  ? Image.network(m.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: color.withValues(alpha: 0.15),
                            child: Center(
                                child: Text(_typeEmoji(m.type),
                                    style: const TextStyle(fontSize: 36))),
                          ))
                  : Container(
                      color: color.withValues(alpha: 0.15),
                      child: Center(
                          child: Text(_typeEmoji(m.type),
                              style: const TextStyle(fontSize: 36))),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${_typeEmoji(m.type)} ${m.type}',
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                const SizedBox(width: 2),
                Text(m.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('${m.completedJobs} jobs',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              ]),
              const SizedBox(height: 6),
              Text('₹${m.effectiveHourlyRate.toStringAsFixed(0)}/hr',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      _InfoChip(
          '👤 Owner', m.ownerName, const Color(0xFF1565C0)),
      if (m.location != null && m.location!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _InfoChip('📍 Location', m.location!, const Color(0xFF388E3C)),
        ),
    ]);
  }

  // Step 2 — Choose hours
  Widget _buildStep2Hours(Color color, bool isDark) {
    final rate = widget.machine.effectiveHourlyRate;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('How many hours?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Select the number of hours you need the machine',
          style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 32),
      // Big hours display
      Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 3),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_hours',
                    style: TextStyle(
                        fontSize: 52, fontWeight: FontWeight.w900, color: color)),
                Text('hour${_hours > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      ),
      const SizedBox(height: 24),
      // Slider
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color,
          thumbColor: color,
          inactiveTrackColor: color.withValues(alpha: 0.2),
          overlayColor: color.withValues(alpha: 0.1),
        ),
        child: Slider(
          value: _hours.toDouble(),
          min: 1,
          max: 24,
          divisions: 23,
          label: '$_hours hr',
          onChanged: (v) => setState(() => _hours = v.round()),
        ),
      ),
      Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('1 hr', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            Text('24 hr', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
          ]),
      const SizedBox(height: 24),
      // Quick select
      Row(children: [2, 4, 6, 8, 12].map((h) {
        final sel = _hours == h;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => setState(() => _hours = h),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: sel ? color : const Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Text('${h}hr',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: sel ? Colors.white : const Color(0xFF616161))),
                ),
              ),
            ),
          ),
        );
      }).toList()),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Machine Charge',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('₹${(rate * _hours).toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    ]);
  }

  // Step 3 — Choose date
  Widget _buildStep3Date(Color color, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('When do you need it?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Select the date for the booking',
          style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 24),
      // Calendar
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07), blurRadius: 10)
          ],
        ),
        child: CalendarDatePicker(
          initialDate: _date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          onDateChanged: (d) => setState(() => _date = d),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF90CAF9)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              color: Color(0xFF1565C0), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                'Selected: ${_date.day}/${_date.month}/${_date.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0))),
          ),
        ]),
      ),
    ]);
  }

  // Step 4 — Field location
  Widget _buildStep4Location(Color color, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Where is your field?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Enter the location where the machine should come',
          style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 24),
      // Search field
      GestureDetector(
        onTap: _openLocationSearch,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _fieldLocation.isNotEmpty
                    ? color
                    : const Color(0xFFE0E0E0),
                width: _fieldLocation.isNotEmpty ? 2 : 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8)
            ],
          ),
          child: Row(children: [
            Icon(Icons.location_on_rounded,
                color: _fieldLocation.isNotEmpty ? color : const Color(0xFF9E9E9E),
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _fieldLocation.isNotEmpty
                    ? _fieldLocation
                    : 'Search your village, taluk, or landmark...',
                style: TextStyle(
                    fontSize: 13.5,
                    color: _fieldLocation.isNotEmpty
                        ? (isDark ? Colors.white : const Color(0xFF212121))
                        : const Color(0xFF9E9E9E)),
                maxLines: 2,
              ),
            ),
            Icon(Icons.search_rounded,
                color: color.withValues(alpha: 0.6)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      // GPS option
      GestureDetector(
        onTap: () async {
          if (_position != null) {
            setState(() {
              _fieldLat = _position!.latitude;
              _fieldLon = _position!.longitude;
              _fieldLocation =
                  'GPS: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
              _locationCtrl.text = _fieldLocation;
            });
          } else {
            await _fetchLocation();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child: Row(children: [
            const Icon(Icons.my_location_rounded,
                color: Color(0xFF1565C0), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Use my current GPS location',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1565C0))),
                if (_position != null)
                  Text(
                      '${_position!.latitude.toStringAsFixed(4)}, '
                      '${_position!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
              ]),
            ),
            if (_position != null)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 20),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      // Notes
      TextField(
        controller: _notesCtrl,
        maxLines: 3,
        onChanged: (v) => _notes = v,
        decoration: InputDecoration(
          hintText: 'Additional notes (e.g. need before 8 AM, field is muddy...)',
          hintStyle: const TextStyle(fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          prefixIcon: const Icon(Icons.note_alt_outlined),
          labelText: 'Booking Notes (optional)',
        ),
      ),
    ]);
  }

  // Step 5 — Confirm booking
  Widget _buildStep5Confirm(Color color, bool isDark) {
    final m = widget.machine;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Confirm Booking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Review your booking details before confirming',
          style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 20),
      // Machine summary
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07), blurRadius: 10)
          ],
        ),
        child: Column(children: [
          _ConfirmRow('Machine', '${_typeEmoji(m.type)} ${m.name}'),
          _ConfirmRow('Type', m.type),
          _ConfirmRow('Owner', m.ownerName),
          _ConfirmRow('Duration', '$_hours hour${_hours > 1 ? 's' : ''}'),
          _ConfirmRow('Date',
              '${_date.day}/${_date.month}/${_date.year}'),
          _ConfirmRow('Field Location',
              _fieldLocation.isNotEmpty ? _fieldLocation : 'Not set'),
          if (_notes.isNotEmpty) _ConfirmRow('Notes', _notes),
        ]),
      ),
      const SizedBox(height: 16),
      // Cost breakdown
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07), blurRadius: 10)
          ],
        ),
        child: Column(children: [
          const Row(children: [
            Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF9E9E9E)),
            SizedBox(width: 8),
            Text('Cost Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 14),
          _CostRow('Machine Charge',
              '₹${_machineCharge.toStringAsFixed(0)}',
              sub: '${m.effectiveHourlyRate.toStringAsFixed(0)} × $_hours hr'),
          const SizedBox(height: 8),
          _CostRow('Travel Charge',
              '₹${_travelCharge.toStringAsFixed(0)}',
              sub: widget.distanceKm != null
                  ? '₹200 base + ${widget.distanceKm!.toStringAsFixed(1)} km'
                  : '₹200 base charge'),
          const Divider(height: 20),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                Text('₹${_totalCost.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color)),
              ]),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC02)),
        ),
        child: const Row(children: [
          Text('ℹ️', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
                'Payment will be collected in cash after the work is completed.',
                style: TextStyle(fontSize: 12, color: Color(0xFF795548))),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  final Color color;
  const _StepIndicator({required this.step, required this.color});

  static const _labels = ['Machine', 'Hours', 'Date', 'Location', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: List.generate(5, (i) {
        final done = i < step;
        final active = i == step;
        return Expanded(
          child: Row(children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active
                      ? color
                      : const Color(0xFFE0E0E0),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : const Color(0xFF9E9E9E))),
                ),
              ),
              const SizedBox(height: 4),
              Text(_labels[i],
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: active ? color : const Color(0xFF9E9E9E))),
            ]),
            if (i < 4)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i < step ? color : const Color(0xFFE0E0E0),
                ),
              ),
          ]),
        );
      })),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 2),
        ),
      ]),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label, value;
  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF9E9E9E))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label, value;
  final String? sub;
  const _CostRow(this.label, this.value, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            if (sub != null)
              Text(sub!,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E))),
          ]),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
