// lib/rent/rent_machine_details_page.dart — RentHub 3.0 Premium Details
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rent_model.dart';
import 'rent_machine_service.dart';
import 'rent_booking_flow_page.dart';
import 'rent_list_form_page.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

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

// ─── Page ────────────────────────────────────────────────────────────────────

class RentMachineDetailsPage extends StatefulWidget {
  final RentMachine machine;
  const RentMachineDetailsPage({super.key, required this.machine});

  @override
  State<RentMachineDetailsPage> createState() => _RentMachineDetailsPageState();
}

class _RentMachineDetailsPageState extends State<RentMachineDetailsPage> {
  late RentMachine _machine;
  bool _updatingAvailability = false;

  @override
  void initState() {
    super.initState();
    _machine = widget.machine;
  }

  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty && uid == _machine.ownerId;
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _machine.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp() async {
    final phone = _machine.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps?q=${_machine.latitude},${_machine.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _updateAvailability(MachineAvailability avail) async {
    setState(() => _updatingAvailability = true);
    try {
      await RentMachineService.instance.updateAvailability(_machine.id, avail);
      setState(() => _machine = _machine.copyWith(availability: avail));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _updatingAvailability = false);
    }
  }

  void _showAvailabilitySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Set Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...MachineAvailability.values.map((a) {
            final sel = _machine.availability == a;
            final color = _availColor(a);
            return ListTile(
              leading: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              title: Text(a.label),
              trailing: sel ? Icon(Icons.check_rounded, color: color) : null,
              onTap: () {
                Navigator.pop(context);
                _updateAvailability(a);
              },
            );
          }),
        ]),
      ),
    );
  }

  void _showBookingNotesSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Add Booking Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Let the owner know your requirements',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. Need machine for 3 acres, prefer before 8 AM...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RentBookingFlowPage(
                              machine: _machine,
                              initialNotes: ctrl.text,
                            )));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor(_machine.type),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Proceed to Booking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(_machine.type);
    final emoji = _typeEmoji(_machine.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(slivers: [
        // ── Hero header ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: color,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isOwner) ...[
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RentListFormPage(existingMachine: _machine))),
              ),
              if (_updatingAvailability)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              else
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.toggle_on_rounded,
                        color: Colors.white, size: 18),
                  ),
                  onPressed: _showAvailabilitySheet,
                ),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              _machine.imageUrl.isNotEmpty
                  ? Image.network(_machine.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: color.withValues(alpha: 0.15),
                            child: Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 80))),
                          ))
                  : Container(
                      color: color.withValues(alpha: 0.15),
                      child: Center(
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 80))),
                    ),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54]))),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_machine.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('$emoji ${_machine.type}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: _availColor(_machine.availability),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(_machine.availability.label,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11)),
                          ]),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Text(
                          '₹${_machine.effectiveHourlyRate.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: color)),
                      const Text('/hour',
                          style: TextStyle(
                              fontSize: 9, color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // ── Content ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  if (_machine.badges.isNotEmpty) ...[
                    _buildBadges(),
                    const SizedBox(height: 16),
                  ],
                  _buildReliabilityCard(color),
                  const SizedBox(height: 16),
                  _buildOwnerCard(isDark),
                  const SizedBox(height: 16),
                  _buildDetailsCard(isDark),
                  const SizedBox(height: 16),
                  _buildPricingCard(color, isDark),
                  const SizedBox(height: 16),
                  _buildBookingNotesButton(color),
                ]),
          ),
        ),
      ]),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _call,
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: const Text('Call',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color, width: 1.5),
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _whatsApp,
              icon: const Text('📱', style: TextStyle(fontSize: 16)),
              label: const Text('WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  _machine.availability == MachineAvailability.available
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  RentBookingFlowPage(machine: _machine)))
                      : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('Book Now →',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      _StatChip('⭐', _machine.rating.toStringAsFixed(1), 'Rating'),
      const SizedBox(width: 12),
      _StatChip('📦', '${_machine.completedJobs}', 'Jobs Done'),
      const SizedBox(width: 12),
      _StatChip('🔧', '${_machine.yearsInService}yr', 'In Service'),
      const SizedBox(width: 12),
      _StatChip('✅',
          '${(_machine.acceptanceRate * 100).toStringAsFixed(0)}%', 'Accept Rate'),
    ]);
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _machine.badges.map((b) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFBC02D)),
          ),
          child: Text('${b.emoji}  ${b.label}',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF795548))),
        );
      }).toList(),
    );
  }

  Widget _buildReliabilityCard(Color color) {
    final score = _machine.reliabilityScore.clamp(0.0, 100.0);
    final scoreColor = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 60
            ? const Color(0xFFFF9800)
            : const Color(0xFFD32F2F);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        SizedBox(
          width: 68,
          height: 68,
          child: CustomPaint(
            painter: _ScoreArcPainter(score: score / 100, color: scoreColor),
            child: Center(
              child: Text('${score.toInt()}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: scoreColor)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Machine Reliability Score',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
                'Based on acceptance rate, on-time arrival & farmer feedback',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildOwnerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Owner Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _typeColor(_machine.type).withValues(alpha: 0.15),
            ),
            child: _machine.ownerPhotoUrl != null
                ? ClipOval(
                    child: Image.network(_machine.ownerPhotoUrl!,
                        fit: BoxFit.cover))
                : Center(
                    child: Text(
                        _machine.ownerName.isNotEmpty
                            ? _machine.ownerName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _typeColor(_machine.type)))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_machine.ownerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(_machine.phone,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
            ]),
          ),
          IconButton(
            onPressed: _openMaps,
            icon: const Icon(Icons.directions_rounded, color: Color(0xFF1565C0)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Machine Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _DetailRow(Icons.category_rounded, 'Type', _machine.type),
        if (_machine.location != null && _machine.location!.isNotEmpty)
          _DetailRow(Icons.location_on_outlined, 'Location', _machine.location!),
        _DetailRow(Icons.calendar_today_rounded, 'Listed',
            _formatDate(_machine.createdAt)),
        _DetailRow(Icons.build_rounded, 'Years In Service',
            '${_machine.yearsInService} years'),
      ]),
    );
  }

  Widget _buildPricingCard(Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text('₹${_machine.effectiveHourlyRate.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                const Text('/hour',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text('₹${_machine.pricePerDay.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: Color(0xFF424242))),
                const Text('/day',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCC02)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF57F17)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Travel charges (₹200 base + ₹25/km) will be added at booking',
                  style: TextStyle(fontSize: 11, color: Color(0xFF795548))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBookingNotesButton(Color color) {
    return GestureDetector(
      onTap: _showBookingNotesSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(children: [
          Icon(Icons.note_add_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Booking Notes',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              const Text('e.g. Need machine before 8 AM, 3 acres paddy field',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String icon, label, sub;
  const _StatChip(this.icon, this.label, this.sub);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Text(sub,
              style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF9E9E9E))),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

// ─── Score arc painter ────────────────────────────────────────────────────────

class _ScoreArcPainter extends CustomPainter {
  final double score;
  final Color color;
  const _ScoreArcPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.8, math.pi * 1.6, false,
        Paint()
          ..color = const Color(0xFFE0E0E0)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.8, math.pi * 1.6 * score, false,
        Paint()
          ..color = color
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.score != score || old.color != color;
}
