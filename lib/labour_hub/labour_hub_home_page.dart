import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// shimmer not available — using AnimatedContainer fallback;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'job_post_model.dart';
import 'labour_detail_page.dart';
import 'labour_profile_form_page.dart';
import 'job_post_form_page.dart';
import 'job_detail_page.dart';
import 'labour_dashboard_page.dart';
import 'saved_workers_page.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP1 = Color(0xFF1B5E20);
const _kP2 = Color(0xFF2E7D32);
const _kGreen = Color(0xFF4CAF50);
const _kLightGreen = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kAmber = Color(0xFFFFA000);
const _kDark = Color(0xFF1A2D1A);
const _kGrad = LinearGradient(
  colors: [_kP1, _kP2, Color(0xFF388E3C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class LabourHubHomePage extends StatefulWidget {
  const LabourHubHomePage({super.key});

  @override
  State<LabourHubHomePage> createState() => _LabourHubHomePageState();
}

class _LabourHubHomePageState extends State<LabourHubHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _service = LabourHubService();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            floating: false,
            backgroundColor: _kP1,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.white),
                tooltip: 'Saved Workers',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SavedWorkersPage())),
              ),
              IconButton(
                icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
                tooltip: 'My Dashboard',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LabourDashboardPage())),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: _kGrad),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),
                        Row(children: [
                          const Text('👷 ',
                              style: TextStyle(fontSize: 24)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('WorkForce Hub',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                              Text('Agricultural Labour Platform',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _SearchBar(controller: _searchCtrl,
                            onChanged: (_) => setState(() {})),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Icons.people_alt_rounded, size: 18),
                    text: 'Find Workers'),
                Tab(icon: Icon(Icons.work_outline_rounded, size: 18),
                    text: 'Find Jobs'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _WorkersTab(
                service: _service, searchQuery: _searchCtrl.text),
            _JobsTab(service: _service, searchQuery: _searchCtrl.text),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const JobPostFormPage())),
              backgroundColor: _kOrange,
              icon: const Icon(Icons.post_add_rounded),
              label: const Text('Post a Job',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                final profile = await _service.getMyProfile();
                if (mounted) {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              LabourProfileFormPage(existing: profile)));
                }
              },
              backgroundColor: _kP2,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('My Profile',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search workers, skills, location…',
          hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white70, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── Workers Tab ───────────────────────────────────────────────────────────────

class _WorkersTab extends StatefulWidget {
  final LabourHubService service;
  final String searchQuery;

  const _WorkersTab({required this.service, required this.searchQuery});

  @override
  State<_WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<_WorkersTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<LabourProfile>> _stream;
  String _selectedSkill = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stream = widget.service.streamAllProfiles();
  }

  List<LabourProfile> _filter(List<LabourProfile> all) {
    var list = all;
    if (_selectedSkill != 'All') {
      list = list.where((p) => p.skills.contains(_selectedSkill)).toList();
    }
    final q = widget.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.skills.any((s) => s.toLowerCase().contains(q)) ||
              p.village.toLowerCase().contains(q) ||
              p.district.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<LabourProfile>>(
      stream: _stream,
      builder: (ctx, snap) {
        if (snap.hasError) return _ErrorView(onRetry: () => setState(() {}));
        final loading = !snap.hasData;
        final all = snap.data ?? [];
        final filtered = _filter(all);
        final available =
            filtered.where((p) => p.availabilityStatus == 'available').toList();
        final topRated = [...filtered]
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final topRatedList = topRated.take(10).toList();
        final recent = [...filtered]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentList = recent.take(10).toList();

        return CustomScrollView(
          slivers: [
            // skill category chips
            SliverToBoxAdapter(
              child: _SkillChips(
                selected: _selectedSkill,
                onSelect: (s) => setState(() => _selectedSkill = s),
              ),
            ),

            // stats bar
            if (!loading)
              SliverToBoxAdapter(
                child: _StatsBar(total: all.length,
                    available: all
                        .where((p) => p.availabilityStatus == 'available')
                        .length),
              ),

            // Available Now
            _SectionHeader(
              title: 'Available Now',
              icon: Icons.circle,
              iconColor: _kGreen,
              onSeeAll: () {},
            ),
            SliverToBoxAdapter(
              child: loading
                  ? _HorizontalShimmer()
                  : available.isEmpty
                      ? _EmptyHorizontal(
                          message: 'No workers available right now')
                      : _HorizontalWorkerList(
                          workers: available, service: widget.service),
            ),

            // Top Rated
            _SectionHeader(
              title: 'Top Rated Workers',
              icon: Icons.star_rounded,
              iconColor: _kAmber,
              onSeeAll: () {},
            ),
            SliverToBoxAdapter(
              child: loading
                  ? _HorizontalShimmer()
                  : topRatedList.isEmpty
                      ? _EmptyHorizontal(message: 'No rated workers yet')
                      : _HorizontalWorkerList(
                          workers: topRatedList, service: widget.service),
            ),

            // Recently Joined
            _SectionHeader(
              title: 'Recently Joined',
              icon: Icons.fiber_new_rounded,
              iconColor: _kOrange,
              onSeeAll: () {},
            ),
            SliverToBoxAdapter(
              child: loading
                  ? _HorizontalShimmer()
                  : recentList.isEmpty
                      ? _EmptyHorizontal(message: 'No recent workers')
                      : _HorizontalWorkerList(
                          workers: recentList, service: widget.service),
            ),

            // All Workers heading
            _SectionHeader(
              title: 'All Workers (${filtered.length})',
              icon: Icons.people_rounded,
              iconColor: _kP2,
            ),

            // All workers list
            if (loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const _WorkerCardShimmer(),
                  childCount: 6,
                ),
              )
            else if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: _FullEmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'No workers found',
                  subtitle: 'Try changing your filters or search terms',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _WorkerCard(
                      worker: filtered[i], service: widget.service),
                  childCount: filtered.length,
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }
}

// ── Jobs Tab ──────────────────────────────────────────────────────────────────

class _JobsTab extends StatefulWidget {
  final LabourHubService service;
  final String searchQuery;

  const _JobsTab({required this.service, required this.searchQuery});

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<JobPost>> _stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stream = widget.service.streamOpenJobs();
  }

  List<JobPost> _filter(List<JobPost> all) {
    final q = widget.searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((j) =>
            j.title.toLowerCase().contains(q) ||
            j.location.toLowerCase().contains(q) ||
            j.requiredSkills.any((s) => s.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<JobPost>>(
      stream: _stream,
      builder: (ctx, snap) {
        if (snap.hasError) return _ErrorView(onRetry: () => setState(() {}));
        final loading = !snap.hasData;
        final jobs = _filter(snap.data ?? []);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _kLightGreen,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${jobs.length} Open Jobs',
                      style: const TextStyle(
                          color: _kP2,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ]),
              ),
            ),
            if (loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                    (_, __) => const _JobCardShimmer(), childCount: 5),
              )
            else if (jobs.isEmpty)
              const SliverToBoxAdapter(
                child: _FullEmptyState(
                  icon: Icons.work_off_rounded,
                  title: 'No open jobs',
                  subtitle: 'Be the first to post a job for your farm',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _JobCard(job: jobs[i], service: widget.service),
                  childCount: jobs.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }
}

// ── Skill Chips ───────────────────────────────────────────────────────────────

class _SkillChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _SkillChips({required this.selected, required this.onSelect});

  static const _skills = [
    'All', 'Harvesting', 'Planting', 'Weeding', 'Pruning', 'Spraying',
    'Drip Irrigation', 'Tractor Driver', 'Harvester Operator', 'JCB Operator',
    'Coconut Tree Climber', 'Coffee Picking', 'Dairy Farm Worker',
    'Organic Farming',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _skills.length,
        itemBuilder: (_, i) {
          final s = _skills[i];
          final sel = s == selected;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _kP2 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _kP2 : Colors.grey.shade300),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: _kP2.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Text(s,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int available;

  const _StatsBar({required this.total, required this.available});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        _StatChip(label: '$total Workers', color: _kP2),
        const SizedBox(width: 8),
        _StatChip(label: '$available Available', color: _kGreen),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _kDark)),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(
                      color: _kP2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }
}

// ── Horizontal Worker List ────────────────────────────────────────────────────

class _HorizontalWorkerList extends StatelessWidget {
  final List<LabourProfile> workers;
  final LabourHubService service;

  const _HorizontalWorkerList(
      {required this.workers, required this.service});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: workers.length,
        itemBuilder: (_, i) => _WorkerCardHorizontal(
            worker: workers[i], service: service),
      ),
    );
  }
}

