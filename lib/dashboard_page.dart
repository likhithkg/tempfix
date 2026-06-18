import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'profile_service.dart';
import 'l10n/app_localizations.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ProfileService _profileService = ProfileService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _profileService.currentUser;

    // Keep user in sync with FirebaseAuth
    FirebaseAuth.instance.userChanges().listen((user) {
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.notLoggedIn)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("KrishiMithra",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "Sampige, Turuvekere taluk; Karnataka, 572221, India",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundImage: _user?.photoURL != null
                    ? NetworkImage(_user!.photoURL!)
                    : null,
                backgroundColor: Colors.green,
                child: _user?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),

      // Body with Firestore stream
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(_user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(AppLocalizations.of(context)!.noProfileDataFound));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 40,
                  backgroundImage: data["photoURL"] != null
                      ? NetworkImage(data["photoURL"])
                      : null,
                  backgroundColor: Colors.green,
                  child: data["photoURL"] == null
                      ? const Icon(Icons.person,
                          size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  AppLocalizations.of(context)!.welcomeUser(data["name"] ?? "Farmer"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Email
                Text(
                  data["email"] ?? "",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 8),

                // Phone
                if (data["phone"] != null && data["phone"].toString().isNotEmpty)
                  Text(
                    "📞 ${data["phone"]}",
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 8),

                // Address
                if (data["address"] != null &&
                    data["address"].toString().isNotEmpty)
                  Text(
                    "📍 ${data["address"]}",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}