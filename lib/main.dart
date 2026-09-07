import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'language_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AgriAIApp());
}

class AgriAIApp extends StatelessWidget {
  const AgriAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // Keep splash screen visible for 2 seconds.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    await _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // ----------------------------------------------------------
    // CHECK LANGUAGE SELECTION
    // ----------------------------------------------------------

    final prefs = await SharedPreferences.getInstance();

    final bool languageSelected =
        prefs.getBool('language_selected') ?? false;

    if (!mounted) return;

    // ----------------------------------------------------------
    // FIRST LAUNCH
    // ----------------------------------------------------------

    if (!languageSelected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LanguageSelectionScreen(),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // CHECK FIREBASE AUTHENTICATION
    // ----------------------------------------------------------

    User? user;

    try {
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => FirebaseAuth.instance.currentUser,
          );
    } catch (_) {
      user = FirebaseAuth.instance.currentUser;
    }

    if (!mounted) return;

    // ----------------------------------------------------------
    // USER IS ALREADY LOGGED IN
    // ----------------------------------------------------------

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // USER IS NOT LOGGED IN
    // ----------------------------------------------------------

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AgriAI Logo
            Image.asset(
              'assets/images/agriai_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return const Icon(
                  Icons.agriculture,
                  size: 100,
                  color: Color(0xFF2E7D32),
                );
              },
            ),

            const SizedBox(height: 24),

            // App Name
            const Text(
              'AgriAI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Smart Agriculture',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 35),

            // Loading Indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}