// lib/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

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

    // Navigate to login after 4 seconds (use named route '/login')
    _navTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
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
      // make the splash image cover entire screen
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/km.png.png', // keep the filename you use in project
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // optional subtle overlay so white text/indicators are visible
            Container(color: Colors.black.withOpacity(0.18)),
            // centered content on top of the full-screen image
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  // If you want only the image, you can remove these children.
                  // Kept small loader and app name for UX feedback.
                  Text(
                    '',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
