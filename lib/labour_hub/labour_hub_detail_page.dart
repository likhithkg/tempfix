// lib/labour_hub/labour_hub_detail_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'labour_model.dart';
import 'labour_hub_form_page.dart';
import 'hire_request_form_page.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

Color _avatarColor(String name) {
  const colors = [
    Color(0xFF1B5E20), Color(0xFFBF360C), Color(0xFF0D47A1),
    Color(0xFF4A148C), Color(0xFF006064), Color(0xFF880E4F),
    Color(0xFF4E342E), Color(0xFF37474F), Color(0xFF1565C0),
    Color(0xFFE65100),
  ];
  final code = name.isNotEmpty ? name.codeUnitAt(0) : 0;
  return colors[code % colors.length];
}

class LabourHubDetailPage extends StatelessWidget {
  final Labour labour;
  const LabourHubDetailPage({super.key, required this.labour});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = uid != null && labour.createdBy == uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    final translatedSkill = ContentTranslationService.translateLabourSkill(
        labour.skill, langCode);
    final translatedLocation =
        ContentTranslationService.translateLocation(labour.location, langCode);

    final avatarColor = _avatarColor(labour.name);
    final initial =
        labour.name.isNotEmpty ? labour.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F3),
      body: CustomScrollView(slivers: [
        // ── Hero ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroSection(
            labour: labour,
            topPad: topPad,
            avatarColor: avatarColor,
            initial: initial,
            isOwner: isOwner,
            translatedSkill: translatedSkill,
            onBack: () => Navigator.maybePop(context),
            onEdit: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => LabourHubFormPage(labour: labour))),
          ),
        ),

        // ── Stats row ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsRow(labour: labour, isDark: isDark),
        ),

        // ── About / description ──────────────────────────────────────────
        if (labour.description != null &&
            labour.description!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: _InfoCard(
              title: 'About',
              isDark: isDark,
              child: Text(labour.description!,
                  style: const TextStyle(
                      fontSize: 14, height: 1.5,
                      color: Color(0xFF555555))),
            ),
          ),

        // ── Details ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoCard(
            title: 'Details',
            isDark: isDark,
            child: Column(children: [
              _DetailRow(
                icon: Icons.location_on_rounded,
                color: const Color(0xFF388E3C),
                label: l.locationLabel,
                value: translatedLocation,
              ),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _DetailRow(
                icon: Icons.phone_rounded,
                color: const Color(0xFF1565C0),
                label: l.mobileLabel,
                value: labour.contact,
                trailing: IconButton(
                  icon: const Icon(Icons.call_rounded,
                      color: Color(0xFF1B5E20)),
                  onPressed: () => _call(context, labour.contact),
                ),
              ),
              if (labour.category != null) ...[
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _DetailRow(
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFFE65100),
                  label: 'Category',
                  value: labour.category!,
                ),
              ],
              if (labour.wageType != null && labour.wage != null) ...[
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _DetailRow(
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF388E3C),
                  label: 'Wage',
                  value:
                      '₹${labour.wage!.toStringAsFixed(0)} per ${labour.wageType}',
                ),
              ],
              if (labour.postedAt != null) ...[
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF7B1FA2),
                  label: 'Posted On',
                  value: _formatDate(labour.postedAt!),
                ),
              ],
            ]),
          ),
        ),

        // ── Skills / tags ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoCard(
            title: 'Skills & Tags',
            isDark: isDark,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _SkillTag(label: labour.skill,
                  color: const Color(0xFF1B5E20)),
              if (labour.category != null)
                _SkillTag(label: labour.category!,
                    color: const Color(0xFFE65100)),
              if (labour.experience != null)
                _SkillTag(
                    label: '${labour.experience} years experience',
                    color: const Color(0xFF1565C0)),
              if (labour.available)
                _SkillTag(label: 'Available Now',
                    color: const Color(0xFF2E7D32))
              else
                _SkillTag(label: 'Currently Busy',
                    color: const Color(0xFFB71C1C)),
            ]),
          ),
        ),

        // ── Bottom padding for action bar ────────────────────────────────
        SliverToBoxAdapter(child: SizedBox(height: botPad + 88)),
      ]),

      // ── Bottom action bar ──────────────────────────────────────────────
      bottomNavigationBar: _BottomActions(
        labour: labour,
        botPad: botPad,
        isDark: isDark,
        onCall: () => _call(context, labour.contact),
        onHire: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => HireRequestFormPage(
                labourId: labour.id, labourName: labour.name))),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Hero section ──────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Labour labour;
  final double topPad;
  final Color avatarColor;
  final String initial, translatedSkill;
  final bool isOwner;
  final VoidCallback onBack, onEdit;

  const _HeroSection({
    required this.labour, required this.topPad, required this.avatarColor,
    required this.initial, required this.translatedSkill,
    required this.isOwner, required this.onBack, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [avatarColor, avatarColor.withValues(alpha: 0.75)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(children: [
        // Nav bar
        Padding(
          padding: EdgeInsets.fromLTRB(4, topPad + 4, 4, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: onBack,
            ),
            const Expanded(child: Text('Worker Profile',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16))),
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: onEdit,
              ),
          ]),
        ),
        const SizedBox(height: 16),
        // Avatar
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white24,
            ),
            child: labour.imageUrl != null && labour.imageUrl!.isNotEmpty
                ? ClipOval(child: Image.network(
                    labour.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(initial,
                          style: const TextStyle(fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ))
                : Center(child: Text(initial,
                    style: const TextStyle(fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: labour.available
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(labour.available ? 'Available' : 'Busy',
                style: const TextStyle(color: Colors.white,
                    fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 12),
        // Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(labour.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const SizedBox(height: 4),
        // Skill chip
        if (translatedSkill.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(translatedSkill,
                style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
        ],
        // Location
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(labour.location,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
        const SizedBox(height: 20),
        // Rounded bottom edge
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F3),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22)),
          ),
        ),
      ]),
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Labour labour;
  final bool isDark;
  const _StatsRow({required this.labour, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F5F3),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Expanded(child: _StatCell(
            value: labour.experience != null ? '${labour.experience}' : '—',
            unit: labour.experience != null ? 'Yrs' : '',
            label: 'Experience',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF1565C0),
          )),
          Container(width: 1, height: 44, color: const Color(0xFFF0F0F0)),
          Expanded(child: _StatCell(
            value: labour.wage != null
                ? '₹${labour.wage!.toStringAsFixed(0)}' : '—',
            unit: labour.wageType ?? '',
            label: 'Wage',
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF388E3C),
          )),
          Container(width: 1, height: 44, color: const Color(0xFFF0F0F0)),
          Expanded(child: _StatCell(
            value: (labour.rating != null && labour.rating! > 0)
                ? labour.rating!.toStringAsFixed(1) : '—',
            unit: (labour.rating != null && labour.rating! > 0) ? '/5' : '',
            label: 'Rating',
            icon: Icons.star_rounded,
            color: const Color(0xFFFF8F00),
          )),
        ]),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, unit, label;
  final IconData icon;
  final Color color;
  const _StatCell({required this.value, required this.unit,
      required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      RichText(text: TextSpan(children: [
        TextSpan(text: value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                color: color)),
        if (unit.isNotEmpty)
          TextSpan(text: ' $unit',
              style: const TextStyle(fontSize: 11,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w600)),
      ])),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10.5,
          color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Info card ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _InfoCard(
      {required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w800, color: Color(0xFF1B5E20),
              letterSpacing: 0.3)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Detail row ────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final Widget? trailing;
  const _DetailRow({required this.icon, required this.color,
      required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10,
              color: Color(0xFF9E9E9E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14,
              fontWeight: FontWeight.w600)),
        ],
      )),
      if (trailing != null) trailing!,
    ]);
  }
}

// ─── Skill tag ─────────────────────────────────────────────────────────────

class _SkillTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SkillTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12,
          fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── Bottom action bar ─────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final Labour labour;
  final double botPad;
  final bool isDark;
  final VoidCallback onCall, onHire;
  const _BottomActions({required this.labour, required this.botPad,
      required this.isDark, required this.onCall, required this.onHire});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, botPad + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.phone_rounded, size: 18),
            label: const Text('Call',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B5E20),
              side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: labour.available ? onHire : null,
            icon: const Icon(Icons.work_rounded, size: 18),
            label: Text(
              labour.available ? 'Hire Now' : 'Not Available',
              style: const TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}
