// lib/profile/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _locationController = TextEditingController();

  User? _user;
  bool _loading = false;
  bool _uploadingImage = false;
  String _selectedLanguage = 'English';
  bool _isDarkMode = false;

  // UI animation controller for subtle parallax/scale
  late final AnimationController _animController;
  late final Animation<double> _avatarScale;

  final List<String> _languages = [
    'English',
    'हिन्दी',
    'ಕನ್ನಡ',
    'தமிழ்',
    'తెలుగు',
    'मराठी'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _avatarScale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _loadUser();
    _loadExtras();
    _animController.forward();
  }

  Future<void> _loadUser() async {
    _user = FirebaseAuth.instance.currentUser;
    _displayNameController.text = _user?.displayName ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _loadExtras() async {
    _user ??= FirebaseAuth.instance.currentUser;
    if (_user == null) return;

    try {
      final map = await ProfileService.instance.getProfileFields(_user!.uid);
      _locationController.text = map['defaultLocation'] ?? '';
      _selectedLanguage = map['language'] ?? _selectedLanguage;
    } catch (_) {
      // ignore
    }

    final isDark = await ProfileService.instance.getDarkMode();
    if (mounted) {
      setState(() => _isDarkMode = isDark);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final file = File(picked.path);
      final publicUrl = await ProfileService.instance.uploadProfileImage(file);
      await ProfileService.instance.updateFirebasePhotoUrl(publicUrl);

      await FirebaseAuth.instance.currentUser?.reload();
      _user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 60, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
                Text('Update profile photo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ImageSourceButton(icon: Icons.photo_library, label: 'Gallery', onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndUploadImage(ImageSource.gallery);
                    }),
                    _ImageSourceButton(icon: Icons.camera_alt, label: 'Camera', onTap: () {
                      Navigator.of(ctx).pop();
                      _pickAndUploadImage(ImageSource.camera);
                    }),
                    _ImageSourceButton(icon: Icons.close, label: 'Cancel', onTap: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _loading = true);
    try {
      final newName = _displayNameController.text.trim();
      if (newName.isNotEmpty && newName != _user!.displayName) {
        await _user!.updateDisplayName(newName);
        await _user!.reload();
      }

      await ProfileService.instance.saveProfileFields(
        uid: _user!.uid,
        defaultLocation: _locationController.text.trim(),
        language: _selectedLanguage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
      await _loadUser();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleTheme(bool value) async {
    setState(() => _isDarkMode = value);
    await ProfileService.instance.setDarkMode(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme preference saved. Restart app to apply immediately.')));
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _locationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _user?.photoURL;
    final email = _user?.email ?? '';
    final phone = _user?.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.05),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient and avatar
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(email.isNotEmpty ? email : (phone.isNotEmpty ? phone : '—'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),

                  // Animated avatar
                  ScaleTransition(
                    scale: _avatarScale,
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Hero(
                        tag: 'profile-avatar',
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) as ImageProvider : null,
                                child: (photoUrl == null || photoUrl.isEmpty) ? Text(_initials(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)) : null,
                              ),
                            ),
                            if (_uploadingImage)
                              const Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(radius: 12, backgroundColor: Colors.white, child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))),
                              )
                            else
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(4),
                                  child: Container(decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle), padding: const EdgeInsets.all(6), child: const Icon(Icons.camera_alt, size: 12, color: Colors.white)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card: editable profile
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Personal Info', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person)),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(labelText: 'Default location', prefixIcon: Icon(Icons.place), hintText: 'e.g. Bengaluru, Karnataka'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide a default location' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedLanguage,
                                decoration: const InputDecoration(labelText: 'Preferred language', prefixIcon: Icon(Icons.language)),
                                items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                onChanged: (v) {
                                  if (v != null && mounted) setState(() => _selectedLanguage = v);
                                },
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                                      label: const Text('Save'),
                                      onPressed: _loading ? null : _updateProfile,
                                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sign out'),
                                    onPressed: _signOut,
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quick actions & settings card
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    const Icon(Icons.history, size: 28, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text('Activity', style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    const Icon(Icons.help_center, size: 28, color: Colors.orange),
                                    const SizedBox(height: 8),
                                    Text('Help', style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Settings Card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _isDarkMode,
                              onChanged: (v) => _toggleTheme(v),
                              title: const Text('Dark mode preference'),
                              subtitle: const Text('Saved locally. Restart to apply.'),
                              secondary: const Icon(Icons.brightness_6),
                            ),
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: const Text('User ID'),
                              subtitle: Text(_user?.uid ?? '-'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.verified_user_outlined),
                              title: const Text('Provider'),
                              subtitle: Text(_user?.providerData.isNotEmpty == true ? _user!.providerData.map((p) => p.providerId).join(', ') : 'firebase'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Footer small note
                    Center(
                      child: Text('KrishiMithra • v1.0', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials() {
    final name = _user?.displayName ?? '';
    if (name.trim().isEmpty) return 'KM';
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImageSourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(radius: 26, backgroundColor: const Color.fromARGB(255, 21, 27, 22), child: Icon(icon, color: Colors.green, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