class _WorkerCardHorizontal extends StatelessWidget {
  final LabourProfile worker;
  final LabourHubService service;

  const _WorkerCardHorizontal(
      {required this.worker, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LabourDetailPage(profile: worker))),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _Avatar(photoUrl: worker.photoUrl, name: worker.name, size: 56),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(worker.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(height: 4),
            if (worker.rating > 0)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.star_rounded, color: _kAmber, size: 14),
                Text(' ${worker.rating.toStringAsFixed(1)}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            const SizedBox(height: 6),
            if (worker.skills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(worker.skills.first,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kP2,
                        fontWeight: FontWeight.w500)),
              ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: worker.availabilityStatus == 'available'
                      ? _kLightGreen
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                worker.availabilityStatus == 'available'
                    ? '● Available'
                    : '○ Busy',
                style: TextStyle(
                    fontSize: 10,
                    color: worker.availabilityStatus == 'available'
                        ? _kGreen
                        : Colors.orange,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text('₹${worker.dailyWage.toStringAsFixed(0)}/day',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _kOrange)),
          ],
        ),
      ),
    );
  }
}

// ── Worker Card (vertical list) ───────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final LabourProfile worker;
  final LabourHubService service;

  const _WorkerCard({required this.worker, required this.service});

  void _call(BuildContext ctx) async {
    if (worker.phone.isEmpty) return;
    final uri = Uri.parse('tel:${worker.phone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LabourDetailPage(profile: worker))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              _Avatar(photoUrl: worker.photoUrl, name: worker.name, size: 60),
              if (worker.isVerified)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded,
                        color: _kP2, size: 14),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(worker.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      _AvailBadge(status: worker.availabilityStatus),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(worker.locationDisplay,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 6),
                    // Skills
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: worker.skills
                          .take(3)
                          .map((s) => _SkillChipSmall(s))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (worker.rating > 0) ...[
                        Icon(Icons.star_rounded,
                            color: _kAmber, size: 14),
                        Text(' ${worker.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(' (${worker.reviewCount})',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.work_history_rounded,
                          size: 13, color: Colors.grey),
                      Text(' ${worker.completedJobs} jobs',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      Text(
                        '₹${worker.dailyWage.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _kOrange),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _call(context),
                          icon: const Icon(Icons.phone_rounded, size: 15),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: _kP2,
                              side: const BorderSide(color: _kP2),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      LabourDetailPage(profile: worker))),
                          icon: const Icon(Icons.handshake_rounded,
                              size: 15),
                          label: const Text('Hire Now'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kP2,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Job Card ──────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final JobPost job;
  final LabourHubService service;

  const _JobCard({required this.job, required this.service});

  @override
  Widget build(BuildContext context) {
    final daysLeft = job.daysUntilStart;
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => JobDetailPage(job: job, service: service))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _kLightGreen,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _kP2,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.agriculture_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(job.farmerName,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${job.dailyWage.toStringAsFixed(0)}/day',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _kOrange)),
                if (daysLeft > 0)
                  Text('Starts in $daysLeft days',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(job.location,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.people_rounded,
                        size: 14, color: Colors.grey),
                    Text(' ${job.spotsLeft} spots left',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 8),
                  // Required skills
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: job.requiredSkills
                        .take(4)
                        .map((s) => _SkillChipSmall(s))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (job.foodIncluded)
                      _BenefitChip('🍱 Food', Colors.orange),
                    if (job.foodIncluded) const SizedBox(width: 6),
                    if (job.accommodationIncluded)
                      _BenefitChip('🏠 Stay', Colors.blue),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: _kP2,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        Text(
                            '${job.applicantCount} applied',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double size;

  const _Avatar(
      {required this.photoUrl, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _kLightGreen,
      backgroundImage:
          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontSize: size * 0.4,
                  color: _kP2,
                  fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

class _AvailBadge extends StatelessWidget {
  final String status;

  const _AvailBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvail = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: isAvail ? _kLightGreen : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        isAvail ? '● Available' : '○ Busy',
        style: TextStyle(
            fontSize: 10,
            color: isAvail ? _kGreen : Colors.orange.shade700,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SkillChipSmall extends StatelessWidget {
  final String label;

  const _SkillChipSmall(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _kLightGreen,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kGreen.withOpacity(0.3))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: _kP2,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BenefitChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Shimmer placeholders ──────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? radius;

  const _ShimmerBox(
      {required this.width, required this.height, this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Color?> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = ColorTween(
            begin: Colors.grey.shade200, end: Colors.grey.shade100)
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
            color: _anim.value,
            borderRadius:
                widget.radius ?? BorderRadius.circular(8)),
      ),
    );
  }
}

class _HorizontalShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 4,
        itemBuilder: (_, __) => _ShimmerBox(
          width: 150,
          height: 210,
          radius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _WorkerCardShimmer extends StatelessWidget {
  const _WorkerCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: _ShimmerBox(
        width: double.infinity,
        height: 130,
        radius: BorderRadius.circular(16),
      ),
    );
  }
}

class _JobCardShimmer extends StatelessWidget {
  const _JobCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: _ShimmerBox(
        width: double.infinity,
        height: 160,
        radius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── Empty/Error states ────────────────────────────────────────────────────────

class _EmptyHorizontal extends StatelessWidget {
  final String message;

  const _EmptyHorizontal({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      ),
    );
  }
}

class _FullEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FullEmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: _kDark)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('Could not load data',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style:
              ElevatedButton.styleFrom(backgroundColor: _kP2),
        ),
      ]),
    );
  }
}
