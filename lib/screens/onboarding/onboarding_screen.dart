import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const OnboardingScreen({
    super.key,
    this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final PageController _pageController =
      PageController();

  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.agriculture_outlined,
      title: 'Smart Farming',
      description:
          'Make better farming decisions with intelligent agricultural insights designed for your field.',
    ),
    _OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'AI-Powered Insights',
      description:
          'Use crop yield prediction, soil analysis and plant disease detection to understand your crops better.',
    ),
    _OnboardingPage(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Better Decisions',
      description:
          'Get practical recommendations for irrigation, fertilizers, crops and daily farm management.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration:
            const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() {
    _finish();
  }

  void _finish() {
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage =
        _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  0,
                ),
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder:
                    (context, index) {
                  return _OnboardingContent(
                    page: _pages[index],
                  );
                },
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                8,
                22,
                24,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) {
                        final bool selected =
                            index ==
                                _currentPage;

                        return AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 220,
                          ),
                          margin:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 4,
                          ),
                          width:
                              selected ? 24 : 7,
                          height: 7,
                          decoration:
                              BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Text(
                            isLastPage
                                ? 'Get Started'
                                : 'Next',
                            style:
                                const TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Icon(
                            isLastPage
                                ? Icons
                                    .check_rounded
                                : Icons
                                    .arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
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

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingContent
    extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingContent({
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  blurRadius: 30,
                  offset:
                      const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 138,
                  height: 138,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withValues(
                      alpha: 0.8,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  page.icon,
                  size: 68,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 42),

          AnimatedSwitcher(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            child: Text(
              page.title,
              key: ValueKey(
                page.title,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                height: 1.15,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: -0.5,
                color:
                    AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 14),

          AnimatedSwitcher(
            duration:
                const Duration(
              milliseconds: 250,
            ),
            child: Text(
              page.description,
              key: ValueKey(
                page.description,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                fontWeight:
                    FontWeight.w500,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}