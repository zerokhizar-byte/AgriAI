import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(
    BuildContext context,
    String language,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_language',
      language,
    );

    await prefs.setBool(
      'language_selected',
      true,
    );

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const languages = [
      'English',
      'हिंदी',
      'मराठी',
      'தமிழ்',
      'తెలుగు',
      'ಕನ್ನಡ',
      'বাংলা',
      'ગુજરાતી',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Select Your Language',
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  60,
                ),
              ),
              onPressed: () {
                _selectLanguage(
                  context,
                  languages[index],
                );
              },
              child: Text(
                languages[index],
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}