import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'job_post_model.dart';
import 'location_search_dialog.dart';

const _kP1 = Color(0xFF1B5E20);
const _kP2 = Color(0xFF2E7D32);
const _kLightGreen = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kDark = Color(0xFF1A2D1A);

class JobPostFormPage extends StatefulWidget {
  final LabourProfile? prefilledWorker;

  const JobPostFormPage({super.key, this.prefilledWorker});

  @override
  State<JobPostFormPage> createState() => _JobPostFormPageState();
}

class _JobPostFormPageState extends State<JobPostFormPage> {
  final _form = GlobalKey<FormState>();
  final _service = LabourHubService();
  bool _submitting = false;
  bool _locating = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _workersCtrl = TextEditingController(text: '1');
  final _wageCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController(text: '8 AM – 5 PM');

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  double _lat = 0, _lon = 0;

  final Set<String> _requiredSkills = {};
  bool _foodIncluded = false;
  bool _accommodationIncluded = false;
  List<String> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledWorker != null) {
      final w = widget.prefilledWorker!;
      if (w.skills.isNotEmpty) _requiredSkills.add(w.skills.first);
    }
    _loadRecentLocations();
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final saved = prefs.getStringList('recent_locations_$uid') ?? [];
    if (mounted) setState(() => _recentLocations = saved);
  }

  Future<void> _saveRecentLocation(String loc) async {
    if (loc.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final key = 'recent_locations_$uid';
    final list = prefs.getStringList(key) ?? [];
    list.remove(loc);
    list.insert(0, loc);
    await prefs.setStringList(key, list.take(10).toList());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _workersCtrl.dispose();
    _wageCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime.now() : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kP2, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _getGPS() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Location permission denied', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      final places =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (places.isNotEmpty && mounted) {
        final pl = places.first;
        final loc = [
          pl.subLocality,
          pl.locality,
          pl.administrativeArea
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _locationCtrl.text = loc;
        });
      }
    } catch (_) {
      _snack('Could not get location', isError: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_requiredSkills.isEmpty) {
      _snack('Select at least one required skill', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final job = JobPost(
        id: '',
        farmerId: user.uid,
        farmerName: user.displayName ?? 'Farmer',
        farmerPhone: user.phoneNumber ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        requiredSkills: _requiredSkills.toList(),
        location: _locationCtrl.text.trim(),
        latitude: _lat,
        longitude: _lon,
        startDate: _startDate,
        endDate: _endDate,
        workersRequired: int.tryParse(_workersCtrl.text) ?? 1,
        dailyWage: double.tryParse(_wageCtrl.text) ?? 0,
        workingHours: _hoursCtrl.text.trim(),
        foodIncluded: _foodIncluded,
        accommodationIncluded: _accommodationIncluded,
        createdAt: DateTime.now(),
      );
      await _service.postJob(job);
      await _saveRecentLocation(_locationCtrl.text.trim());
      if (mounted) {
        _snack('Job posted successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('Failed to post job: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : _kP2,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: Form(
        key: _form,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kP1, _kP2, Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 16, 24),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Post a Job',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('Find skilled workers for your farm',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ── Job Details ──────────────────────────────────────────────────
            _SCard(
              child: _buildSection('Job Details', Icons.work_outline_rounded, [
                _field('Job Title', _titleCtrl,
                    hint: 'e.g. Paddy Harvesting Workers Needed',
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Title is required' : null),
                _field('Description (optional)', _descCtrl,
                    hint: 'Describe the work, requirements, etc.',
                    maxLines: 3),
              ]),
            ),

            // ── Required Skills ──────────────────────────────────────────────
            _SCard(
              child: _buildSection(
                  'Required Skills', Icons.handyman_rounded, [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kLabourSkills.map((s) {
                    final sel = _requiredSkills.contains(s);
                    return FilterChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      selectedColor: _kP2,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : _kDark),
                      onSelected: (v) => setState(() {
                        v
                            ? _requiredSkills.add(s)
                            : _requiredSkills.remove(s);
                      }),
                    );
                  }).toList(),
                ),
              ]),
            ),

            // ── Location ────────────────────────────────────────────────────
            _SCard(
              child: _buildSection('Job Location', Icons.location_on_rounded, [
                _LocationPickerField(
                  controller: _locationCtrl,
                  recentLocations: _recentLocations,
                  onPicked: (lat, lon) {
                    setState(() {
                      _lat = lat;
                      _lon = lon;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _getGPS,
                    icon: _locating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kP2))
                        : const Icon(Icons.my_location_rounded, color: _kP2),
                    label: Text(_locating ? 'Getting GPS…' : 'Use Current GPS'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _kP2,
                        side: const BorderSide(color: _kP2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ]),
            ),

            // ── Dates ────────────────────────────────────────────────────────
            _SCard(
              child: _buildSection('Work Duration', Icons.date_range_rounded, [
                Row(children: [
                  Expanded(
                    child: _DatePicker(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePicker(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: _kLightGreen,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Duration: ${_endDate.difference(_startDate).inDays + 1} days',
                    style: const TextStyle(
                        color: _kP2, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),

            // ── Workers & Wage ───────────────────────────────────────────────
            _SCard(
              child: _buildSection(
                  'Workers & Wage', Icons.people_rounded, [
                Row(children: [
                  Expanded(
                    child: _field('No. of Workers', _workersCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Daily Wage (₹)', _wageCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null),
                  ),
                ]),
                _field('Working Hours', _hoursCtrl,
                    hint: 'e.g. 8 AM – 5 PM'),
              ]),
            ),

            // ── Benefits ─────────────────────────────────────────────────────
            _SCard(
              child: _buildSection('Benefits Provided', Icons.redeem_rounded, [
                SwitchListTile(
                  value: _foodIncluded,
                  onChanged: (v) => setState(() => _foodIncluded = v),
                  activeColor: _kP2,
                  title: const Text('🍱  Food Included'),
                  subtitle: const Text('Meals provided during work',
                      style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _accommodationIncluded,
                  onChanged: (v) =>
                      setState(() => _accommodationIncluded = v),
                  activeColor: _kP2,
                  title: const Text('🏠  Accommodation Included'),
                  subtitle: const Text('Staying arrangements provided',
                      style: TextStyle(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                ),
              ]),
            ),

            // ── Submit ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.post_add_rounded),
                  label: Text(_submitting ? 'Posting…' : 'Post Job',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: _kP2),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _kDark)),
      ]),
      const SizedBox(height: 16),
      ...children,
    ]);
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboardType,
      String? hint,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8FDF8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kP2, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

// ── Location picker field ─────────────────────────────────────────────────────

class _LocationPickerField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> recentLocations;
  final void Function(double lat, double lon) onPicked;

  const _LocationPickerField({
    required this.controller,
    required this.recentLocations,
    required this.onPicked,
  });

  Future<void> _open(BuildContext ctx) async {
    final result = await showDialog<LocationResult>(
      context: ctx,
      builder: (_) =>
          LocationSearchDialog(recentLocations: recentLocations),
    );
    if (result != null) {
      controller.text = result.displayName;
      onPicked(result.lat, result.lon);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) =>
          controller.text.trim().isEmpty ? 'Location is required' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _open(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FDF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.hasError
                      ? Colors.red
                      : controller.text.isNotEmpty
                          ? _kP2
                          : Colors.grey.shade300,
                  width: controller.text.isNotEmpty ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.location_on_rounded,
                    color: controller.text.isNotEmpty
                        ? _kP2
                        : Colors.grey.shade400,
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : 'Tap to search location…',
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isNotEmpty
                          ? _kDark
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.search_rounded,
                    color: Colors.grey.shade400, size: 20),
              ]),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 14),
              child: Text(state.errorText!,
                  style:
                      const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePicker(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FDF8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: _kP2),
            const SizedBox(width: 6),
            Text(
                '${date.day}/${date.month}/${date.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }
}

class _SCard extends StatelessWidget {
  final Widget child;

  const _SCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      ),
    );
  }
}
