import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class LanguageScreen extends StatefulWidget {
  final String? selectedLanguage;
  final ValueChanged<String>? onLanguageSelected;
  final VoidCallback? onContinue;

  const LanguageScreen({
    super.key,
    this.selectedLanguage,
    this.onLanguageSelected,
    this.onContinue,
  });

  @override
  State<LanguageScreen> createState() =>
      _LanguageScreenState();
}

class _LanguageScreenState
    extends State<LanguageScreen> {
  late String _selectedLanguage;

  static const List<_LanguageOption> _languages = [
    _LanguageOption(
      name: 'English',
      nativeName: 'English',
      code: 'EN',
    ),
    _LanguageOption(
      name: 'Hindi',
      nativeName: 'हिन्दी',
      code: 'हि',
    ),
    _LanguageOption(
      name: 'Marathi',
      nativeName: 'मराठी',
      code: 'म',
    ),
    _LanguageOption(
      name: 'Urdu',
      nativeName: 'اردو',
      code: 'ا',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _selectedLanguage =
        widget.selectedLanguage?.trim().isNotEmpty == true
            ? widget.selectedLanguage!
            : 'English';
  }

  void _selectLanguage(
    _LanguageOption language,
  ) {
    setState(() {
      _selectedLanguage = language.name;
    });

    widget.onLanguageSelected?.call(
      language.name,
    );
  }

  void _continue() {
    if (widget.onContinue != null) {
      widget.onContinue!.call();
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            24,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 22),

                      const _LanguageLogo(),

                      const SizedBox(height: 28),

                      const Text(
                        'Choose Your Language',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Select your preferred language to use AgriAI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      ...List.generate(
                        _languages.length,
                        (index) {
                          final language =
                              _languages[index];

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index ==
                                          _languages.length - 1
                                      ? 0
                                      : 12,
                            ),
                            child: _LanguageCard(
                              language: language,
                              selected:
                                  _selectedLanguage ==
                                      language.name,
                              onTap: () {
                                _selectLanguage(
                                  language,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String name;
  final String nativeName;
  final String code;

  const _LanguageOption({
    required this.name,
    required this.nativeName,
    required this.code,
  });
}

class _LanguageCard extends StatelessWidget {
  final _LanguageOption language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.cardGreen
            : AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppColors.primary
                  .withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(18),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.cardGreen,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    language.code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w900,
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
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        language.name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight.w500,
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                      width:
                          selected ? 2 : 1.5,
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
      ),
    );
  }
}

class _LanguageLogo extends StatelessWidget {
  const _LanguageLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary
                .withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Icon(
        Icons.language_rounded,
        size: 38,
        color: AppColors.primary,
      ),
    );
  }
}