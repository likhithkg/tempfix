import 'package:flutter/material.dart';
import 'labour_hub_service.dart';
import 'labour_profile_model.dart';
import 'labour_detail_page.dart';
import '../theme.dart';


class SavedWorkersPage extends StatefulWidget {
  const SavedWorkersPage({super.key});

  @override
  State<SavedWorkersPage> createState() => _SavedWorkersPageState();
}

class _SavedWorkersPageState extends State<SavedWorkersPage> {
  final _service = LabourHubService();
  late Future<List<LabourProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchFavouriteProfiles();
  }

  void _reload() => setState(() {
        _future = _service.fetchFavouriteProfiles();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: KMColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: KMGradients.primaryHeader),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 48, 16, 0),
                    child: Row(children: [
                      SizedBox(width: 40),
                      Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Saved Workers',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Your favourited labour profiles',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<LabourProfile>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: KMColors.primary)),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                        child: Text('Could not load saved workers',
                            style: TextStyle(color: Colors.grey.shade600))),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(children: [
                      Icon(Icons.favorite_border_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No saved workers yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap ♥ on a worker profile to save them here',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400)),
                    ]),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) =>
                      _SavedCard(profile: list[i], service: _service, onRemove: _reload),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  final LabourProfile profile;
  final LabourHubService service;
  final VoidCallback onRemove;

  const _SavedCard(
      {required this.profile, required this.service, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => LabourDetailPage(profile: profile)));
          onRemove();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: KMColors.primary.withValues(alpha: 0.15),
              backgroundImage: profile.photoUrl.isNotEmpty
                  ? NetworkImage(profile.photoUrl)
                  : null,
              child: profile.photoUrl.isEmpty
                  ? Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: KMColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(profile.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: profile.availabilityStatus == 'available'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.circle,
                              size: 7,
                              color: profile.availabilityStatus == 'available'
                                  ? Colors.green
                                  : Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                              profile.availabilityStatus == 'available'
                                  ? 'Available'
                                  : 'Busy',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: profile.availabilityStatus ==
                                          'available'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    if (profile.locationDisplay.isNotEmpty)
                      Text('📍 ${profile.locationDisplay}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (profile.skills.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: KMColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(profile.skills.first,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: KMColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ),
                      const Spacer(),
                      if (profile.rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFA000)),
                        const SizedBox(width: 2),
                        Text(profile.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(width: 10),
                      Text('₹${profile.dailyWage.toInt()}/day',
                          style: const TextStyle(
                              fontSize: 12,
                              color: KMColors.primary,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ]),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.red),
              tooltip: 'Remove from saved',
              onPressed: () async {
                await service.toggleFavourite(profile.id);
                onRemove();
              },
            ),
          ]),
        ),
      ),
    );
  }
}
