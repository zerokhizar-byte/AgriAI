import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class LanguageSettingsScreen extends StatefulWidget {
  final String selectedLanguage;
  final ValueChanged<String>? onLanguageChanged;

  const LanguageSettingsScreen({
    super.key,
    this.selectedLanguage = 'English',
    this.onLanguageChanged,
  });

  @override
  State<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends State<LanguageSettingsScreen> {
  late String _selectedLanguage;

  static const List<AppLanguage> _languages = [
    AppLanguage(
      name: 'English',
      nativeName: 'English',
      code: 'EN',
    ),
    AppLanguage(
      name: 'Hindi',
      nativeName: 'हिन्दी',
      code: 'हि',
    ),
    AppLanguage(
      name: 'Marathi',
      nativeName: 'मराठी',
      code: 'म',
    ),
    AppLanguage(
      name: 'Urdu',
      nativeName: 'اردو',
      code: 'ا',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
  }

  void _selectLanguage(AppLanguage language) {
    if (_selectedLanguage == language.name) {
      return;
    }

    setState(() {
      _selectedLanguage = language.name;
    });

    widget.onLanguageChanged?.call(language.name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language changed to ${language.name}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radius22,
                ),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.language_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select the language you want to use throughout AgriAI.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            fontWeight:
                                FontWeight.w500,
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Languages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(
                  AppDimensions.radius18,
                ),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  for (var i = 0;
                      i < _languages.length;
                      i++) ...[
                    _LanguageTile(
                      language: _languages[i],
                      selected:
                          _selectedLanguage ==
                              _languages[i].name,
                      onTap: () {
                        _selectLanguage(
                          _languages[i],
                        );
                      },
                    ),
                    if (i != _languages.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(
                          left: 76,
                        ),
                        child: Divider(
                          height: 1,
                          color: AppColors.divider,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLanguage {
  final String name;
  final String nativeName;
  final String code;

  const AppLanguage({
    required this.name,
    required this.nativeName,
    required this.code,
  });
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 220),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  language.code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      language.name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                    width: selected ? 2 : 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}