import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../language_selection_screen.dart';
import '../../navigation/main_navigation.dart';
import '../auth/login_screen.dart';

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
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) {
      return;
    }

    await _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final bool languageSelected =
        prefs.getBool('language_selected') ?? false;

    if (!mounted) {
      return;
    }

    if (!languageSelected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LanguageSelectionScreen(),
        ),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    user ??= await _getAuthUser();

    if (!mounted) {
      return;
    }

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const MainNavigation(),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  Future<User?> _getAuthUser() async {
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => FirebaseAuth.instance.currentUser,
      );
    } catch (_) {
      return FirebaseAuth.instance.currentUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const Text(
                'AgriAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Agriculture',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 35),
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
      ),
    );
  }
}