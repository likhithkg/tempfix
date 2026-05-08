// lib/labour_hub/labour_hub_detail_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'labour_model.dart';
import 'labour_hub_form_page.dart';
import 'hire_request_form_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LabourHubDetailPage extends StatelessWidget {
  final Labour labour;

  const LabourHubDetailPage({super.key, required this.labour});

  Future<void> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Labour Details"),
        backgroundColor: Colors.green.shade700,
        elevation: 2,

        // ▶ Three dots menu (only for owner)
        actions: [
          if (labour.createdBy == currentUserId)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabourHubFormPage(labour: labour),
                    ),
                  );
                } else if (value == 'delete') {
                  // handled in listing page; avoid delete here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Delete option available in listing page."),
                    ),
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text("Edit Labour"),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text("Delete Labour"),
                ),
              ],
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -----------------------------------
            // MAIN CARD
            // -----------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: labour.available
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      labour.available
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 40,
                      color: labour.available ? Colors.green : Colors.red,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    labour.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (labour.skill.trim().isNotEmpty)
                    Text(
                      labour.skill,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),

                  const SizedBox(height: 10),

                  Chip(
                    label: Text(
                      labour.available ? "Available" : "Not Available",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        labour.available ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------
            // DETAILS INFO CARD
            // -----------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // LOCATION
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          labour.location,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 28),

                  // CONTACT
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          labour.contact,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _callNumber(labour.contact),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------
            // CALL BUTTON
            // -----------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text("Call Labour", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _callNumber(labour.contact),
              ),
            ),

            const SizedBox(height: 14),

            // -----------------------------------
            // HIRE BUTTON
            // -----------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.work),
                label: const Text(
                  "Hire Labour",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HireRequestFormPage(
                        labourId: labour.id,
                        labourName: labour.name,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
