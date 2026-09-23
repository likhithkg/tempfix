import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:oktoast/oktoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'firebase_options.dart';
import 'weather/weather_page.dart';
import 'rent/rent_home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';


import 'plant_vendor/plant_vendor_home.dart';
import 'labour_hub/labour_hub_home_page.dart';
import 'profile/profile_service.dart';
import 'profile/profile_button.dart'; // <-- ADD THIS
import 'crop_disease/crop_disease_page.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:google_sign_in/google_sign_in.dart';
import 'theme.dart'; 
import 'splash/splash_screen.dart';
import 'export_hub/export_hub_page.dart';
import 'chatbot/chatbot_page.dart';
import 'f2b_mart/f2b_home_page.dart';
import 'home/home_page.dart';
import 'config/km_images.dart';






// Import your app widget
// import 'your_app_file.dart'; // if KrishiMithraApp is in a different file adjust the import
// If KrishiMithraApp is in the same file, no extra import needed.

// ensureInitialized and runApp MUST be in the same zone to avoid zone-mismatch
// errors from Supabase's async auth listeners on web. The fix: do everything
// inside a single runZonedGuarded with an async callback.
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('FlutterError caught: ${details.exception}\n${details.stack}');
    };

    Object? initError;
    StackTrace? initStack;

    // 1. Firebase (must be first — scopes theme prefs to UID)
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e, st) {
      initError = e;
      initStack = st;
      print('*** Firebase initialization error:\n$e\n$st');
    }

    // 2. Load dark mode preference
    final prefs = await SharedPreferences.getInstance();
    final startupUid = fb.FirebaseAuth.instance.currentUser?.uid;
    final darkKey = startupUid != null ? 'isDarkMode_$startupUid' : 'isDarkMode';
    final isDark = prefs.getBool(darkKey) ?? false;
    ProfileService.instance.themeModeNotifier.value =
        isDark ? ThemeMode.dark : ThemeMode.light;

    // 3. Locale
    await LocaleService.instance.init();

    // 4. Supabase
    if (initError == null) {
      try {
        await sb.Supabase.initialize(
          url: 'https://ticpdepakqlizhdwgxtz.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpY3BkZXBha3FsaXpoZHd3Z3h0eiIsInJvbGUiOiJhbmlvbiIsImlhdCI6MTc1MzcxNDI0MywiZXhwIjoyMDY5MjkwMjQzfQ.WdBMFR3z-mugqp7qLhOgWuHVh782ykZv4-mC2FPtKNM',
        );
      } catch (e, st) {
        initError = e;
        initStack = st;
        print('*** App initialization error:\n$e\n$st');
      }
    }

    // 5. runApp — same zone as ensureInitialized above
    if (initError != null) {
      runApp(ErrorApp(isDark: isDark, error: initError, stack: initStack));
    } else {
      runApp(const KrishiMithraApp());
    }
  }, (error, stack) {
    print('Uncaught zone error: $error\n$stack');
  });
}

