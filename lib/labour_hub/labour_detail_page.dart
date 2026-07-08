import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'labour_review_model.dart';

const _kP1 = Color(0xFF1B5E20);
const _kP2 = Color(0xFF2E7D32);
const _kGreen = Color(0xFF4CAF50);
const _kLightGreen = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kAmber = Color(0xFFFFA000);
const _kDark = Color(0xFF1A2D1A);

class LabourDetailPage extends StatefulWidget {
  final LabourProfile profile;

  const LabourDetailPage({super.key, required this.profile});

  @override
  State<LabourDetailPage> createState() => _LabourDetailPageState();
}

class _LabourDetailPageState extends State<LabourDetailPage> {
  final _service = LabourHubService();
  late final Stream<List<LabourReview>> _reviewsStream;
  bool _isFav = false;
  bool _showReviewForm = false;
  double _reviewRating = 5;
  final _reviewCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reviewsStream = _service.streamReviews(widget.profile.id);
    _loadFav();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFav() async {
    final favs = await _service.getFavourites();
    if (mounted) setState(() => _isFav = favs.contains(widget.profile.id));
  }

  void _call() async {
    final p = widget.profile;
    final number = p.phone.isNotEmpty ? p.phone : '';
    if (number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _whatsapp() async {
    final p = widget.profile;
    final raw = (p.whatsappNumber.isNotEmpty ? p.whatsappNumber : p.phone)
        .replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) return;
    final number = raw.startsWith('91') ? raw : '91$raw';
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _openMap() async {
    final p = widget.profile;
    if (!p.hasLocation) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _share() {
    final p = widget.profile;
    final text =
        '${p.name} — ${p.skills.take(3).join(', ')}\n${p.locationDisplay} | ${p.wageDisplay}\nContact: ${p.phone}';
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile link copied to clipboard'),
        backgroundColor: _kP2,
      ));
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final review = LabourReview(
      id: '',
      labourId: widget.profile.id,
      reviewerId: user.uid,
      reviewerName: user.displayName ?? 'Anonymous',
      rating: _reviewRating,
      comment: _reviewCtrl.text.trim(),
      jobTitle: 'Direct review',
      createdAt: DateTime.now(),
    );
    try {
      await _service.addReview(review);
      if (mounted) {
        setState(() {
          _showReviewForm = false;
          _reviewCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Review submitted!'), backgroundColor: _kP2));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to submit review'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwn = uid == p.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _kP1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: _share,
              ),
              IconButton(
                icon: Icon(
                    _isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFav ? Colors.red.shade300 : Colors.white),
                onPressed: () async {
                  await _service.toggleFavourite(p.id);
                  setState(() => _isFav = !_isFav);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_kP1, _kP2, Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 44),
                      // Online indicator + avatar
                      Stack(alignment: Alignment.center, children: [
                        Stack(alignment: Alignment.bottomRight, children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white24,
                            backgroundImage: p.photoUrl.isNotEmpty
                                ? NetworkImage(p.photoUrl)
                                : null,
                            child: p.photoUrl.isEmpty
                                ? Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                          if (p.isVerified)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.verified_rounded,
                                  color: _kP2, size: 18),
                            ),
                        ]),
                        if (p.onlineStatus)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                  color: _kGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2)),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      Text(p.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(p.lastSeenText,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.white54),
                            const SizedBox(width: 4),
                            Text(p.locationDisplay,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ]),
                      const SizedBox(height: 8),
                      _AvailPill(status: p.availabilityStatus),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats Row ───────────────────────────────────────────────────────
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
                  _Stat(
                      icon: Icons.star_rounded,
                      color: _kAmber,
                      value: p.rating > 0
                          ? p.rating.toStringAsFixed(1)
                          : '–',
                      label: 'Rating'),
                  _divider(),
                  _Stat(
                      icon: Icons.work_history_rounded,
                      color: _kP2,
                      value: '${p.completedJobs}',
                      label: 'Jobs Done'),
                  _divider(),
                  _Stat(
                      icon: Icons.timer_rounded,
                      color: _kOrange,
                      value: '${p.experienceYears}y',
                      label: 'Experience'),
                  _divider(),
                  _Stat(
                      icon: Icons.currency_rupee_rounded,
                      color: _kGreen,
                      value: p.wageDisplay,
                      label: 'Wage'),
                ],
              ),
            ),
          ),

          // ── Gallery ─────────────────────────────────────────────────────────
          if (p.galleryUrls.isNotEmpty)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Photo Gallery', Icons.photo_library_rounded),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: p.galleryUrls.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _showGalleryImage(context, p.galleryUrls, i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            p.galleryUrls[i],
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 110,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_rounded,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Description ──────────────────────────────────────────────────────
          if (p.description.isNotEmpty)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('About', Icons.description_rounded),
                  const SizedBox(height: 12),
                  Text(p.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.55)),
                ],
              ),
            ),

          // ── Skills ──────────────────────────────────────────────────────────
          if (p.skills.isNotEmpty)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Skills', Icons.handyman_rounded),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.skills.map((s) => _SkillBadge(s)).toList(),
                  ),
                ],
              ),
            ),

          // ── Availability ─────────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Availability', Icons.event_available_rounded),
                const SizedBox(height: 12),
                Row(children: [
                  _AvailPill(status: p.availabilityStatus),
                  const SizedBox(width: 8),
                  Text('Working radius: ${p.workingRadiusKm} km',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ]),
                if (p.availabilityTypes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.availabilityTypes.map((t) {
                      final label =
                          kAvailabilityTypeLabels[t] ?? t;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _kLightGreen,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kGreen.withOpacity(0.3))),
                        child: Text(label,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _kP2,
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // ── Wage Details ─────────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Wage Information',
                    Icons.currency_rupee_rounded),
                const SizedBox(height: 12),
                if (p.dailyWage > 0)
                  _DetailRow(Icons.wb_sunny_rounded, 'Daily Wage',
                      '₹${p.dailyWage.toStringAsFixed(0)} / day'),
                if (p.hourlyWage > 0)
                  _DetailRow(Icons.access_time_rounded, 'Hourly Wage',
                      '₹${p.hourlyWage.toStringAsFixed(0)} / hour'),
                if (p.monthlyWage > 0)
                  _DetailRow(Icons.calendar_month_rounded, 'Monthly Wage',
                      '₹${p.monthlyWage.toStringAsFixed(0)} / month'),
                _DetailRow(Icons.thumb_up_rounded, 'Preferred',
                    kWageTypeLabels[p.preferredWageType] ?? p.preferredWageType),
              ],
            ),
          ),

          // ── Details ──────────────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Details', Icons.info_outline_rounded),
                const SizedBox(height: 12),
                _DetailRow(Icons.person_rounded, 'Gender', p.gender),
                _DetailRow(Icons.cake_rounded, 'Age', '${p.age} years'),
                _DetailRow(Icons.phone_rounded, 'Phone', p.phone),
                if (p.whatsappNumber.isNotEmpty)
                  _DetailRow(Icons.chat_rounded, 'WhatsApp', p.whatsappNumber),
                _DetailRow(Icons.location_on_rounded, 'Location',
                    p.locationDisplay),
                if (p.taluk.isNotEmpty)
                  _DetailRow(Icons.map_rounded, 'Taluk', p.taluk),
                if (p.state.isNotEmpty)
                  _DetailRow(Icons.flag_rounded, 'State', p.state),
                if (p.pincode.isNotEmpty)
                  _DetailRow(Icons.pin_drop_rounded, 'Pincode', p.pincode),
                _DetailRow(Icons.language_rounded, 'Languages',
                    p.languages.isEmpty
                        ? 'Not specified'
                        : p.languages.join(', ')),
                if (p.isAadhaarVerified)
                  _DetailRow(Icons.verified_user_rounded, 'Aadhaar',
                      '✅ Verified'),
              ],
            ),
          ),

          // ── Location Map Link ────────────────────────────────────────────────
          if (p.hasLocation)
            _Card(
              child: InkWell(
                onTap: _openMap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blue.shade200)),
                  child: Row(children: [
                    const Icon(Icons.map_rounded,
                        color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('View on Map',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            Text(
                                '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey)),
                          ]),
                    ),
                    const Icon(Icons.open_in_new_rounded,
                        color: Colors.blue, size: 16),
                  ]),
                ),
              ),
            ),

          // ── Badges ───────────────────────────────────────────────────────────
          if (p.isVerified ||
              p.isAadhaarVerified ||
              p.rating >= 4 ||
              p.completedJobs >= 10)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle('Badges', Icons.military_tech_rounded),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (p.isVerified)
                      _Badge('✅ Verified Worker', _kGreen),
                    if (p.isAadhaarVerified)
                      _Badge('🪪 Aadhaar Verified', _kP2),
                    if (p.rating >= 4.5)
                      _Badge('⭐ Top Rated', _kAmber),
                    if (p.completedJobs >= 10)
                      _Badge('🏆 Trusted Worker', _kOrange),
                    if (p.experienceYears >= 5)
                      _Badge('💪 Experienced', Colors.purple),
                    if (p.gender == 'Female')
                      _Badge('👩 Women Worker', Colors.pink),
                  ]),
                ],
              ),
            ),

          // ── Reviews ──────────────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                      child: _CardTitle(
                          'Reviews', Icons.reviews_rounded)),
                  if (!isOwn)
                    TextButton(
                      onPressed: () => setState(
                          () => _showReviewForm = !_showReviewForm),
                      child: Text(
                          _showReviewForm ? 'Cancel' : 'Write Review',
                          style: const TextStyle(color: _kP2)),
                    ),
                ]),
                if (_showReviewForm) ...[
                  const SizedBox(height: 12),
                  _ReviewForm(
                    rating: _reviewRating,
                    onRatingChanged: (r) =>
                        setState(() => _reviewRating = r),
                    controller: _reviewCtrl,
                    onSubmit: _submitReview,
                  ),
                ],
                StreamBuilder<List<LabourReview>>(
                  stream: _reviewsStream,
                  builder: (ctx, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('No reviews yet',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13)),
                      );
                    }
                    return Column(
                        children: snap.data!
                            .map((r) => _ReviewTile(review: r))
                            .toList());
                  },
                ),
              ],
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),

      // ── Bottom Action Bar ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _call,
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Call',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kP2,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _whatsapp,
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                if (p.hasLocation) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _openMap,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Icon(Icons.map_rounded),
                  ),
                ],
              ]),
            ),
    );
  }

  void _showGalleryImage(
      BuildContext context, List<String> urls, int index) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => _GalleryViewer(urls: urls, initialIndex: index)));
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);
}

