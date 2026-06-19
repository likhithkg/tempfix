// lib/exporter_hub/buyers_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'buyer_detail_page.dart';
import 'role_service.dart';
import '../l10n/app_localizations.dart';

class BuyersPage extends StatefulWidget {
  const BuyersPage({super.key});

  @override
  State<BuyersPage> createState() => _BuyersPageState();
}

class _BuyersPageState extends State<BuyersPage> {
  final _db = FirebaseFirestore.instance;
  String _search = '';
  String _userRole = 'farmer';

  @override
  void initState() {
    super.initState();
    RoleService.streamCurrentRole().listen((r) {
      if (mounted) setState(() => _userRole = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAdmin = RoleService.isAdmin(_userRole);

    return Scaffold(
      appBar: AppBar(title: Text(l.internationalBuyers)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.searchBuyers,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('international_buyers')
                .orderBy('companyName')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              if (_search.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['companyName']?.toString().toLowerCase() ?? '').contains(_search) ||
                      (data['country']?.toString().toLowerCase() ?? '').contains(_search) ||
                      (data['contactPerson']?.toString().toLowerCase() ?? '').contains(_search);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_outline, size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(l.noBuyersYet,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final buyerId = docs[i].id;
                  final company = data['companyName']?.toString() ?? '';
                  final country = data['country']?.toString() ?? '';
                  final contact = data['contactPerson']?.toString() ?? '';
                  final volume = data['annualVolume']?.toString() ?? '';
                  final grades = (data['preferredGrades'] as List? ?? []).join(', ');
                  final products = (data['productsInterested'] as List? ?? []).join(', ');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => BuyerDetailPage(buyerId: buyerId, data: data))),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(company.isNotEmpty ? company[0].toUpperCase() : '?',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(company, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$country • $contact'),
                        if (products.isNotEmpty) Text(products, style: const TextStyle(fontSize: 11)),
                        if (volume.isNotEmpty)
                          Text('Annual: $volume', style: const TextStyle(fontSize: 11)),
                        if (grades.isNotEmpty)
                          Text('Grades: $grades', style: const TextStyle(fontSize: 11)),
                      ]),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(context),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l.addBuyer),
            )
          : null,
    );
  }

  void _showCreateSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateBuyerSheet(db: _db),
    );
  }
}

class _CreateBuyerSheet extends StatefulWidget {
  final FirebaseFirestore db;
  const _CreateBuyerSheet({required this.db});

  @override
  State<_CreateBuyerSheet> createState() => _CreateBuyerSheetState();
}

class _CreateBuyerSheetState extends State<_CreateBuyerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _productsCtrl = TextEditingController();
  final _gradesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _companyCtrl.dispose(); _countryCtrl.dispose(); _contactCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose(); _volumeCtrl.dispose();
    _productsCtrl.dispose(); _gradesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final products = _productsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final grades = _gradesCtrl.text.split(',').map((s) => s.trim().toUpperCase()).where((s) => s.isNotEmpty).toList();
      await widget.db.collection('international_buyers').add({
        'companyName': _companyCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'contactPerson': _contactCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'annualVolume': _volumeCtrl.text.trim(),
        'productsInterested': products,
        'preferredGrades': grades,
        'createdBy': user?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.buyerAdded)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(l.addBuyer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...[
            (_companyCtrl, l.companyName, true),
            (_countryCtrl, l.countryLabel, true),
            (_contactCtrl, l.contactPerson, true),
            (_emailCtrl, l.emailLabel, false),
            (_phoneCtrl, l.phone, false),
            (_volumeCtrl, l.annualVolume, false),
            (_productsCtrl, l.productsInterestedHint, false),
            (_gradesCtrl, l.preferredGradesHint, false),
          ].map(((TextEditingController, String, bool) t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: t.$1,
                decoration: InputDecoration(labelText: t.$2, border: const OutlineInputBorder()),
                validator: t.$3 ? (v) => v!.trim().isEmpty ? 'Required' : null : null,
              ))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.addBuyer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(height: 20),
        ])),
      ),
    );
  }
}
