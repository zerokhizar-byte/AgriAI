import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'language_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_update_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState>
    appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AgriAIApp());
}

class AgriAIApp extends StatefulWidget {
  const AgriAIApp({
    super.key,
  });

  @override
  State<AgriAIApp> createState() => _AgriAIAppState();
}

class _AgriAIAppState extends State<AgriAIApp> {
  bool _updateCheckStarted = false;
  bool _updateDialogShowing = false;

  void _onAppReady() {
    if (_updateCheckStarted) {
      return;
    }

    _updateCheckStarted = true;

    debugPrint(
      'AgriAI: MainNavigation is ready. '
      'Starting 3-second update timer.',
    );

    unawaited(
      _startDelayedUpdateCheck(),
    );
  }

  Future<void> _startDelayedUpdateCheck() async {
    await Future<void>.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) {
      return;
    }

    debugPrint(
      'AgriAI: 3-second delay completed. '
      'Checking for update...',
    );

    try {
      final AppUpdateInfo updateInfo =
          await AppUpdateService.checkForUpdate();

      if (!mounted) {
        return;
      }

      debugPrint(
        'AgriAI Update Check: '
        'current=${updateInfo.currentVersion}, '
        'latest=${updateInfo.latestVersion}, '
        'minimum=${updateInfo.minimumVersion}, '
        'available=${updateInfo.updateAvailable}, '
        'required=${updateInfo.updateRequired}',
      );

      if (updateInfo.updateRequired) {
        debugPrint(
          'AgriAI: Mandatory update detected.',
        );

        await _showUpdateDialog(
          updateInfo,
          mandatory: true,
        );

        return;
      }

      if (updateInfo.updateAvailable) {
        debugPrint(
          'AgriAI: Optional update detected. '
          'Showing startup alert.',
        );

        await _showUpdateDialog(
          updateInfo,
          mandatory: false,
        );

        return;
      }

      debugPrint(
        'AgriAI: App is already up to date.',
      );
    } catch (error) {
      debugPrint(
        'AgriAI Update Check Error: $error',
      );
    }
  }

  Future<void> _showUpdateDialog(
    AppUpdateInfo updateInfo, {
    required bool mandatory,
  }) async {
    if (_updateDialogShowing) {
      return;
    }

    final NavigatorState? navigator =
        appNavigatorKey.currentState;

    if (navigator == null || !navigator.mounted) {
      debugPrint(
        'AgriAI: Navigator is not available.',
      );
      return;
    }

    _updateDialogShowing = true;

    try {
      await showDialog<void>(
        context: navigator.context,
        barrierDismissible: !mandatory,
        builder: (
          BuildContext dialogContext,
        ) {
          return PopScope(
            canPop: !mandatory,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              title: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFE8F5E9),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color:
                          Color(0xFF2E7D32),
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      updateInfo.title.isNotEmpty
                          ? updateInfo.title
                          : 'New AgriAI Update Available',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    updateInfo.message.isNotEmpty
                        ? updateInfo.message
                        : 'A new version of AgriAI is available. '
                            'Update now to get the latest features '
                            'and improvements.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF5F8F5),
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Current version',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.black54,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                updateInfo
                                    .currentVersion,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color:
                              Colors.black45,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: <Widget>[
                              const Text(
                                'New version',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.black54,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                updateInfo
                                    .latestVersion,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mandatory) ...<Widget>[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFFEBEE),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.warning_amber_rounded,
                            color:
                                Color(0xFFC62828),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This update is required '
                              'to continue using AgriAI.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actionsPadding:
                  const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20,
              ),
              actions: <Widget>[
                if (!mandatory)
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                    child: const Text(
                      'Later',
                    ),
                  ),
                FilledButton.icon(
                  onPressed: () {
                    unawaited(
                      _openUpdateLink(
                        updateInfo,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.download_rounded,
                  ),
                  label: const Text(
                    'Update Now',
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      _updateDialogShowing = false;
    }
  }

  Future<void> _openUpdateLink(
    AppUpdateInfo updateInfo,
  ) async {
    final TargetPlatform platform =
        Theme.of(
          appNavigatorKey.currentState!.context,
        ).platform;

    final String storeUrl =
        platform == TargetPlatform.iOS
            ? updateInfo.iosStoreUrl
            : updateInfo.androidStoreUrl;

    if (storeUrl.trim().isEmpty) {
      appScaffoldMessengerKey.currentState
          ?.showSnackBar(
        const SnackBar(
          content: Text(
            'The AgriAI update link is not available yet.',
          ),
        ),
      );

      return;
    }

    final Uri? uri =
        Uri.tryParse(storeUrl.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority) {
      appScaffoldMessengerKey.currentState
          ?.showSnackBar(
        const SnackBar(
          content: Text(
            'The AgriAI update link is invalid.',
          ),
        ),
      );

      return;
    }

    final bool launched =
        await launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication,
    );

    if (!launched) {
      appScaffoldMessengerKey.currentState
          ?.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the AgriAI update link.',
          ),
        ),
      );
    }
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor:
            const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor:
          const Color(0xFFF8FBF8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriAI',
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey:
          appScaffoldMessengerKey,
      theme: _buildTheme(),
      home: SplashScreen(
        onAppReady: _onAppReady,
      ),
      routes: <String, WidgetBuilder>{
        '/login': (_) =>
            const LoginScreen(),
        '/language': (_) =>
            const LanguageSelectionScreen(),
      },
    );
  }
}