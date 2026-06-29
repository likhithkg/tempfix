import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'labour_hub_service.dart';
import 'job_post_model.dart';
import 'job_application_model.dart';

const _kP1 = Color(0xFF1B5E20);
const _kP2 = Color(0xFF2E7D32);
const _kGreen = Color(0xFF4CAF50);
const _kLightGreen = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kAmber = Color(0xFFFFA000);
const _kDark = Color(0xFF1A2D1A);

class JobDetailPage extends StatefulWidget {
  final JobPost job;
  final LabourHubService service;

  const JobDetailPage({super.key, required this.job, required this.service});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool _hasApplied = false;
  bool _checking = true;
  bool _applying = false;
  late final Stream<List<JobApplication>> _applicationsStream;
  final _msgCtrl = TextEditingController();
  final _counterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkApplied();
    _applicationsStream = widget.service.streamJobApplications(widget.job.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkApplied() async {
    final applied = await widget.service.hasApplied(widget.job.id);
    if (mounted) setState(() { _hasApplied = applied; _checking = false; });
  }

  Future<void> _apply() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Please sign in to apply', isError: true);
      return;
    }
    final profile = await widget.service.getMyProfile();
    if (profile == null) {
      _snack('Create a labour profile first', isError: true);
      return;
    }
    setState(() => _applying = true);
    try {
      final counterText = _counterCtrl.text.trim();
      final app = JobApplication(
        id: '',
        jobId: widget.job.id,
        jobTitle: widget.job.title,
        labourId: user.uid,
        labourName: profile.name,
        labourPhone: profile.phone,
        labourPhotoUrl: profile.photoUrl,
        labourRating: profile.rating,
        labourSkills: profile.skills,
        farmerId: widget.job.farmerId,
        counterOffer: counterText.isNotEmpty
            ? double.tryParse(counterText)
            : null,
        message: _msgCtrl.text.trim(),
        appliedAt: DateTime.now(),
      );
      await widget.service.applyForJob(app);
      if (mounted) {
        setState(() => _hasApplied = true);
        Navigator.pop(context); // close sheet
        _snack('Application sent successfully!');
      }
    } catch (e) {
      _snack('Failed to apply: $e', isError: true);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _callFarmer() async {
    if (widget.job.farmerPhone.isEmpty) return;
    final uri = Uri.parse('tel:${widget.job.farmerPhone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _showApplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Apply for: ${widget.job.title}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Offered: ₹${widget.job.dailyWage.toStringAsFixed(0)}/day',
              style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _counterCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Counter Offer (₹/day) — optional',
              hintText: 'Leave blank to accept offered wage',
              prefixText: '₹ ',
              filled: true,
              fillColor: const Color(0xFFF8FDF8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message to farmer (optional)',
              hintText: 'Tell them about your experience…',
              filled: true,
              fillColor: const Color(0xFFF8FDF8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applying ? null : _apply,
              icon: _applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_applying ? 'Sending…' : 'Send Application',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kP2,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ]),
      ),
    );
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
    final job = widget.job;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = uid == job.farmerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _kP1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kP1, _kP2, Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(job.status.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 8),
                        Text(job.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(job.farmerName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Key info ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16),
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
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _InfoStat('₹${job.dailyWage.toStringAsFixed(0)}',
                        'Per Day', _kOrange),
                    _vDivider(),
                    _InfoStat('${job.workersRequired}', 'Workers', _kP2),
                    _vDivider(),
                    _InfoStat('${job.durationDays}', 'Days', _kGreen),
                    _vDivider(),
                    _InfoStat(
                        '${job.applicantCount}', 'Applied', Colors.purple),
                  ]),
            ),
          ),

          // ── Job details ───────────────────────────────────────────────────
          _JCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JTitle('Job Details', Icons.info_outline_rounded),
                  const SizedBox(height: 12),
                  _JRow(Icons.location_on_rounded, 'Location', job.location),
                  _JRow(Icons.calendar_today_rounded, 'Start Date',
                      '${job.startDate.day}/${job.startDate.month}/${job.startDate.year}'),
                  _JRow(Icons.event_rounded, 'End Date',
                      '${job.endDate.day}/${job.endDate.month}/${job.endDate.year}'),
                  _JRow(Icons.schedule_rounded, 'Working Hours',
                      job.workingHours),
                  _JRow(Icons.people_rounded, 'Spots Left',
                      '${job.spotsLeft} of ${job.workersRequired}'),
                  if (job.foodIncluded)
                    _JRow(Icons.restaurant_rounded, 'Food',
                        '✅ Included'),
                  if (job.accommodationIncluded)
                    _JRow(Icons.hotel_rounded, 'Accommodation',
                        '✅ Included'),
                ]),
          ),

          // ── Required skills ───────────────────────────────────────────────
          if (job.requiredSkills.isNotEmpty)
            _JCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JTitle('Required Skills', Icons.handyman_rounded),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.requiredSkills
                          .map((s) => _SkillBadge(s))
                          .toList(),
                    ),
                  ]),
            ),

          // ── Description ───────────────────────────────────────────────────
          if (job.description.isNotEmpty)
            _JCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JTitle('Description', Icons.description_rounded),
                    const SizedBox(height: 10),
                    Text(job.description,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87,
                            height: 1.5)),
                  ]),
            ),

          // ── Applicants (owner only) ────────────────────────────────────────
          if (isOwner)
            _JCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JTitle('Applicants', Icons.people_rounded),
                    const SizedBox(height: 12),
                    StreamBuilder<List<JobApplication>>(
                      stream: _applicationsStream,
                      builder: (ctx, snap) {
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return Text('No applications yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13));
                        }
                        return Column(
                          children: snap.data!
                              .map((a) => _ApplicantTile(
                                    app: a,
                                    service: widget.service,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ]),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),

      // ── Bottom bar ────────────────────────────────────────────────────────
      bottomNavigationBar: isOwner
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(children: [
                if (job.farmerPhone.isNotEmpty) ...[
                  IconButton(
                    onPressed: _callFarmer,
                    icon: const Icon(Icons.phone_rounded, color: _kP2),
                    style: IconButton.styleFrom(
                        backgroundColor: _kLightGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _checking
                      ? const Center(
                          child: CircularProgressIndicator(color: _kP2))
                      : _hasApplied
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              decoration: BoxDecoration(
                                  color: _kLightGreen,
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: _kGreen),
                                    SizedBox(width: 8),
                                    Text('Application Sent',
                                        style: TextStyle(
                                            color: _kP2,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ]),
                            )
                          : ElevatedButton.icon(
                              onPressed:
                                  job.isOpen && !job.isFull
                                      ? _showApplySheet
                                      : null,
                              icon: const Icon(Icons.send_rounded),
                              label: Text(
                                  job.isFull
                                      ? 'Job Full'
                                      : 'Apply Now',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _kP2,
                                  foregroundColor: Colors.white,
                                  minimumSize:
                                      const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12))),
                            ),
                ),
              ]),
            ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _InfoStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _InfoStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

class _JCard extends StatelessWidget {
  final Widget child;

  const _JCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

class _JTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _JTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: _kP2),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _kDark)),
    ]);
  }
}

