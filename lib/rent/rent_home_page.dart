// lib/rent/rent_home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:krishimithra/rent/rent_model.dart';
import 'package:krishimithra/rent/rent_machine_service.dart';
import 'rent_list_form_page.dart';
import 'rent_nearby_page.dart';
import 'rent_machine_details_page.dart';
import '../l10n/app_localizations.dart';
import '../widgets/km_widgets.dart';
import '../widgets/km_listing_card.dart';
import '../widgets/km_action_button.dart';
import '../theme.dart';
import '../services/content_translation_service.dart';

class RentHomePage extends StatefulWidget {
  const RentHomePage({super.key});

  @override
  State<RentHomePage> createState() => _RentHomePageState();
}

class _RentHomePageState extends State<RentHomePage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late Future<List<RentMachine>> _machinesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _machinesFuture = RentMachineService.instance.getRentMachines();
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isOwner(RentMachine m) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty && uid == m.ownerId;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.rentMachine),
        actions: [
          IconButton(
            tooltip: l.nearbyMachines,
            icon: const Icon(Icons.near_me_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RentNearbyPage()),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RentListFormPage()),
          );
          _reload();
        },
        label: Text(l.listMachine),
        icon: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KMSpacing.lg,
              KMSpacing.md,
              KMSpacing.lg,
              KMSpacing.sm,
            ),
            child: KMSearchBar(
              controller: _searchCtrl,
              hintText: l.searchByNameOwnerLocation,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              onClear: () => setState(() {
                _searchQuery = '';
                _searchCtrl.clear();
              }),
            ),
          ),

          // ── Grid ─────────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<RentMachine>>(
              future: _machinesFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final machines = snap.data!.where((m) {
                  if (_searchQuery.isEmpty) return true;
                  return m.name.toLowerCase().contains(_searchQuery) ||
                      m.type.toLowerCase().contains(_searchQuery) ||
                      m.ownerName.toLowerCase().contains(_searchQuery) ||
                      (m.location?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (machines.isEmpty) {
                  return KMEmptyState(
                    message: l.noMachinesFoundNearby,
                    icon: Icons.agriculture_outlined,
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    KMSpacing.md,
                    KMSpacing.xs,
                    KMSpacing.md,
                    KMSpacing.xl + 64,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: KMSpacing.md,
                    mainAxisSpacing: KMSpacing.md,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: machines.length,
                  itemBuilder: (_, i) {
                    final m = machines[i];
                    return KMListingCard(
                      imageUrl: m.imageUrl.isNotEmpty ? m.imageUrl : null,
                      fallbackIcon: Icons.agriculture,
                      imageHeight: 120,
                      fillHeight: true,
                      title: m.name,
                      subtitle: '₹${m.pricePerDay}${l.perDay} • ${ContentTranslationService.translateMachineType(m.type, langCode)}',
                      caption: m.location != null ? ContentTranslationService.translateLocation(m.location!, langCode) : l.locationNotAvailable,
                      menuButton: _isOwner(m)
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RentListFormPage(
                                        existingMachine: m,
                                      ),
                                    ),
                                  ).then((_) => _reload());
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l.edit),
                                ),
                              ],
                            )
                          : null,
                      infoRow: Text(
                        m.ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                      actionRow: Align(
                        alignment: Alignment.centerRight,
                        child: KMCallIconButton(onPressed: () => _call(m.phone)),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RentMachineDetailsPage(machine: m),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
