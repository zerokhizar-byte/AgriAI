import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../language_selection_screen.dart';
import '../../navigation/main_navigation.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onAppReady;

  const SplashScreen({
    super.key,
    this.onAppReady,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;

  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();

    _enterFullScreen();

    unawaited(_startApp());
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _startApp() async {
    await _initializeAndPlayVideo();

    if (!mounted) {
      return;
    }

    await _checkUserAndNavigate();
  }

  Future<void> _initializeAndPlayVideo() async {
    try {
      final VideoPlayerController controller =
          VideoPlayerController.asset(
        'assets/animations/agriai_logo.mp4',
      );

      _videoController = controller;

      await controller.initialize();

      if (!mounted) {
        return;
      }

      await controller.setLooping(false);

      setState(() {
        _videoReady = true;
      });

      await controller.play();

      await _waitForVideoCompletion();
    } catch (error, stackTrace) {
      debugPrint(
        'AgriAI Splash video error: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _videoFailed = true;
      });

      await Future<void>.delayed(
        const Duration(seconds: 2),
      );
    }
  }

  Future<void> _waitForVideoCompletion() async {
    final VideoPlayerController? controller =
        _videoController;

    if (controller == null) {
      return;
    }

    while (mounted) {
      final VideoPlayerValue value =
          controller.value;

      if (!value.isInitialized) {
        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );
        continue;
      }

      if (value.position >= value.duration) {
        break;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );
    }
  }

  Future<void> _checkUserAndNavigate() async {
    _restoreSystemUI();

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final bool languageSelected =
        prefs.getBool('language_selected') ?? false;

    if (!mounted) {
      return;
    }

    if (!languageSelected) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              const LanguageSelectionScreen(),
        ),
      );
      return;
    }

    User? user =
        FirebaseAuth.instance.currentUser;

    user ??= await _getAuthUser();

    if (!mounted) {
      return;
    }

    if (user != null) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainNavigation(
            onAppReady: widget.onAppReady,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
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
        onTimeout: () =>
            FirebaseAuth.instance.currentUser,
      );
    } catch (_) {
      return FirebaseAuth.instance.currentUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller =
        _videoController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildSplashContent(controller),
    );
  }

  Widget _buildSplashContent(
    VideoPlayerController? controller,
  ) {
    if (_videoFailed) {
      return _buildFallbackSplash();
    }

    if (!_videoReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return const SizedBox.expand(
        child: ColoredBox(
          color: Colors.black,
        ),
      );
    }

    final Size videoSize =
        controller.value.size;

    if (videoSize.width <= 0 ||
        videoSize.height <= 0) {
      return const SizedBox.expand(
        child: ColoredBox(
          color: Colors.black,
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildFallbackSplash() {
    return const SizedBox.expand(
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: Image(
            image: AssetImage(
              'assets/images/agriai_logo.png',
            ),
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _restoreSystemUI();

    _videoController?.dispose();

    super.dispose();
  }
}