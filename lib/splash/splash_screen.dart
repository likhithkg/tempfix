import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../home/home_page.dart';
import '../public/landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // On web, give Firebase a moment to restore auth state before navigating.
    // On mobile the auth state is available immediately from local cache.
    final delay = kIsWeb
        ? const Duration(milliseconds: 1800)
        : const Duration(milliseconds: 1400);

    _navTimer = Timer(delay, () {
      if (!mounted) return;
      _navigate();
    });
  }

  void _navigate() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Already signed in — go directly to the main app.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KrishiMithraHome()),
      );
    } else {
      // Not signed in — show the public landing page first.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
      );
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/km.png.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco_rounded, color: Colors.white, size: 80),
                      SizedBox(height: 16),
                      Text('KrishiMithra',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.18)),
            Positioned(
              bottom: 72,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
