import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'land_connect_constants.dart';
import 'land_discovery_page.dart';
import 'land_listing_form_page.dart';
import 'my_land_page.dart';
import 'my_requests_page.dart';
import 'incoming_requests_page.dart';

const _kPrimary = Color(kLcPrimary);
const _kDark = Color(kLcDark);

class LandConnectHomePage extends StatelessWidget {
  const LandConnectHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _kPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kDark, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.landscape_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.lcTitle,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Find land. Find cultivators. Grow together.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            l.lcDisclaimerText,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Primary CTAs ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _BigActionCard(
                          icon: Icons.agriculture_rounded,
                          label: l.lcHaveLand,
                          sublabel: l.lcHaveLandSub,
                          gradient: const LinearGradient(
                            colors: [_kDark, _kPrimary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            if (user == null) {
                              _showSignInSnack(context);
                              return;
                            }
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const LandListingFormPage()));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BigActionCard(
                          icon: Icons.search_rounded,
                          label: l.lcFindLand,
                          sublabel: l.lcFindLandSub,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), KMColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LandDiscoveryPage())),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Section: Manage ───────────────────────────────────────
                  const _SectionLabel('Manage'),
                  const SizedBox(height: 10),

                  _MenuTile(
                    icon: Icons.list_alt_rounded,
                    label: l.lcMyListings,
                    subtitle: l.lcMyListingsSub,
                    color: _kPrimary,
                    onTap: () {
                      if (user == null) { _showSignInSnack(context); return; }
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyLandPage()));
                    },
                  ),
                  _MenuTile(
                    icon: Icons.inbox_rounded,
                    label: l.lcCultivationRequests,
                    subtitle: l.lcCultivationRequestsSub,
                    color: Colors.teal,
                    onTap: () {
                      if (user == null) { _showSignInSnack(context); return; }
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const IncomingRequestsPage()));
                    },
                  ),
                  _MenuTile(
                    icon: Icons.send_rounded,
                    label: l.lcMyRequests,
                    subtitle: l.lcMyRequestsSub,
                    color: Colors.indigo,
                    onTap: () {
                      if (user == null) { _showSignInSnack(context); return; }
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MyRequestsPage()));
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── How it works ──────────────────────────────────────────
                  _SectionLabel(l.lcHowItWorks),
                  const SizedBox(height: 10),
                  _HowItWorksCard(cs: cs),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignInSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to continue')),
    );
  }
}

// ── Big action card ───────────────────────────────────────────────────────────

class _BigActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _BigActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(sublabel, style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

// ── Menu tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surface,
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}

// ── How it works ─────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  final ColorScheme cs;
  const _HowItWorksCard({required this.cs});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.add_box_outlined, _kPrimary, 'Landowner lists unused land with details'),
      (Icons.search_outlined, KMColors.primary, 'Cultivator finds matching land nearby'),
      (Icons.send_outlined, Colors.indigo, 'Cultivator sends cultivation request'),
      (Icons.check_circle_outline, Colors.teal, 'Landowner accepts and both connect'),
      (Icons.handshake_outlined, Colors.orange, 'Parties agree on terms and cultivation begins'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KMShadow.card,
      ),
      child: Column(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final (icon, color, text) = e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text,
                  style: TextStyle(fontSize: 13, color: cs.onSurface))),
              if (i < steps.length - 1)
                const SizedBox.shrink(),
            ]),
          );
        }).toList(),
      ),
    );
  }
}
