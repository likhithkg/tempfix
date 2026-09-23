import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    Widget avatarChild;
    if (user != null && user.photoURL != null && user.photoURL!.isNotEmpty) {
      avatarChild = CircleAvatar(
        backgroundImage: NetworkImage(user.photoURL!),
        radius: 18,
      );
    } else if (user != null && (user.displayName?.isNotEmpty ?? false)) {
      final initials = user.displayName!
          .split(' ')
          .where((s) => s.isNotEmpty)
          .map((s) => s[0])
          .take(2)
          .join();
      avatarChild = CircleAvatar(
        radius: 18,
        child: Text(initials.toUpperCase()),
      );
    } else {
      avatarChild = const CircleAvatar(
        radius: 18,
        child: Icon(Icons.person),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
        child: avatarChild,
      ),
    );
  }
}