/// Sends the Firebase ID token to the backend so it can find/create the user
/// in MongoDB. Non-fatal — Firebase is the auth source of truth.
Future<void> _syncUserWithBackend(fb.User? user) async {
  if (user == null) return;
  try {
    final token = await user.getIdToken(true);
    await http.post(
      Uri.parse('https://km-backend-ug96.onrender.com/api/auth/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 45));
  } catch (_) {
    // Non-fatal — the app still works via Firebase even if backend sync fails.
  }
}

/// A tiny MaterialApp that shows a readable error screen.
/// Paste or keep this in main.dart — it's used only when initialization fails.
class ErrorApp extends StatelessWidget {
  final bool isDark;
  final Object error;
  final StackTrace? stack;
  const ErrorApp({super.key, required this.isDark, required this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: Colors.green,
    );

    return MaterialApp(
      title: 'KrishiMithra — Init Error',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: ErrorScreen(error: error, stack: stack),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  const ErrorScreen({super.key, required this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initialization Error'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'The app failed to start properly.',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Error (short):\n${error.toString()}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Stack (truncated):',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stack?.toString().split('\n').take(12).join('\n') ?? 'No stack available',
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // copy to clipboard or print again
                  print('Error copied: $error\n$stack');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error printed to logs (adb logcat).')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('Print error to logs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class KrishiMithraApp extends StatelessWidget {
  const KrishiMithraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ProfileService.instance.themeModeNotifier,
        builder: (context, themeMode, _) => ValueListenableBuilder<Locale?>(
          valueListenable: LocaleService.instance.localeNotifier,
          builder: (context, locale, _) {
          return MaterialApp(
            title: 'KrishiMithra',
            theme: kmLightTheme,
            darkTheme: kmDarkTheme,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('kn'),
              Locale('ta'),
              Locale('te'),
              Locale('mr'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Swap Nunito out for the platform default font on Indic locales.
            // Nunito has no Kannada/Telugu/Devanagari/Tamil glyphs; without
            // this the localized strings render as garbled à²... sequences.
            builder: (context, child) {
              const indicLocales = {'hi', 'kn', 'ta', 'te', 'mr'};
              final lang = Localizations.localeOf(context).languageCode;
              if (indicLocales.contains(lang)) {
                final theme = Theme.of(context);
                return Theme(
                  data: theme.copyWith(
                    textTheme: kmStripFontFamily(theme.textTheme),
                    appBarTheme: theme.appBarTheme.copyWith(
                      titleTextStyle:
                          kmStripFont(theme.appBarTheme.titleTextStyle),
                    ),
                  ),
                  child: child!,
                );
              }
              return child!;
            },
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginPage(),
            },
          );
        },
      ),
    ),
  );
  }
}

//
// ✅ WELCOME PAGE
//


// Main LoginPage with tabs
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              KMImages.loginBg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [KMColors.primaryDark, KMColors.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Gradient overlay: darker at top for readability, lighter at bottom
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.20),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  // ── Branded header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Center(
                          child: Image.asset('assets/leaves.png', width: 34, height: 34,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.eco_rounded, color: Colors.white, size: 30)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('KrishiMithra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(l.appTagline,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // ── Login method tabs ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        indicator: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                        tabs: [
                          Tab(icon: const Icon(Icons.email_outlined, size: 16), text: l.email, height: 40),
                          Tab(icon: const Icon(Icons.phone_outlined, size: 16), text: l.phone, height: 40),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        EmailLoginPage(),
                        PhoneLoginPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// Email Login Tab
//
class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;

  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);
    try {
      fb.UserCredential uc;

      if (kIsWeb) {
        // Web: Firebase Auth handles the OAuth popup directly — no extra package needed
        final provider = fb.GoogleAuthProvider();
        uc = await fb.FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Android / iOS: use the google_sign_in package for native account picker
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => loading = false);
          return; // user cancelled the picker
        }
        final googleAuth = await googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        uc = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      }

      await _saveGoogleUserToFirestore(uc.user);
      await _syncUserWithBackend(uc.user);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KrishiMithraHome()));
    } on fb.FirebaseAuthException catch (e) {
      showToast("Google sign-in failed: ${e.message ?? e.code}");
    } catch (e) {
      showToast("Google sign-in failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveGoogleUserToFirestore(fb.User? user) async {
    if (user == null) return;
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'authProvider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      showToast("Please enter email and password");
      return;
    }

    setState(() => loading = true);
    try {
      await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await _syncUserWithBackend(fb.FirebaseAuth.instance.currentUser);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KrishiMithraHome()));
    } on fb.FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => "No user found with that email",
        'wrong-password' || 'invalid-credential' => "Incorrect password",
        'invalid-email' => "Invalid email address",
        'user-disabled' => "This account has been disabled",
        'too-many-requests' => "Too many failed attempts. Try later",
        'network-request-failed' => "Network error. Check your connection",
        _ => "Login failed: ${e.message ?? e.code}",
      };
      showToast(msg);
    } catch (e) {
      showToast("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            elevation: 16,
            color: Theme.of(context).cardColor.withValues(alpha: 0.96),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.loginEmail,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, fontSize: 22, color: primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back to KrishiMithra',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      prefixIcon: Icon(Icons.email_outlined, color: primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                      filled: true,
                      fillColor: primary.withValues(alpha: 0.04),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                      filled: true,
                      fillColor: primary.withValues(alpha: 0.04),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
                      child: Text('Forgot Password?', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: loading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('G',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
                          const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                        child: Text('Sign Up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//
// Phone Login Tab (OTP)
//
class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});
  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  String phone = '';
  String verificationId = '';
  final otpController = TextEditingController();
  bool otpSent = false;
  bool loading = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _resendCountdown--);
      if (_resendCountdown <= 0) timer.cancel();
    });
  }

  String _friendlyPhoneError(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-phone-number' => 'Invalid phone number format',
      'too-many-requests' => 'Too many attempts. Try again later',
      'network-request-failed' => 'Network error. Check your connection',
      'captcha-check-failed' => 'Verification failed. Try again',
      'quota-exceeded' => 'SMS quota exceeded. Try later',
      'invalid-verification-code' => 'Incorrect OTP. Please try again',
      'session-expired' => 'OTP expired. Tap Resend OTP',
      _ => e.message ?? 'Authentication failed',
    };
  }

  void sendOTP() async {
    if (phone.trim().isEmpty) {
      showToast("Enter phone number");
      return;
    }
    setState(() { loading = true; otpSent = false; });
    otpController.clear();

    // On Flutter Web, verifyPhoneNumber can throw a FirebaseAuthException directly
    // (e.g. reCAPTCHA failure, unauthorized domain) instead of calling verificationFailed.
    // The try-catch here is required on web; on mobile it only handles unexpected errors.
    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (cred) async {
          // Only fires on Android (auto-SMS-retrieval). Not called on web.
          try {
            await fb.FirebaseAuth.instance.signInWithCredential(cred);
            await _saveUserToFirestore();
            await _syncUserWithBackend(fb.FirebaseAuth.instance.currentUser);
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const KrishiMithraHome()),
            );
          } catch (e) {
            if (mounted) {
              showToast("Auto sign-in failed: $e");
              setState(() => loading = false);
            }
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          // Show actual Firebase error code so it's diagnosable during development.
          debugPrint('📱 verificationFailed [${e.code}]: ${e.message}');
          if (mounted) {
            showToast('[${e.code}] ${e.message ?? "Verification failed"}');
            setState(() => loading = false);
          }
        },
        codeSent: (String id, int? resendToken) {
          verificationId = id;
          if (mounted) setState(() { otpSent = true; loading = false; });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      // Catches exceptions thrown directly by verifyPhoneNumber on Flutter Web.
      debugPrint('📱 sendOTP direct throw: $e');
      String msg;
      if (e is fb.FirebaseAuthException) {
        debugPrint('📱 code=${e.code}  msg=${e.message}');
        msg = '[${e.code}] ${e.message ?? "Firebase auth failed"}';
      } else {
        msg = 'Phone auth error: $e';
      }
      if (mounted) {
        showToast(msg);
        setState(() => loading = false);
      }
    }
  }

  void verifyOTP() async {
    if (otpController.text.trim().isEmpty) {
      showToast("Enter OTP");
      return;
    }
    setState(() => loading = true);
    try {
      final cred = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );
      await fb.FirebaseAuth.instance.signInWithCredential(cred);
      await _saveUserToFirestore();
      await _syncUserWithBackend(fb.FirebaseAuth.instance.currentUser);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const KrishiMithraHome()));
    } on fb.FirebaseAuthException catch (e) {
      showToast(_friendlyPhoneError(e));
    } catch (e) {
      showToast("Verification failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveUserToFirestore() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await doc.get();
      if (!snapshot.exists) {
        await doc.set({
          "uid": user.uid,
          "phone": user.phoneNumber,
          "authProvider": "phone",
          "createdAt": FieldValue.serverTimestamp(),
        });
      } else {
        await doc.update({"lastLoginAt": FieldValue.serverTimestamp()});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Card(
          elevation: 14,
          color: Theme.of(context).cardColor.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Text(AppLocalizations.of(context)!.phoneLogin, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
                if (otpSent)
                  Column(
                    children: [
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.enterOtp,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(AppLocalizations.of(context)!.verifyOtp),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: (_resendCountdown > 0 || loading) ? null : sendOTP,
                        child: Text(
                          _resendCountdown > 0
                              ? "Resend OTP in ${_resendCountdown}s"
                              : "Resend OTP",
                          style: TextStyle(
                            color: _resendCountdown > 0
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (val) => phone = val.completeNumber,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Send OTP"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// Sign Up Page
//
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;

  void register() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      showToast("Please fill all fields");
      return;
    }
    setState(() => loading = true);
    try {
      fb.UserCredential userCredential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('userProfile')
            .doc(user.uid)
            .set({
          'email': user.email,
          'phone': user.phoneNumber,
          'authProvider': 'email',
          'createdAt': FieldValue.serverTimestamp(),
          'defaultLocation': null,
          'preferences': {},
        });
        await _syncUserWithBackend(user);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KrishiMithraHome()),
      );
    } on fb.FirebaseAuthException catch (e) {
      showToast("Sign-up failed: ${e.message}");
    } catch (e) {
      showToast("Sign-up failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [KMColors.primaryDark, KMColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.20),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                // ── Branded header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/leaves.png', width: 34, height: 34,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KrishiMithra',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          l.appTagline,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Card(
                        elevation: 16,
                        color: Theme.of(context).cardColor.withValues(alpha: 0.96),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l.createAccount,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 22, fontWeight: FontWeight.w800, color: primary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Join the KrishiMithra community',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: l.email,
                                  prefixIcon: Icon(Icons.email_outlined, color: primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: primary.withValues(alpha: 0.04),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: l.password,
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey.shade500,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: primary.withValues(alpha: 0.04),
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: loading ? null : register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: loading
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : Text(l.createAccount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Already have an account? ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(l.login, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// Forgot Password Page
//
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;

  void sendResetLink() async {
    if (emailController.text.trim().isEmpty) {
      showToast("Please enter email");
      return;
    }
    setState(() => loading = true);
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      showToast("Password reset link sent!");
    } catch (e) {
      showToast("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/login_bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.38)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    elevation: 16,
                    color: Theme.of(context).cardColor.withValues(alpha: 0.96),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_reset_rounded, color: primary, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Reset Your Password',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 22, fontWeight: FontWeight.w800, color: primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We will send a reset link to your email',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.email,
                              prefixIcon: Icon(Icons.email_outlined, color: primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: primary, width: 2),
                              ),
                              filled: true,
                              fillColor: primary.withValues(alpha: 0.04),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: loading ? null : sendResetLink,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text(AppLocalizations.of(context)!.sendResetLink,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Back to Login', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}















class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedLocation = 'Select Location';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _recentLocations = [];

  Map<String, dynamic>? userProfile;

 final List<Map<String, dynamic>> features = [
  {"title": "Weather", "icon": Icons.cloud, "asset": "assets/icons/weather.png"},
  {"title": "export hub", "icon": Icons.terrain, "asset": "assets/icons/soil.png"},
  {"title": "F2B mart", "icon": Icons.attach_money, "asset": "assets/icons/market_prices.png"},
  {"title": "Crop Disease", "icon": Icons.bug_report, "asset": "assets/icons/crop_disease.png"},
  {"title": "Rent Machine", "icon": Icons.agriculture, "asset": "assets/icons/rent_machine.png"},
  {"title": "Plant Vendors", "icon": Icons.local_florist, "asset": "assets/icons/plant_vendors.png"},
  {"title": "Labour Hub", "icon": Icons.groups, "asset": "assets/icons/health.png"},
  {"title": "Chatbot", "icon": Icons.chat_bubble_outline, "asset": "assets/icons/chatbot.png"}, // ✅ added
];

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadRecentLocations();
    _loadUserProfile();
  }

  // ---------- Improved: load saved default location (reads both userProfile & users) ----------
  Future<void> _loadSavedLocation() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // ── Step 1: SharedPreferences (instant, offline, no permission issues) ──
    try {
      final prefs = await SharedPreferences.getInstance();
      final loc = prefs.getString('loc_name_$uid') ?? '';
      if (loc.isNotEmpty && mounted) {
        setState(() {
          selectedLocation = loc;
          _searchController.text = loc;
        });
        return; // SharedPreferences hit — no need to wait for Firestore
      }
    } catch (_) {}

    // ── Step 2: Firestore fallback (first-time or new device) ──
    for (final col in ['users', 'userProfile']) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(col)
            .doc(uid)
            .get();
        if (!doc.exists) continue;
        final data = doc.data()!;
        final location = data['defaultLocation']?.toString() ??
            data['default_location']?.toString() ?? '';
        if (location.isEmpty) continue;
        final lat = (data['defaultLat'] ?? data['default_lat']) as num?;
        final lon = (data['defaultLon'] ?? data['default_lon']) as num?;
        if (mounted) {
          setState(() {
            selectedLocation = location;
            _searchController.text = location;
          });
        }
        // Mirror to SharedPreferences so next cold start is instant
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loc_name_$uid', location);
          if (lat != null) await prefs.setDouble('loc_lat_$uid', lat.toDouble());
          if (lon != null) await prefs.setDouble('loc_lon_$uid', lon.toDouble());
        } catch (_) {}
        return;
      } catch (_) {
        continue;
      }
    }
  }

  // ---------- Improved: load recent locations (per-user, local then Firestore) ----------
  Future<void> _loadRecentLocations() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    // Load from per-user SharedPreferences key first for instant UI
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getStringList('recent_locations_$uid') ?? [];
      if (local.isNotEmpty && mounted) setState(() => _recentLocations = local);
    } catch (_) {}

    // Sync from Firestore for cross-device persistence
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data()?['recentLocations'] != null) {
        final fromFs = (doc.data()!['recentLocations'] as List)
            .map((e) => e.toString())
            .toList();
        if (fromFs.isNotEmpty && mounted) {
          setState(() => _recentLocations = fromFs.take(8).toList());
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(
                'recent_locations_$uid', _recentLocations);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // ---------- Save selected location (SharedPreferences primary, Firestore backup) ----------
  Future<void> _saveLocation(String location) async {
    double lat = 0.0;
    double lon = 0.0;
    try {
      final coords = await LocationService.getCoordinatesFromName(location);
      lat = (coords['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (coords['lon'] as num?)?.toDouble() ?? 0.0;
    } catch (_) {}

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      // ── Primary: SharedPreferences with UID key ──
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loc_name_$uid', location);
        if (lat != 0) await prefs.setDouble('loc_lat_$uid', lat);
        if (lon != 0) await prefs.setDouble('loc_lon_$uid', lon);

        _recentLocations.remove(location);
        _recentLocations.insert(0, location);
        if (_recentLocations.length > 8) {
          _recentLocations = _recentLocations.sublist(0, 8);
        }
        await prefs.setStringList('recent_locations_$uid', _recentLocations);
      } catch (_) {}

      // ── Backup: Firestore ──
      try {
        final ref = FirebaseFirestore.instance.collection('users').doc(uid);
        await ref.set({
          'defaultLocation': location,
          'defaultLat': lat,
          'defaultLon': lon,
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        selectedLocation = location;
        _searchController.text = location;
        _recentLocations.remove(location);
        _recentLocations.insert(0, location);
        if (_recentLocations.length > 8) {
          _recentLocations = _recentLocations.sublist(0, 8);
        }
      });
    }
  }

  // ---------- Keep user profile loader (unchanged but robust) ----------
  Future<void> _loadUserProfile() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (final col in ['users', 'userProfile']) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(col)
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() => userProfile = doc.data());
          return;
        }
      } catch (_) {
        continue;
      }
    }
  }

  // ---------- Location dialog (await save before pop) ----------
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<dynamic> searchResults = [];
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> search(String text) async {
              final results = await LocationService.getSuggestions(text);
              setState(() {
                searchResults = results;
              });
            }

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectLocation),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchLocation,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => searchResults = []);
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (text) {
                            search(text);
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          final text = _searchController.text.trim();
                          if (text.isNotEmpty) {
                            await _saveLocation(text);
                            if (!mounted) return;
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_recentLocations.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.recentLocations,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        const SizedBox(height: 8),
                        ..._recentLocations.map((loc) => ListTile(
                              leading: Icon(Icons.history, color: Theme.of(context).iconTheme.color),
                              title: Text(loc),
                              onTap: () async {
                                await _saveLocation(loc);
                                if (!mounted) return;
                                Navigator.pop(context);
                              },
                            )),
                      ],
                    ),
                  if (searchResults.isNotEmpty)
                    ...searchResults.map((suggestion) {
                      final name = suggestion['display_name'] ?? 'Unknown';
                      return ListTile(
                        leading: Icon(Icons.place, color: Theme.of(context).iconTheme.color),
                        title: Text(name),
                        onTap: () async {
                          await _saveLocation(name);
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }


 @override
Widget build(BuildContext context) {
  Widget buildFeatureCard(String title, String imagePath, IconData fallbackIcon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Full card background image
            Positioned.fill(
              child: imagePath.isNotEmpty
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).cardColor,
                        child: Center(
                          child: Icon(fallbackIcon, size: 48, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    )
                  : Container(color: Theme.of(context).cardColor),
            ),

            // Subtle gradient overlay for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            // Center small icon (optional) - commented out if you don't want it
            // Center(
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 12.0),
            //     child: Image.asset(imagePath, height: 60, width: 60, errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 60)),
            //   ),
            // ),

            // Title overlay at bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: Colors.black.withValues(alpha: 0.25),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(1, 1)),
                        ],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ✅ Top header
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                      'assets/leaves.png',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
  AppLocalizations.of(context)!.appName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFamily: 'Serpentine',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          selectedLocation,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
               Row(
  children: [

    IconButton(
      icon: const Icon(Icons.language),
      onPressed: () {
        final languages = LocaleService.instance.supportedLanguages;
        final currentCode = LocaleService.instance.currentLanguageCode;
        showDialog(
          context: context,
          builder: (ctx) { final l2 = AppLocalizations.of(ctx)!; return AlertDialog(
            title: Text(l2.selectLanguage),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: languages.entries.map((entry) {
                  final isSelected = entry.value.languageCode == currentCode;
                  return ListTile(
                    title: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: KMColors.primary)
                        : null,
                    onTap: () {
                      LocaleService.instance.setLocale(entry.value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ); },
        );
      },
    ),

    // 📍 LOCATION ICON (ADD THIS)
    IconButton(
      icon: const Icon(Icons.location_on),
      onPressed: () {
        _showLocationDialog();
      },
    ),

    const ProfileButton(),
  ],
),
              ],
            ),
          ),
          Container(height: 1, color: Theme.of(context).dividerColor),
          // ✅ Features Grid
         Expanded(
  child: SingleChildScrollView(
    child: Column(
      children: [

        /// 🔥 TOP 4 FEATURES
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
  final feature = features[index];
  final String key = feature['title'];   // ✅ FIX
  String title;

switch (feature['title']) {
  case "Weather":
    title = AppLocalizations.of(context)!.weather;
    break;
  case "F2B mart":
    title = AppLocalizations.of(context)!.f2bMart;
    break;
  case "Rent Machine":
    title = AppLocalizations.of(context)!.rentMachine;
    break;
  case "Plant Vendors":
    title = AppLocalizations.of(context)!.plantVendors;
    break;
  case "Labour Hub":
    title = AppLocalizations.of(context)!.labourHub;
    break;
  case "Crop Disease":
    title = AppLocalizations.of(context)!.cropDisease;
    break;
  case "export hub":
    title = AppLocalizations.of(context)!.exportHub;
    break;
  case "Chatbot":
    title = AppLocalizations.of(context)!.chatbot;
    break;
  default:
    title = feature['title'];
}
              final IconData icon = feature['icon'] ?? Icons.help_outline;
              final String assetPath = feature['asset'] ?? '';

             VoidCallback onTap = () {
  if (key == "Weather") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherPage(location: selectedLocation),
      ),
    );
  } else if (key == "Rent Machine") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RentHomePage()));
  } else if (key == "F2B mart") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const F2BHomePage()));
  } else if (key == "Plant Vendors") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorHome()));
  } else if (key == "Labour Hub") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LabourHubHomePage()));
  } else if (key == "Crop Disease") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CropDiseasePage()));
  } else if (key == "export hub") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportHubPage()));
  } else if (key == "Chatbot") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotPage()));
  } else {
    showToast("Opening $title");
  }
};

              return buildFeatureCard(title, assetPath, icon, onTap);
            },
          ),
        ),

        /// 🔥 REMAINING FEATURES
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: features.length - 4,
            itemBuilder: (context, index) {
              final feature = features[index + 4];
              final String key = feature['title']; 
              String title;
              final IconData icon = feature['icon'] ?? Icons.help_outline;
              final String assetPath = feature['asset'] ?? '';

             VoidCallback onTap = () {
  if (key == "Weather") {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeatherPage(location: selectedLocation),
      ),
    );
  } else if (key == "Rent Machine") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RentHomePage()));
  } else if (key == "F2B mart") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const F2BHomePage()));
  } else if (key == "Plant Vendors") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorHome()));
  } else if (key == "Labour Hub") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LabourHubHomePage()));
  } else if (key == "Crop Disease") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CropDiseasePage()));
  } else if (key == "export hub") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportHubPage()));
  } else if (key == "Chatbot") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotPage()));
  } else {
    showToast("Opening $key");
  }
};

switch (key) {
  case "Weather":
    title = AppLocalizations.of(context)!.weather;
    break;
  case "F2B mart":
    title = AppLocalizations.of(context)!.f2bMart;
    break;
  case "Rent Machine":
    title = AppLocalizations.of(context)!.rentMachine;
    break;
  case "Plant Vendors":
    title = AppLocalizations.of(context)!.plantVendors;
    break;
  case "Labour Hub":
    title = AppLocalizations.of(context)!.labourHub;
    break;
  case "Crop Disease":
    title = AppLocalizations.of(context)!.cropDisease;
    break;
  case "export hub":
    title = AppLocalizations.of(context)!.exportHub;
    break;
  case "Chatbot":
    title = AppLocalizations.of(context)!.chatbot;
    break;
  default:
    title = key;
}

return buildFeatureCard(title, assetPath, icon, onTap);
            },
          ),
        ),
      ],
    ),
  ),
)
        ],
      ),
    ),
    );
  }
}               