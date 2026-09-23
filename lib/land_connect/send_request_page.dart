import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'land_listing_model.dart';
import 'land_request_model.dart';
import 'land_connect_service.dart';
import 'land_connect_constants.dart';

const _kPrimary = Color(kLcPrimary);

class SendRequestPage extends StatefulWidget {
  final LandListing listing;
  const SendRequestPage({super.key, required this.listing});

  @override
  State<SendRequestPage> createState() => _SendRequestPageState();
}

class _SendRequestPageState extends State<SendRequestPage> {
  final _cropCtrl = TextEditingController();
  final _acresCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _arrangement = 'negotiable';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _arrangement = widget.listing.arrangementType;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _cropCtrl.dispose();
    _acresCtrl.dispose();
    _monthsCtrl.dispose();
    _amountCtrl.dispose();
    _msgCtrl.dispose();
    _expCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      _showErr('Please enter your phone number so the owner can contact you');
      return;
    }
    if (_cropCtrl.text.trim().isEmpty) {
      _showErr('Please enter the crop you want to grow');
      return;
    }
    final acres = double.tryParse(_acresCtrl.text);
    if (acres == null || acres <= 0) {
      _showErr('Please enter required acreage');
      return;
    }
    if (acres > widget.listing.availableAcres) {
      _showErr('Requested acreage exceeds available ${widget.listing.availableAcres} acres');
      return;
    }
    final months = int.tryParse(_monthsCtrl.text);
    if (months == null || months <= 0) {
      _showErr('Please enter cultivation duration in months');
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final request = LandRequest(
        id: '',
        listingId: widget.listing.id,
        cultivatorId: user.uid,
        cultivatorName: user.displayName ?? user.email ?? '',
        cultivatorPhone: _phoneCtrl.text.trim(),
        cultivatorExperience: int.tryParse(_expCtrl.text) ?? 0,
        ownerId: widget.listing.ownerId,
        ownerName: widget.listing.ownerName,
        ownerPhone: widget.listing.ownerPhone,
        landTitle: widget.listing.ownerName.isNotEmpty
            ? widget.listing.ownerName
            : widget.listing.title,
        landLocation: widget.listing.locationDisplay,
        cropName: _cropCtrl.text.trim(),
        requestedAcres: acres,
        durationMonths: months,
        proposedArrangement: _arrangement,
        proposedAmount: double.tryParse(_amountCtrl.text) ?? 0,
        message: _msgCtrl.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final err = await LandConnectService.sendRequest(request);
      if (!mounted) return;

      if (err == 'already_sent') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already have an active request for this land')));
      } else if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request sent successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send request: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showErr(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kPrimary,
        title: Text(loc.lcSendRequest,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Listing summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(kLcPrimary).withValues(alpha: 0.1),
                    const Color(kLcPrimary).withValues(alpha: 0.02)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(kLcPrimary).withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.ownerName.isNotEmpty ? l.ownerName : l.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('${l.locationDisplay} • ${l.availableAcres.toStringAsFixed(1)} acres available',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: 20),

          // Contact info
          _sectionLabel('Your Contact Details'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 14, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your phone number will be shared with the landowner when your request is accepted.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          _field('Your Phone Number *', _phoneCtrl,
              hint: '+91 98765 43210', phone: true),
          const SizedBox(height: 20),

          // Form fields
          _sectionLabel('Your Request'),
          const SizedBox(height: 10),

          _field('Crop You Want to Grow *', _cropCtrl,
              hint: 'e.g. Tomato, Rice, Cotton'),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _field('Required Acreage *', _acresCtrl,
                hint: '2.0', numeric: true)),
            const SizedBox(width: 12),
            Expanded(child: _field('Duration (months) *', _monthsCtrl,
                hint: '12', numeric: true, integer: true)),
          ]),
          const SizedBox(height: 12),

          _field('Your Experience (years)', _expCtrl,
              hint: '5', numeric: true, integer: true),
          const SizedBox(height: 16),

          _sectionLabel('Proposed Arrangement'),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _arrangement,
            onChanged: (v) => setState(() => _arrangement = v!),
            child: Column(
              children: kArrangements.map((arr) => RadioListTile<String>(
                value: arr,
                title: Text(kArrangementLabels[arr] ?? arr,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                activeColor: _kPrimary,
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),

          if (_arrangement == 'fixed_rent')
            _field('Proposed Amount (₹/year)', _amountCtrl,
                hint: '25000', numeric: true),

          const SizedBox(height: 12),
          _field('Message to Landowner (optional)', _msgCtrl,
              hint: 'Introduce yourself, your farming experience, plan...', maxLines: 4),
          const SizedBox(height: 20),

          // Summary preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: KMShadow.card,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Request Summary', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 16),
              _summaryRow('Land', l.ownerName.isNotEmpty ? l.ownerName : l.title),
              _summaryRow('Location', l.locationDisplay),
              _summaryRow('Crop', _cropCtrl.text.isNotEmpty ? _cropCtrl.text : '—'),
              _summaryRow('Acreage', _acresCtrl.text.isNotEmpty ? '${_acresCtrl.text} acres' : '—'),
              _summaryRow('Duration', _monthsCtrl.text.isNotEmpty ? '${_monthsCtrl.text} months' : '—'),
              _summaryRow('Arrangement', kArrangementLabels[_arrangement] ?? _arrangement),
            ]),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _send,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(loc.lcSubmitRequest, style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String t) =>
      Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));

  Widget _field(String label, TextEditingController ctrl,
      {String hint = '', int maxLines = 1, bool numeric = false, bool integer = false, bool phone = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: phone
            ? TextInputType.phone
            : numeric
                ? (integer
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true))
                : TextInputType.text,
        decoration: InputDecoration(hintText: hint),
        onChanged: (_) => setState(() {}),
      ),
    ]);
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