// ── Gallery Viewer ────────────────────────────────────────────────────────────

class _GalleryViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _GalleryViewer({required this.urls, required this.initialIndex});

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => Center(
          child: InteractiveViewer(
            child: Image.network(widget.urls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _AvailPill extends StatelessWidget {
  final String status;

  const _AvailPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvail = status == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
          color: isAvail
              ? Colors.green.shade700.withOpacity(0.3)
              : Colors.orange.shade700.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isAvail
                  ? Colors.green.shade300
                  : Colors.orange.shade300)),
      child: Text(
        isAvail ? '● Available for work' : '○ Currently busy',
        style: TextStyle(
            color: isAvail
                ? Colors.green.shade100
                : Colors.orange.shade100,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: _kDark)),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

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

class _CardTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _CardTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: _kP2),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: _kDark)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final LabourReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _kLightGreen,
          child: Text(
              review.reviewerName.isNotEmpty
                  ? review.reviewerName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: _kP2, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(review.reviewerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  ...List.generate(
                      5,
                      (i) => Icon(
                            i < review.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 14,
                            color: _kAmber,
                          )),
                ]),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(review.comment,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                ],
              ]),
        ),
      ]),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _ReviewForm({
    required this.rating,
    required this.onRatingChanged,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your Rating',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      const SizedBox(height: 8),
      Row(
        children: List.generate(5, (i) {
          return GestureDetector(
            onTap: () => onRatingChanged(i + 1.0),
            child: Icon(
                i < rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: _kAmber,
                size: 32),
          );
        }),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Write your review…',
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
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
              backgroundColor: _kP2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: const Text('Submit Review',
              style: TextStyle(color: Colors.white)),
        ),
      ),
      const Divider(height: 24),
    ]);
  }
}
