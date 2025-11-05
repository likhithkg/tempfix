import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({Key? key}) : super(key: key);

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
        child: Text(initials.toUpperCase()),
        radius: 18,
      );
    } else {
      avatarChild = const CircleAvatar(
        child: Icon(Icons.person),
        radius: 18,
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
