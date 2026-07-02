// lib/profile/profile_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../chatbot/chatbot_page.dart';
import '../exporter_hub/exporter_home_page.dart';
import '../plant_vendor/plant_vendor_home.dart';
import '../rent/rent_home_page.dart';
import '../services/locale_service.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import 'profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  User? _user;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _loadingStats = true;
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;

  int _numListings = 0;
  int _numRentals = 0;
  int _numOrders = 0;

  late final AnimationController _animCtrl;
  late final Animation<double> _avatarAnim;

  static const _languages = [
    ('English', 'en'),
    ('हिन्दी', 'hi'),
    ('ಕನ್ನಡ', 'kn'),
    ('தமிழ்', 'ta'),
    ('తెలుగు', 'te'),
    ('मराठी', 'mr'),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _avatarAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _loadAll();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    _user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = _user?.displayName ?? '';

    await Future.wait([_loadProfileFields(), _loadStats()]);
    _isDarkMode = await ProfileService.instance.getDarkMode();
    if (mounted) setState(() {});
  }

  Future<void> _loadProfileFields() async {
    if (_user == null) return;
    try {
      final map = await ProfileService.instance.getProfileFields(_user!.uid);
      if (mounted) {
        _locationCtrl.text = map['defaultLocation'] ?? '';
        _selectedLanguage = map['language'] ?? _selectedLanguage;
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    if (_user == null) return;
    final uid = _user!.uid;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('plant_vendors')
            .where('ownerId', isEqualTo: uid)
            .count()
            .get(),
        FirebaseFirestore.instance
            .collection('rent_machines')
            .where('ownerId', isEqualTo: uid)
            .count()
            .get(),
        FirebaseFirestore.instance
            .collection('purchase_orders')
            .where('farmerId', isEqualTo: uid)
            .count()
            .get(),
      ]);
      if (mounted) {
        setState(() {
          _numListings = results[0].count ?? 0;
          _numRentals = results[1].count ?? 0;
          _numOrders = results[2].count ?? 0;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploadingImage = true);
    try {
      final url =
          await ProfileService.instance.uploadProfileImage(File(picked.path));
      await ProfileService.instance.updateFirebasePhotoUrl(url);
      await FirebaseAuth.instance.currentUser?.reload();
      _user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {});
        _snack(AppLocalizations.of(context)!.profilePhotoUpdated);
      }
    } catch (e) {
      if (mounted) _snack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePickerSheet(
        onGallery: () => _pickImage(ImageSource.gallery),
        onCamera: () => _pickImage(ImageSource.camera),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty && name != _user!.displayName) {
        await _user!.updateDisplayName(name);
        await _user!.reload();
      }
      await ProfileService.instance.saveProfileFields(
        uid: _user!.uid,
        defaultLocation: _locationCtrl.text.trim(),
        language: _selectedLanguage,
      );
      _user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {});
        _snack(AppLocalizations.of(context)!.profileSaved);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleDarkMode(bool v) async {
    setState(() => _isDarkMode = v);
    await ProfileService.instance.setDarkMode(v);
    if (mounted) _snack(AppLocalizations.of(context)!.themePreferenceSaved);
  }

  Future<void> _changeLanguage(String label, String code) async {
    setState(() => _selectedLanguage = label);
    try {
      await LocaleService.instance.setLocale(Locale(code));
    } catch (_) {}
    await ProfileService.instance.saveProfileFields(
        uid: _user?.uid ?? '', language: label);
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context)!;
    final ok = await _confirm(l.signOut, 'Sign out of KrishiMithra?');
    if (!ok) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      _snack(AppLocalizations.of(context)!.passwordChangeNotAvailable);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) _snack(AppLocalizations.of(context)!.passwordResetEmailSent);
    } catch (e) {
      if (mounted) _snack('Failed: $e', isError: true);
    }
  }

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context)!;
    final ok = await _confirm(l.deleteAccountTitle, l.deleteAccountConfirm,
        isDestructive: true);
    if (!ok || _user == null) return;
    try {
      await ProfileService.instance.deleteUserData(_user!.uid);
      await _user!.delete();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    }
  }

  Future<void> _chooseLocation() async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: _locationCtrl.text);
    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.setDefaultLocation),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              hintText: l.locationHintText,
              prefixIcon: const Icon(Icons.place_outlined)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(l.save)),
        ],
      ),
    );
    if (chosen != null && chosen.isNotEmpty && mounted) {
      setState(() => _locationCtrl.text = chosen);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : null,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<bool> _confirm(String title, String body,
      {bool isDestructive = false}) async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white)
                : null,
            child: Text(isDestructive ? l.delete : l.save),
          ),
        ],
      ),
    );
    return result == true;
  }

  String get _initials {
    final n = _user?.displayName ?? '';
    if (n.trim().isEmpty) return 'KM';
    final p = n.split(' ').where((s) => s.isNotEmpty).toList();
    return p.length == 1
        ? p.first[0].toUpperCase()
        : '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? KMColors.backgroundDark : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(l, cs)),

          // ── Stats row ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsRow(l, cs, isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Account section ───────────────────────────────────────────
          SliverToBoxAdapter(
              child: _sectionLabel('Account', isDark)),
          SliverToBoxAdapter(
              child: _buildAccountCard(l, cs, isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Preferences section ───────────────────────────────────────
          SliverToBoxAdapter(
              child: _sectionLabel('Preferences', isDark)),
          SliverToBoxAdapter(
              child: _buildPreferencesCard(l, cs, isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── My Activity section ───────────────────────────────────────
          SliverToBoxAdapter(
              child: _sectionLabel('My Activity', isDark)),
          SliverToBoxAdapter(
              child: _buildActivityCard(l, cs, isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Account Management section ────────────────────────────────
          SliverToBoxAdapter(
              child: _sectionLabel('Account Management', isDark)),
          SliverToBoxAdapter(
              child: _buildManagementCard(l, cs, isDark)),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Footer ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: Text(
                'KrishiMithra v1.0  •  Made for Indian Farmers',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l, ColorScheme cs) {
    final photoUrl = _user?.photoURL;
    final email = _user?.email ?? '';
    final phone = _user?.phoneNumber ?? '';
    final contact = email.isNotEmpty ? email : (phone.isNotEmpty ? phone : '—');
    final isVerified = _user?.emailVerified == true;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(children: [
            // Top row: back button + title + more options
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(l.profile,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (v) async {
                  if (v == 'password') await _changePassword();
                  if (v == 'export') {
                    try {
                      await ProfileService.instance
                          .exportUserData(_user?.uid ?? '');
                      if (mounted) _snack(l.exportStarted);
                    } catch (e) {
                      if (mounted) _snack('Export failed: $e', isError: true);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'password',
                      child: Row(children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 10),
                        Text(l.changePassword),
                      ])),
                  PopupMenuItem(
                      value: 'export',
                      child: Row(children: [
                        const Icon(Icons.download_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(l.exportData),
                      ])),
                ],
              ),
            ]),

            const SizedBox(height: 12),

            // Avatar + name + contact
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Avatar
              ScaleTransition(
                scale: _avatarAnim,
                child: GestureDetector(
                  onTap: _showImageSheet,
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white,
                        backgroundImage: (photoUrl != null &&
                                photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(_initials,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: KMColors.primary))
                            : null,
                      ),
                    ),
                    if (_uploadingImage)
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      )
                    else
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                                color: KMColors.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),

              const SizedBox(width: 16),

              // Name + contact + verified badge
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            _user?.displayName?.isNotEmpty == true
                                ? _user!.displayName!
                                : l.appName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Colors.lightBlueAccent, size: 18),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Text(contact,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.eco_rounded,
                              color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text('KrishiMithra Farmer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(AppLocalizations l, ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      transform: Matrix4.translationValues(0, -20, 0),
      decoration: BoxDecoration(
        color: isDark ? KMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: KMShadow.card,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _loadingStats
          ? const SizedBox(
              height: 48,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : Row(children: [
              _statCell('$_numListings', l.listingsCount, cs),
              _vDivider(),
              _statCell('$_numRentals', l.rentalsCount, cs),
              _vDivider(),
              _statCell('$_numOrders', 'Orders', cs),
            ]),
    );
  }

  Widget _statCell(String value, String label, ColorScheme cs) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: KMColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.grey.shade200,
      );

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark
                ? Colors.white60
                : Colors.grey.shade600),
      ),
    );
  }

  // ── Account card ──────────────────────────────────────────────────────────

  Widget _buildAccountCard(
      AppLocalizations l, ColorScheme cs, bool isDark) {
    return _card(
      isDark,
      child: Form(
        key: _formKey,
        child: Column(children: [
          // Display name
          _EditableTile(
            icon: Icons.person_rounded,
            iconColor: cs.primary,
            label: l.displayName,
            child: TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.pleaseEnterName : null,
            ),
          ),
          _divider(),

          // Location
          _EditableTile(
            icon: Icons.place_rounded,
            iconColor: Colors.orange,
            label: l.defaultLocationLabel,
            onTap: _chooseLocation,
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: cs.onSurfaceVariant),
            child: Text(
              _locationCtrl.text.isNotEmpty
                  ? _locationCtrl.text
                  : l.locationHintText,
              style: TextStyle(
                  fontSize: 14,
                  color: _locationCtrl.text.isNotEmpty
                      ? cs.onSurface
                      : cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _divider(),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(l.saveChanges),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Preferences card ──────────────────────────────────────────────────────

  Widget _buildPreferencesCard(
      AppLocalizations l, ColorScheme cs, bool isDark) {
    return _card(
      isDark,
      child: Column(children: [
        // Language
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.language_rounded, color: Colors.purple, size: 20),
          ),
          title: Text(l.languageSetting,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(_selectedLanguage,
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          trailing: Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 18),
          onTap: () => _showLanguagePicker(cs),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        ),
        _divider(),

        // Dark mode
        SwitchListTile(
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.brightness_6_rounded,
                color: Colors.indigo, size: 20),
          ),
          title: Text(l.darkMode,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(l.darkModeSavedLocally,
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          value: _isDarkMode,
          onChanged: _toggleDarkMode,
          activeThumbColor: cs.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      ]),
    );
  }

  void _showLanguagePicker(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        const Text('Select Language',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._languages.map((e) => ListTile(
              title: Text(e.$1,
                  style: TextStyle(
                      fontWeight: e.$1 == _selectedLanguage
                          ? FontWeight.bold
                          : FontWeight.normal)),
              trailing: e.$1 == _selectedLanguage
                  ? Icon(Icons.check_rounded, color: cs.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _changeLanguage(e.$1, e.$2);
              },
            )),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── Activity card ─────────────────────────────────────────────────────────

  Widget _buildActivityCard(
      AppLocalizations l, ColorScheme cs, bool isDark) {
    return _card(
      isDark,
      child: Column(children: [
        _NavTile(
          icon: Icons.local_florist_rounded,
          iconColor: const Color(0xFF2E7D32),
          label: 'My Plant Listings',
          subtitle: '$_numListings active listings',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PlantVendorHome())),
        ),
        _divider(),
        _NavTile(
          icon: Icons.agriculture_rounded,
          iconColor: Colors.brown,
          label: 'My Rent Machines',
          subtitle: '$_numRentals machines listed',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RentHomePage())),
        ),
        _divider(),
        _NavTile(
          icon: Icons.local_shipping_rounded,
          iconColor: const Color(0xFF004D40),
          label: 'My Export Orders',
          subtitle: '$_numOrders orders placed',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ExporterHomePage())),
        ),
        _divider(),
        _NavTile(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: Colors.indigo,
          label: 'AI Chat History',
          subtitle: 'View past conversations with KrishiMithra AI',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatbotPage())),
        ),
      ]),
    );
  }

  // ── Management card ───────────────────────────────────────────────────────

  Widget _buildManagementCard(
      AppLocalizations l, ColorScheme cs, bool isDark) {
    return _card(
      isDark,
      child: Column(children: [
        // Account info (read-only)
        ListTile(
          leading: _iconBox(Icons.badge_outlined, Colors.blueGrey),
          title: Text(l.userId,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(
            _user?.uid ?? '—',
            style: const TextStyle(
                fontSize: 11, color: KMColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
        _divider(),
        ListTile(
          leading: _iconBox(Icons.verified_user_outlined, Colors.teal),
          title: Text(l.providerLabel,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(
            _user?.providerData.isNotEmpty == true
                ? _user!.providerData
                    .map((p) => p.providerId.replaceAll('.com', ''))
                    .join(', ')
                : 'email',
            style: const TextStyle(
                fontSize: 12, color: KMColors.textSecondary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
        _divider(),

        // Sign out
        ListTile(
          leading: _iconBox(Icons.logout_rounded, Colors.orange),
          title: Text(l.signOut,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange)),
          onTap: _signOut,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          trailing: Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 18),
        ),
        _divider(),

        // Delete account
        ListTile(
          leading: _iconBox(Icons.delete_forever_rounded, Colors.red),
          title: Text(l.deleteAccount,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red)),
          subtitle: Text('Permanently removes your data',
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant)),
          onTap: _deleteAccount,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          trailing: Icon(Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant, size: 18),
        ),
      ]),
    );
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? KMColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: KMShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1, indent: 60, color: Colors.grey.withValues(alpha: 0.15));

  Widget _iconBox(IconData icon, Color color) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      );
}

// ── Editable tile ─────────────────────────────────────────────────────────────

class _EditableTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _EditableTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  child,
                ]),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ]),
      ),
    );
  }
}

// ── Navigation tile ───────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurfaceVariant, size: 18),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    );
  }
}

// ── Image picker sheet ────────────────────────────────────────────────────────

class _ImagePickerSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _ImagePickerSheet({required this.onGallery, required this.onCamera});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Text(l.updateProfilePhoto,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _SheetButton(
              icon: Icons.photo_library_rounded,
              label: l.gallery,
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
            _SheetButton(
              icon: Icons.camera_alt_rounded,
              label: l.camera,
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
            _SheetButton(
              icon: Icons.close_rounded,
              label: l.cancel,
              color: Colors.grey,
              onTap: () => Navigator.pop(context),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(children: [
          CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
