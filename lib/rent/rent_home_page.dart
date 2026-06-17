// lib/rent/rent_home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:krishimithra/rent/rent_model.dart';
import 'package:krishimithra/rent/rent_machine_service.dart';
import 'rent_list_form_page.dart';
import 'rent_nearby_page.dart';
import 'rent_machine_details_page.dart'; // ✅ ADDED

class RentHomePage extends StatefulWidget {
  const RentHomePage({super.key});

  @override
  State<RentHomePage> createState() => _RentHomePageState();
}

class _RentHomePageState extends State<RentHomePage> {
  final _searchCtrl = TextEditingController();

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

  bool _isOwner(RentMachine m) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.isNotEmpty && uid == m.ownerId;
  }

  Future<List<RentMachine>> _loadMachines() {
    return RentMachineService.instance.getRentMachines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ✅ ONLY CHANGE HERE (NEARBY BUTTON ADDED)
      appBar: AppBar(
        title: const Text('Rent Machine'),
        actions: [
          IconButton(
            tooltip: 'Nearby Machines',
            icon: const Icon(Icons.near_me_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RentNearbyPage(),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RentListFormPage(),
            ),
          );
          setState(() {});
        },
        label: const Text("List Machine"),
        icon: const Icon(Icons.add),
      ),

      body: FutureBuilder<List<RentMachine>>(
        future: _loadMachines(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .75,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final machine = items[i];

              return _MachineCard(
                m: machine,
                onCall: _call,

                /// ✅ VIEW DETAILS
                onView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RentMachineDetailsPage(machine: machine),
                    ),
                  );
                },

                /// ✅ EDIT (ONLY OWNER)
                onEdit: _isOwner(machine)
                    ? () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RentListFormPage(
                              existingMachine: machine,
                            ),
                          ),
                        );
                        setState(() {});
                      }
                    : () {},

                isOwner: _isOwner(machine),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------------
// Machine Card
// ----------------------
// ----------------------
// Machine Card
// ----------------------
class _MachineCard extends StatelessWidget {
  const _MachineCard({
    required this.m,
    required this.onCall,
    required this.onEdit,
    required this.onView,
    required this.isOwner,
  });

  final RentMachine m;
  final void Function(String phone) onCall;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // =========================
                // USER UPLOADED IMAGE
                // =========================

                m.imageUrl.isNotEmpty
                    ? Image.network(
                        m.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,

                        // LOADING
                        loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                        ) {
                          if (loadingProgress ==
                              null) {
                            return child;
                          }

                          return const SizedBox(
                            height: 120,
                            child: Center(
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },

                        // ERROR
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Image.asset(
                            'assets/farmer_logo.png',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/farmer_logo.png',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),

                // =========================
                // OWNER EDIT MENU
                // =========================

                if (isOwner)
                  Positioned(
                    top: 6,
                    right: 6,
                    child:
                        PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          onEdit();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "₹${m.pricePerDay}/day",
                  ),

                  const SizedBox(height: 4),

                  Text(m.location ?? ''),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child:
                            Text(m.ownerName),
                      ),

                      IconButton(
                        onPressed: () =>
                            onCall(m.phone),
                        icon: const Icon(
                          Icons.call,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}