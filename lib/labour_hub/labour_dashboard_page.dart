import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'job_post_model.dart';
import 'job_application_model.dart';
import 'labour_profile_form_page.dart';
import 'job_post_form_page.dart';
import 'job_detail_page.dart';









class LabourDashboardPage extends StatefulWidget {
  const LabourDashboardPage({super.key});

  @override
  State<LabourDashboardPage> createState() => _LabourDashboardPageState();
}

class _LabourDashboardPageState extends State<LabourDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _service = LabourHubService();
  late Future<LabourProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _profileFuture = _service.getMyProfile();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: KMColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [KMColors.primaryDark, KMColors.primary, Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: FutureBuilder<LabourProfile?>(
                    future: _profileFuture,
                    builder: (ctx, snap) {
                      final profile = snap.data;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white24,
                                backgroundImage: profile?.photoUrl.isNotEmpty == true
                                    ? NetworkImage(profile!.photoUrl)
                                    : null,
                                child: profile?.photoUrl.isEmpty != false
                                    ? Text(
                                        (user.displayName ?? '?')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          profile?.name ??
                                              user.displayName ??
                                              'Farmer',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      if (profile != null) ...[
                                        const SizedBox(height: 2),
                                        Text(profile.locationDisplay,
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          _StatusDot(profile.availabilityStatus),
                                          const SizedBox(width: 6),
                                          DropdownButton<String>(
                                            value: profile.availabilityStatus,
                                            dropdownColor: KMColors.primaryDark,
                                            iconEnabledColor: Colors.white,
                                            underline: const SizedBox(),
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                            items: [
                                              'available',
                                              'busy',
                                              'unavailable'
                                            ]
                                                .map((s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text(
                                                        kAvailabilityLabels[s] ??
                                                            s)))
                                                .toList(),
                                            onChanged: (v) async {
                                              if (v != null) {
                                                await _service
                                                    .updateAvailability(v);
                                                if (mounted) {
                                                  setState(() {
                                                    _profileFuture =
                                                        _service.getMyProfile();
                                                  });
                                                }
                                              }
                                            },
                                          ),
                                        ]),
                                      ],
                                    ]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: Colors.white),
                                onPressed: () async {
                                  final prof =
                                      await _service.getMyProfile();
                                  if (mounted) {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                LabourProfileFormPage(
                                                    existing: prof)));
                                    setState(() {});
                                  }
                                },
                              ),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.work_outline_rounded, size: 16),
                    text: 'My Applications'),
                Tab(icon: Icon(Icons.post_add_rounded, size: 16),
                    text: 'My Job Posts'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _ApplicationsTab(service: _service),
            _PostedJobsTab(service: _service),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const JobPostFormPage()));
          setState(() {});
        },
        backgroundColor: KMColors.rentPrimary,
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('Post Job',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// â”€â”€ Applications Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ApplicationsTab extends StatefulWidget {
  final LabourHubService service;

  const _ApplicationsTab({required this.service});

  @override
  State<_ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<_ApplicationsTab> {
  late final Stream<List<JobApplication>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.service.streamMyApplications();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'shortlisted':
        return Icons.star_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobApplication>>(
      stream: _stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: KMColors.primary));
        }
        final apps = snap.data!;
        if (apps.isEmpty) {
          return const _EmptyState(
            icon: Icons.send_rounded,
            title: 'No applications yet',
            subtitle: 'Browse open jobs and apply to start working',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: apps.length,
          itemBuilder: (_, i) {
            final a = apps[i];
            final color = _statusColor(a.status);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      Icon(_statusIcon(a.status), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.jobTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        if (a.counterOffer != null)
                          Text(
                              'Counter: â‚¹${a.counterOffer!.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: KMColors.rentPrimary,
                                  fontWeight: FontWeight.w500)),
                        Text(
                            'Applied: ${a.appliedAt.day}/${a.appliedAt.month}/${a.appliedAt.year}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3))),
                  child: Text(a.status.toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

// â”€â”€ Posted Jobs Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PostedJobsTab extends StatefulWidget {
  final LabourHubService service;

  const _PostedJobsTab({required this.service});

  @override
  State<_PostedJobsTab> createState() => _PostedJobsTabState();
}

class _PostedJobsTabState extends State<_PostedJobsTab> {
  late final Stream<List<JobPost>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.service.streamMyPostedJobs();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobPost>>(
      stream: _stream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: KMColors.primary));
        }
        final jobs = snap.data!;
        if (jobs.isEmpty) {
          return const _EmptyState(
            icon: Icons.work_off_rounded,
            title: 'No jobs posted yet',
            subtitle: 'Post a job to find skilled workers for your farm',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: jobs.length,
          itemBuilder: (_, i) {
            final j = jobs[i];
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          JobDetailPage(job: j, service: widget.service))),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(j.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        _StatusBadge(j.status),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(j.location,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _InfoPill(
                            'â‚¹${j.dailyWage.toStringAsFixed(0)}/day',
                            KMColors.rentPrimary),
                        const SizedBox(width: 6),
                        _InfoPill('${j.workersRequired} workers', KMColors.primary),
                        const SizedBox(width: 6),
                        _InfoPill(
                            '${j.applicantCount} applied',
                            Colors.purple),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                widget.service.updateJobStatus(j.id, 'cancelled'),
                            icon: const Icon(Icons.close_rounded,
                                size: 14),
                            label: const Text('Close',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                    color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => JobDetailPage(
                                        job: j, service: widget.service))),
                            icon: const Icon(
                                Icons.people_alt_rounded,
                                size: 14),
                            label: Text(
                                '${j.applicantCount} Applicants',
                                style: const TextStyle(
                                    fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: KMColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8))),
                          ),
                        ),
                      ]),
                    ]),
              ),
            );
          },
        );
      },
    );
  }
}

// â”€â”€ Shared â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatusDot extends StatelessWidget {
  final String status;

  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == 'available'
        ? KMColors.available
        : status == 'busy'
            ? Colors.orange
            : Colors.grey;
    return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == 'open'
        ? KMColors.available
        : status == 'in_progress'
            ? Colors.blue
            : status == 'completed'
                ? KMColors.primary
                : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: KMColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}


