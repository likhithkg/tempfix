// lib/rent/rent_home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rent_model.dart';
import 'rent_machine_service.dart';
import 'rent_list_form_page.dart';
import 'rent_nearby_page.dart'; // ✅ Import nearby page

class RentHomePage extends StatefulWidget {
  const RentHomePage({super.key});

  @override
  State<RentHomePage> createState() => _RentHomePageState();
}

class _RentHomePageState extends State<RentHomePage> {
  final _searchCtrl = TextEditingController();
  final _types = const [
    'All',
    'Tractor',
    'Harvester',
    'Plough',
    'Seeder',
    'Sprayer',
    'Tiller',
    'Baler',
    'Other',
  ];

  String _type = 'All';
  String _search = '';
  bool _asGrid = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _confirmDelete(BuildContext context, RentMachine m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await RentMachineService.instance.deleteRentMachine(m.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
    }
  }

  bool _isOwner(RentMachine m) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty && uid == m.ownerId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rent Machine'),
        actions: [
          // ✅ Nearby button
          IconButton(
            tooltip: 'Nearby Machines',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RentNearbyPage()),
              );
            },
            icon: const Icon(Icons.near_me_rounded),
          ),
          IconButton(
            tooltip: _asGrid ? 'List' : 'Grid',
            onPressed: () => setState(() => _asGrid = !_asGrid),
            icon: Icon(
              _asGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RentListFormPage()),
          );
        },
        label: const Text('List Machine'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name, owner, type or location…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          // Categories
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final t = _types[i];
                final selected = t == _type;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _types.length,
            ),
          ),
          const SizedBox(height: 6),
          // Machine listings
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: StreamBuilder<List<RentMachine>>(
                stream: RentMachineService.instance
                    .streamMachines(typeFilter: _type, search: _search),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No machines found. Tap “List Machine” to add one.',
                      ),
                    );
                  }

                  if (_asGrid) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .75,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _MachineCard(
                        m: items[i],
                        onCall: _call,
                        onEdit: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RentListFormPage(
                                existingMachine: items[i],
                              ),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, items[i]),
                        isOwner: _isOwner(items[i]),
                      ),
                    );
                  } else {
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _MachineTile(
                        m: items[i],
                        onCall: _call,
                        onEdit: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RentListFormPage(
                                existingMachine: items[i],
                              ),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, items[i]),
                        isOwner: _isOwner(items[i]),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------
// Machine Card (Grid view)
// ----------------------
class _MachineCard extends StatelessWidget {
  const _MachineCard({
    required this.m,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
    required this.isOwner,
  });

  final RentMachine m;
  final void Function(String phone) onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = m.imageUrl.isNotEmpty
        ? NetworkImage(m.imageUrl)
        : const AssetImage('assets/farmer_logo.png') as ImageProvider;

    return Material(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Ink.image(image: img, fit: BoxFit.cover),
                  if (isOwner)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.black26,
                        shape: const CircleBorder(),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          onSelected: (val) async {
                            if (val == 'edit') {
                              onEdit();
                            } else if (val == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      Chip(
                        label: Text(m.type),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text('₹${m.pricePerDay.toStringAsFixed(0)}/day'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📍 ${m.location != null && m.location!.isNotEmpty ? m.location! : "Location not set"}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Call',
                        onPressed: () => onCall(m.phone),
                        icon: const Icon(Icons.call_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------
// Machine Tile (List view)
// ----------------------
class _MachineTile extends StatelessWidget {
  const _MachineTile({
    required this.m,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
    required this.isOwner,
  });

  final RentMachine m;
  final void Function(String phone) onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final img = m.imageUrl.isNotEmpty
        ? NetworkImage(m.imageUrl)
        : const AssetImage('assets/farmer_logo.png') as ImageProvider;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: img,
        ),
        title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(m.type),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('₹${m.pricePerDay.toStringAsFixed(0)}/day'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${m.location != null && m.location!.isNotEmpty ? m.location! : "Location not set"}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Call',
              onPressed: () => onCall(m.phone),
              icon: const Icon(Icons.call_rounded),
            ),
            if (isOwner)
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
          ],
        ),
      ),
    );
  }
}