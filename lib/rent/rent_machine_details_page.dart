// lib/rent/rent_machine_details_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rent_model.dart';
import 'rent_list_form_page.dart';
import '../l10n/app_localizations.dart';
import '../services/content_translation_service.dart';

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'tractor': return const Color(0xFFBF360C);
    case 'harvester': return const Color(0xFF4A148C);
    case 'sprayer': return const Color(0xFF1565C0);
    case 'rotavator': return const Color(0xFF1B5E20);
    case 'transplanter': return const Color(0xFF006064);
    case 'thresher': return const Color(0xFFE65100);
    case 'pump set': return const Color(0xFF0277BD);
    default: return const Color(0xFF455A64);
  }
}

class RentMachineDetailsPage extends StatelessWidget {
  final RentMachine machine;
  const RentMachineDetailsPage({super.key, required this.machine});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open dialer')));
    }
  }

  Future<void> _whatsapp(BuildContext context, String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = uid != null && uid == machine.ownerId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final typeColor = _typeColor(machine.type);
    final hasImage = machine.imageUrl.isNotEmpty;
    final translatedType = ContentTranslationService.translateMachineType(
        machine.type, langCode);
    final translatedLocation = machine.location != null
        ? ContentTranslationService.translateLocation(
            machine.location!, langCode)
        : null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F3F0),
      body: CustomScrollView(slivers: [
        // ── Hero image ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroImage(
            machine: machine,
            topPad: topPad,
            typeColor: typeColor,
            hasImage: hasImage,
            isOwner: isOwner,
            translatedType: translatedType,
            onBack: () => Navigator.maybePop(context),
            onEdit: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    RentListFormPage(existingMachine: machine))),
          ),
        ),

        // ── Price + title banner ────────────────────────────────────────
        SliverToBoxAdapter(
          child: _TitleBanner(
              machine: machine, isDark: isDark, typeColor: typeColor,
              translatedType: translatedType),
        ),

        // ── Stats row ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsRow(machine: machine, isDark: isDark),
        ),

        // ── Owner card ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoCard(
            title: 'Owner Details',
            isDark: isDark,
            child: Column(children: [
              _DetailRow(
                icon: Icons.person_rounded,
                color: const Color(0xFFBF360C),
                label: l.ownerLabel,
                value: machine.ownerName,
              ),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _DetailRow(
                icon: Icons.phone_rounded,
                color: const Color(0xFF1565C0),
                label: l.mobileLabel,
                value: machine.phone,
                trailing: IconButton(
                  icon: const Icon(Icons.call_rounded,
                      color: Color(0xFF1B5E20)),
                  onPressed: () => _call(context, machine.phone),
                ),
              ),
            ]),
          ),
        ),

        // ── Machine details ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoCard(
            title: 'Machine Details',
            isDark: isDark,
            child: Column(children: [
              _DetailRow(
                icon: Icons.agriculture_rounded,
                color: typeColor,
                label: l.machineTypeLabel,
                value: translatedType,
              ),
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _DetailRow(
                icon: Icons.currency_rupee_rounded,
                color: const Color(0xFF388E3C),
                label: l.pricePerDayLabel,
                value:
                    '₹${machine.pricePerDay.toStringAsFixed(0)} per day',
              ),
              if (translatedLocation != null) ...[
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFFBF360C),
                  label: l.locationLabel,
                  value: translatedLocation,
                ),
              ],
              const Divider(height: 20, color: Color(0xFFF0F0F0)),
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF7B1FA2),
                label: 'Listed On',
                value: _formatDate(machine.createdAt),
              ),
            ]),
          ),
        ),

        // ── Bottom padding ──────────────────────────────────────────────
        SliverToBoxAdapter(child: SizedBox(height: botPad + 88)),
      ]),

      // ── Bottom action bar ────────────────────────────────────────────
      bottomNavigationBar: _BottomBar(
        isDark: isDark,
        botPad: botPad,
        onCall: () => _call(context, machine.phone),
        onWhatsApp: () => _whatsapp(context, machine.phone),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Hero image ────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final RentMachine machine;
  final double topPad;
  final Color typeColor;
  final bool hasImage, isOwner;
  final String translatedType;
  final VoidCallback onBack, onEdit;
  const _HeroImage({
    required this.machine, required this.topPad, required this.typeColor,
    required this.hasImage, required this.isOwner,
    required this.translatedType, required this.onBack, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(fit: StackFit.expand, children: [
        // Image or gradient
        hasImage
            ? Image.network(
                machine.imageUrl, fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child
                        : Container(color: typeColor.withValues(alpha: 0.15),
                            child: const Center(
                                child: CircularProgressIndicator())),
                errorBuilder: (_, __, ___) =>
                    _GradientBg(color: typeColor),
              )
            : _GradientBg(color: typeColor),
        // Gradient overlay (bottom)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent,
                    Colors.black.withValues(alpha: 0.55)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Back button
        Positioned(
          top: topPad + 8, left: 12,
          child: _CircleBtn(icon: Icons.arrow_back_rounded,
              onTap: onBack),
        ),
        // Edit button (owner only)
        if (isOwner)
          Positioned(
            top: topPad + 8, right: 12,
            child: _CircleBtn(icon: Icons.edit_rounded, onTap: onEdit),
          ),
        // Type badge bottom-left
        Positioned(
          bottom: 14, left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(translatedType,
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

class _GradientBg extends StatelessWidget {
  final Color color;
  const _GradientBg({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.agriculture_rounded,
            size: 90, color: Colors.white.withValues(alpha: 0.28)),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Title banner ──────────────────────────────────────────────────────────

class _TitleBanner extends StatelessWidget {
  final RentMachine machine;
  final bool isDark;
  final Color typeColor;
  final String translatedType;
  const _TitleBanner({required this.machine, required this.isDark,
      required this.typeColor, required this.translatedType});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F3F0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(machine.name,
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w900)),
            if (machine.location != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(machine.location!,
                      style: const TextStyle(fontSize: 12,
                          color: Color(0xFF9E9E9E)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: typeColor.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            Text('₹${machine.pricePerDay.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: typeColor)),
            Text('per day',
                style: const TextStyle(fontSize: 9.5,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final RentMachine machine;
  final bool isDark;
  const _StatsRow({required this.machine, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F3F0),
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
            value: '₹${machine.pricePerDay.toStringAsFixed(0)}',
            unit: '/day',
            label: 'Price',
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF388E3C),
          )),
          Container(width: 1, height: 44, color: const Color(0xFFF0F0F0)),
          Expanded(child: _StatCell(
            value: ContentTranslationService.translateMachineType(
                machine.type, langCode),
            unit: '',
            label: 'Type',
            icon: Icons.agriculture_rounded,
            color: _typeColor(machine.type),
          )),
          Container(width: 1, height: 44, color: const Color(0xFFF0F0F0)),
          Expanded(child: _StatCell(
            value: machine.ownerName.split(' ').first,
            unit: '',
            label: 'Owner',
            icon: Icons.person_rounded,
            color: const Color(0xFFBF360C),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                color: color)),
        if (unit.isNotEmpty)
          TextSpan(text: unit,
              style: const TextStyle(fontSize: 10,
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
              fontWeight: FontWeight.w800, color: Color(0xFFBF360C),
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

// ─── Bottom action bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isDark;
  final double botPad;
  final VoidCallback onCall, onWhatsApp;
  const _BottomBar({required this.isDark, required this.botPad,
      required this.onCall, required this.onWhatsApp});

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
              foregroundColor: const Color(0xFFBF360C),
              side: const BorderSide(color: Color(0xFFBF360C), width: 1.5),
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
            onPressed: onWhatsApp,
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
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
