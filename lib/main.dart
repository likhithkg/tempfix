import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:oktoast/oktoast.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'firebase_options.dart';
import 'weather/weather_page.dart';
import 'rent/rent_home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';
 // adjust path if you put it elsewhere
import 'image_test_page.dart';


import 'exporter_hub/exporter_service.dart';
import 'plant_vendor/plant_vendor_home.dart';
import 'labour_hub/labour_hub_listing_page.dart';
import 'labour_hub/labour_hub_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'profile/profile_page.dart';
import 'profile/profile_button.dart'; // <-- ADD THIS
import 'crop_disease/crop_disease_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/user_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'rent/rent_nearby_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart'; 
import 'splash/splash_screen.dart';
import 'export_hub/export_hub_page.dart';
import 'chatbot/chatbot_page.dart';
import 'exporter_hub/exporter_home_page.dart';






// Import your app widget
// import 'your_app_file.dart'; // if KrishiMithraApp is in a different file adjust the import
// If KrishiMithraApp is in the same file, no extra import needed.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initError;
  StackTrace? initStack;

  // Load persisted theme preference first (so we can show app with right theme even if init fails)
   // Load persisted theme preference first (so we can show app with right theme even if init fails)
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;

  // --- Initialize LocaleService so saved locale is available immediately ---
  await LocaleService.instance.init();

  // Try to initialize external services, but catch and store errors instead of crashing.
  try {
    // dotenv (optional — will throw if file missing but we catch it)
   try {
  await dotenv.load(fileName: ".env");

final key = dotenv.env['GEMINI_API_KEY'];

if (key == null || key.isEmpty) {
  print("⚠ GEMINI_API_KEY not found in .env");
} else {
  print("✅ Gemini API Key Loaded");
}
} catch (e, st) {
  print('Warning loading .env: $e\n$st');
}


    // Firebase init
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
    // Supabase init (if you use it)
    await sb.Supabase.initialize(
      url: 'https://ticpdepakqlizhdwgxtz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpY3BkZXBha3FsaXpoZHd3Z3h0eiIsInJvbGUiOiJhbmlvbiIsImlhdCI6MTc1MzcxNDI0MywiZXhwIjoyMDY5MjkwMjQzfQ.WdBMFR3z-mugqp7qLhOgWuHVh782ykZv4-mC2FPtKNM',
    );
  } catch (e, st) {
    // store the init error so we can show a helpful UI instead of white screen
    initError = e;
    initStack = st;
    // Print to console for logcat/adb logging
    // (these prints will appear in logcat when connected or in debug APK)
    print('*** App initialization error:\n$e\n$st');
  }

  // Catch Flutter framework errors and print them
  FlutterError.onError = (FlutterErrorDetails details) {
    // still use the default handler to show in debug
    FlutterError.presentError(details);
    // also print so it's available in logcat
    print('FlutterError caught: ${details.exception}\n${details.stack}');
  };

  // Run app within a guarded zone to catch other uncaught async errors
  runZonedGuarded(() {
    // If initError happened, start the minimal ErrorApp so we can read the message
    if (initError != null) {
      runApp(ErrorApp(
        isDark: isDark,
        error: initError!,
        stack: initStack,
      ));
    } else {
      // No early init error — run your normal app
      runApp(KrishiMithraApp(isDark: isDark));
    }
  }, (error, stack) {
    // Last-resort catcher: print to console (logcat)
    print('Uncaught zone error: $error\n$stack');
  });
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
  final bool isDark;
  const KrishiMithraApp({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: ValueListenableBuilder<Locale?>(
        valueListenable: LocaleService.instance.localeNotifier,
        builder: (context, locale, _) {
          return MaterialApp(
            title: 'KrishiMithra',
            theme: kmLightTheme,
            darkTheme: kmDarkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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
              // Add your AppLocalizations.delegate here if you use intl/ARB
            ],
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginPage(),
            },
          );
        },
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
    final indicatorColor = Theme.of(context).colorScheme.primary;
    final labelColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Full-screen background image
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/login_bg.png',
              fit: BoxFit.cover,
            ),
            // Optional overlay to increase contrast
            Container(color: Colors.black.withOpacity(0.35)),
            SafeArea(
              child: Column(
                children: [
                  // AppBar-like header (transparent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Row(
                      children: [
                        // optional logo or back button
                        // Icon(Icons.agriculture, color: Colors.white),
                        const Spacer(),
                        // keep some room for future actions
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tabs
                  TabBar(
                    labelColor: labelColor,
                    unselectedLabelColor: Colors.grey[300],
                    indicatorColor: indicatorColor,
                    tabs: const [
                      Tab(icon: Icon(Icons.email), text: "Email"),
                      Tab(icon: Icon(Icons.phone), text: "Phone"),
                    ],
                  ),
                  // Expanded content area for forms
                  Expanded(
                    child: TabBarView(
                      children: const [
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

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
    } on fb.FirebaseAuthException catch (e) {
      showToast(
        e.code == 'user-not-found'
            ? "No user found with that email"
            : e.code == 'wrong-password'
                ? "Incorrect password"
                : "Login failed: ${e.message}",
      );
    } catch (e) {
      showToast("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Floating card style on top of the background
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Card(
          elevation: 14,
          color: Theme.of(context).cardColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: SizedBox(
                    height: 80,
                    width: 80,
                    child: Image.asset(
                      'assets/log.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.loginEmail, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login"),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                      child: Text("Don't have an account? Sign Up", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                  child: Text("Forgot Password?", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54)),
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

  void sendOTP() async {
    if (phone.trim().isEmpty) {
      showToast("Enter phone number");
      return;
    }
    setState(() => loading = true);
    await fb.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (cred) async {
        await fb.FirebaseAuth.instance.signInWithCredential(cred);
        await _saveUserToFirestore();
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
      },
      verificationFailed: (e) {
        showToast("Verification failed: ${e.message}");
        setState(() => loading = false);
      },
      codeSent: (id, _) {
        verificationId = id;
        setState(() {
          otpSent = true;
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
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
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
    } catch (e) {
      showToast("Invalid OTP");
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
          "createdAt": FieldValue.serverTimestamp(),
        });
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
          color: Theme.of(context).cardColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40), // Half of the height to make it circular
                child: Image.asset(
                'assets/log.png',
                height: 80,
                width: 80, // Make width equal to height for perfect circle
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 12),
              Text("Login / Sign Up with Phone", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
                if (otpSent)
                  Column(
                    children: [
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Enter OTP",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                          child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Verify OTP"),
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
          'createdAt': FieldValue.serverTimestamp(),
          'defaultLocation': null,
          'preferences': {},
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
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
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // Full-screen background + overlay
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/login_bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Card(
                  elevation: 10,
                  color: Theme.of(context).cardColor.withOpacity(0.95),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              'assets/log.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.transparent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Create Your Account",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up"),
                          ),
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
      // Full-screen background + overlay
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/login_bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Card(
                  elevation: 10,
                  color: Theme.of(context).cardColor.withOpacity(0.95),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Reset Your Password",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22, fontWeight: FontWeight.bold, color: primary),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : sendResetLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Send Reset Link"),
                          ),
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
  List<dynamic> _suggestions = [];
  bool _showSuggestions = false;
  List<String> _recentLocations = [];

  Map<String, dynamic>? userProfile;
  LatLng? _defaultCoords; // ✅ stores latest lat/lon

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
    if (user != null) {
      try {
        final userProfileDoc = FirebaseFirestore.instance.collection('userProfile').doc(user.uid);
        final usersDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

        DocumentSnapshot<Map<String, dynamic>> doc = await userProfileDoc.get();
        Map<String, dynamic>? data;
        if (doc.exists) {
          data = doc.data();
        } else {
          final doc2 = await usersDoc.get();
          if (doc2.exists) data = doc2.data();
        }

        if (data != null) {
          final location = data['defaultLocation'] ?? data['default_location'] ?? data['default_loc'];
          final lat = data['defaultLat'] ?? data['default_lat'] ?? data['lat'];
          final lon = data['defaultLon'] ?? data['default_lon'] ?? data['lon'];

          if (location != null && location is String && mounted) {
            setState(() {
              selectedLocation = location;
              _searchController.text = location;
              if (lat != null && lon != null) {
                try {
                  final doubleLat = (lat is num) ? lat.toDouble() : double.parse(lat.toString());
                  final doubleLon = (lon is num) ? lon.toDouble() : double.parse(lon.toString());
                  _defaultCoords = LatLng(doubleLat, doubleLon);
                } catch (_) {}
              }
            });
            return;
          }
        }
      } catch (_) {
        // ignore and fallback
      }
    }

    // Fallback to original LocationService behavior
    try {
      final location = await LocationService.getDefaultLocation(
        userId: fb.FirebaseAuth.instance.currentUser?.uid ?? "",
      );
      if (location != null && location.isNotEmpty && mounted) {
        setState(() {
          selectedLocation = location;
          _searchController.text = location;
        });
      }
    } catch (_) {}
  }

  // ---------- Improved: load recent locations (local then Firestore) ----------
  Future<void> _loadRecentLocations() async {
    // load local prefs first for quick UI
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getStringList('recent_locations') ?? [];
      if (local.isNotEmpty && mounted) setState(() => _recentLocations = local);
    } catch (_) {}

    // then try to sync from Firestore (so it persists across devices)
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc1 = await FirebaseFirestore.instance.collection('userProfile').doc(user.uid).get();
        List<String> fromFs = [];
        if (doc1.exists && doc1.data()?['recentLocations'] != null) {
          fromFs = (doc1.data()!['recentLocations'] as List).map((e) => e.toString()).toList();
        } else {
          final doc2 = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc2.exists && doc2.data()?['recentLocations'] != null) {
            fromFs = (doc2.data()!['recentLocations'] as List).map((e) => e.toString()).toList();
          }
        }
        if (fromFs.isNotEmpty && mounted) {
          setState(() => _recentLocations = fromFs.take(5).toList());
          // update local prefs too
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('recent_locations', _recentLocations);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  // ---------- Improved: save selected location (writes Firestore userProfile & users) ----------
  Future<void> _saveLocation(String location) async {
    // Resolve coordinates using your existing LocationService
    double lat = 0.0;
    double lon = 0.0;
    try {
      final coords = await LocationService.getCoordinatesFromName(location);
      lat = (coords['lat'] is num) ? (coords['lat'] as num).toDouble() : double.tryParse(coords['lat'].toString()) ?? 0.0;
      lon = (coords['lon'] is num) ? (coords['lon'] as num).toDouble() : double.tryParse(coords['lon'].toString()) ?? 0.0;
    } catch (_) {}

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProfileRef = FirebaseFirestore.instance.collection('userProfile').doc(user.uid);
      final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final locMap = {
        'defaultLocation': location,
        'defaultLat': lat,
        'defaultLon': lon,
      };

      // Write to both collections (merge) to be compatible with different code paths
      try {
        await userProfileRef.set(locMap, SetOptions(merge: true));
      } catch (_) {}
      try {
        await usersRef.set(locMap, SetOptions(merge: true));
      } catch (_) {}

      // Maintain recentLocations array in Firestore (server-side copy)
      try {
        final userDoc = await userProfileRef.get();
        List existing = [];
        if (userDoc.exists && userDoc.data()?['recentLocations'] != null) {
          existing = List.from(userDoc.data()?['recentLocations'] as List);
        } else {
          final udoc2 = await usersRef.get();
          if (udoc2.exists && udoc2.data()?['recentLocations'] != null) {
            existing = List.from(udoc2.data()?['recentLocations'] as List);
          }
        }

        // Remove duplicates (by string equality) and insert new at front
        existing.removeWhere((e) {
          try {
            final s = e is String ? e : (e is Map ? (e['displayName'] ?? e['name'] ?? e['defaultLocation']) : e.toString());
            return s == location;
          } catch (_) {
            return false;
          }
        });

        existing.insert(0, location);
        // Trim to 10 items
        final trimmed = existing.take(10).toList();

        await userProfileRef.set({'recentLocations': trimmed}, SetOptions(merge: true));
        await usersRef.set({'recentLocations': trimmed}, SetOptions(merge: true));
      } catch (_) {
        // ignore
      }
    }

    // Update local UI & SharedPreferences
    if (mounted) {
      setState(() {
        selectedLocation = location;
        _searchController.text = location;
        _showSuggestions = false;
        _defaultCoords = LatLng(lat, lon);
        if (!_recentLocations.contains(location)) {
          _recentLocations.insert(0, location);
          if (_recentLocations.length > 5) _recentLocations = _recentLocations.sublist(0, 5);
        } else {
          // move to front
          _recentLocations.remove(location);
          _recentLocations.insert(0, location);
        }
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_locations', _recentLocations);
    } catch (_) {}
  }

  // ---------- Keep user profile loader (unchanged but robust) ----------
  Future<void> _loadUserProfile() async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic>? data;
      final doc1 = await FirebaseFirestore.instance.collection('userProfile').doc(user.uid).get();
      if (doc1.exists) data = doc1.data();

      if (data == null) {
        final doc2 = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc2.exists) data = doc2.data();
      }

      if (!mounted) return;
      setState(() {
        userProfile = data;
      });
    } catch (_) {}
  }

  // ---------- small helpers used by search & dialog ----------
  void _onSearchTextChanged(String text) async {
    if (text.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final results = await LocationService.getSuggestions(text);
    setState(() {
      _suggestions = results;
    });
  }

  void _selectLocation(String displayName) {
    _saveLocation(displayName);
    FocusScope.of(context).unfocus();
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
                        Text('Recent Locations',
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


  void _openNearbyMachines() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RentNearbyPage(
        userLocation: _defaultCoords != null
            ? Position(
                latitude: _defaultCoords!.latitude,
                longitude: _defaultCoords!.longitude,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              )
            : null,
        referenceName: selectedLocation, // ✅ pass the saved name
      ),
    ),
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
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.05),
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
                color: Colors.black.withOpacity(0.25), // extra overlay behind text
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
      setState(() => _showSuggestions = false);
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

    // 🌐 Language icon (if you have)
    IconButton(
      icon: const Icon(Icons.language),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Select Language"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("English"),
                  onTap: () {
                    LocaleService.instance.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text("ಕನ್ನಡ"),
                  onTap: () {
                    LocaleService.instance.setLocale(const Locale('kn'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
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

    // 👤 PROFILE ICON
    CircleAvatar(
      backgroundColor: KMColors.primary,
      child: const Text("LK", style: TextStyle(color: KMColors.textOnPrimary)),
    ),
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => ExporterHomePage()));
  } else if (key == "Plant Vendors") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorHome()));
  } else if (key == "Labour Hub") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LabourHubListingPage()));
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => ExporterHomePage()));
  } else if (key == "Plant Vendors") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantVendorHome()));
  } else if (key == "Labour Hub") {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LabourHubListingPage()));
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