class _JRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _JRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Text('$label:  ',
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kDark)),
        ),
      ]),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final String label;

  const _SkillBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: _kLightGreen,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGreen.withOpacity(0.4))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12, color: _kP2, fontWeight: FontWeight.w500)),
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  final JobApplication app;
  final LabourHubService service;

  const _ApplicantTile({required this.app, required this.service});

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(app.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FDF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _kLightGreen,
          backgroundImage: app.labourPhotoUrl.isNotEmpty
              ? NetworkImage(app.labourPhotoUrl)
              : null,
          child: app.labourPhotoUrl.isEmpty
              ? Text(
                  app.labourName.isNotEmpty
                      ? app.labourName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: _kP2, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.labourName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (app.counterOffer != null)
                  Text(
                      'Counter offer: ₹${app.counterOffer!.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                          fontSize: 12, color: _kOrange,
                          fontWeight: FontWeight.w500)),
                if (app.message.isNotEmpty)
                  Text(app.message,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ]),
        ),
        const SizedBox(width: 8),
        Column(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(app.status.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          if (app.status == 'pending')
            Row(children: [
              GestureDetector(
                onTap: () => service.updateApplicationStatus(
                    app.id, 'accepted'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: _kLightGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: _kGreen, size: 16),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => service.updateApplicationStatus(
                    app.id, 'rejected'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded,
                      color: Colors.red.shade400, size: 16),
                ),
              ),
            ]),
        ]),
      ]),
    );
  }
}
