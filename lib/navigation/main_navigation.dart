import 'package:flutter/material.dart';

import '../screens/disease_detection/disease_detection_screen.dart';
import '../screens/home/home_screen.dart' as home_screen;
import '../screens/profile/profile_screen.dart';
import '../screens/reels/reels_screen.dart';
import '../screens/search/user_search_screen.dart';
import '../screens/yield_prediction/yield_prediction_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final VoidCallback? onAppReady;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.onAppReady,
  });

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex =
        widget.initialIndex.clamp(0, 4);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        widget.onAppReady?.call();
      },
    );
  }

  void _onNavigationChanged(int index) {
    if (index < 0 || index > 4) {
      return;
    }

    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return home_screen.HomeScreen(
          onProfile: () {
            _onNavigationChanged(4);
          },
          onSearch: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const UserSearchScreen(),
              ),
            );
          },
        );

      case 1:
        return const ReelsScreen();

      case 2:
        return const YieldPredictionScreen();

      case 3:
        return const DiseaseDetectionScreen();

      case 4:
        return const ProfileScreen();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(22),
          child: NavigationBar(
            height: 72,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedIndex: _currentIndex,
            onDestinationSelected:
                _onNavigationChanged,
            indicatorColor:
                const Color(0xFFE8F5E9),
            destinations:
                const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                ),
                selectedIcon: Icon(
                  Icons.home,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.play_circle_outline,
                ),
                selectedIcon: Icon(
                  Icons.play_circle,
                ),
                label: 'Reels',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.analytics_outlined,
                ),
                selectedIcon: Icon(
                  Icons.analytics,
                ),
                label: 'Yield',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.local_florist_outlined,
                ),
                selectedIcon: Icon(
                  Icons.local_florist,
                ),
                label: 'Disease',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                ),
                selectedIcon: Icon(
                  Icons.person,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(
          5,
          _buildScreen,
        ),
      ),
      bottomNavigationBar:
          _buildBottomNavigationBar(),
    );
  }
}