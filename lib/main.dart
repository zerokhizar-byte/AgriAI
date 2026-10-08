import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'language_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_update_service.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState>
    appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ============================================================================
// FCM BACKGROUND HANDLER
// ============================================================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'AgriAI FCM background message: '
      'id=${message.messageId}, '
      'title=${message.notification?.title}, '
      'body=${message.notification?.body}, '
      'data=${message.data}',
    );
  } catch (error, stackTrace) {
    debugPrint(
      'AgriAI FCM background initialization error: $error',
    );

    debugPrint(
      stackTrace.toString(),
    );
  }
}

// ============================================================================
// FIREBASE / FCM INITIALIZATION
// ============================================================================

Future<void> _initializeFirebaseServices() async {
  debugPrint(
    'AgriAI: Starting Firebase initialization...',
  );

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    debugPrint(
      'AgriAI: Firebase is already initialized.',
    );
  }

  debugPrint(
    'AgriAI: Firebase initialized successfully.',
  );

  // Register the background FCM handler only after
  // Firebase has been initialized.
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  await _initializeFirebaseMessaging();

  _listenForAuthenticationChanges();

  debugPrint(
    'AgriAI: Firebase services initialized successfully.',
  );
}

// ============================================================================
// FCM INITIALIZATION
// ============================================================================

Future<void> _initializeFirebaseMessaging() async {
  final FirebaseMessaging messaging =
      FirebaseMessaging.instance;

  try {
    // ------------------------------------------------------------------------
    // LOCAL NOTIFICATIONS
    // ------------------------------------------------------------------------

    await NotificationService.initializeLocalNotifications();

    debugPrint(
      'AgriAI: Local notifications initialized.',
    );

    // ------------------------------------------------------------------------
    // FCM PERMISSION
    // ------------------------------------------------------------------------

    final NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'AgriAI FCM permission: '
      '${settings.authorizationStatus.name}',
    );

    // ------------------------------------------------------------------------
    // FCM TOKEN
    // ------------------------------------------------------------------------

    try {
      final String? token =
          await messaging.getToken();

      if (token != null &&
          token.trim().isNotEmpty) {
        debugPrint(
          'AgriAI FCM TOKEN:\n$token',
        );

        // FCM token persistence is handled by
        // NotificationService.initializeForCurrentUser().
      } else {
        debugPrint(
          'AgriAI FCM: Device token is not available yet.',
        );
      }
    } catch (error) {
      debugPrint(
        'AgriAI FCM token error: $error',
      );
    }

    // ------------------------------------------------------------------------
    // TOKEN REFRESH
    // ------------------------------------------------------------------------

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (String newToken) {
        debugPrint(
          'AgriAI FCM TOKEN REFRESHED:\n$newToken',
        );

        try {
          // FCM token persistence is handled by
          // NotificationService.initializeForCurrentUser().
        } catch (error) {
          debugPrint(
            'AgriAI FCM token refresh error: $error',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'AgriAI FCM token refresh listener error: $error',
        );
      },
    );

    // ------------------------------------------------------------------------
    // FOREGROUND MESSAGE
    // ------------------------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        final String title =
            message.notification?.title ??
                message.data['title']?.toString() ??
                'AgriAI';

        final String body =
            message.notification?.body ??
                message.data['body']?.toString() ??
                '';

        final String payload =
            _buildNotificationPayload(message);

        debugPrint(
          'AgriAI FCM foreground message: '
          'title=$title, '
          'body=$body, '
          'payload=$payload',
        );

        unawaited(
          NotificationService.showLocalNotification(
            title: title,
            body: body,
            payload: payload,
          ),
        );
      },
      onError: (Object error) {
        debugPrint(
          'AgriAI FCM foreground listener error: $error',
        );
      },
    );

    // ------------------------------------------------------------------------
    // NOTIFICATION OPENED FROM BACKGROUND
    // ------------------------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint(
          'AgriAI FCM notification opened: '
          'id=${message.messageId}',
        );

        debugPrint(
          'AgriAI FCM data: ${message.data}',
        );

        _handleNotificationData(
          message.data,
        );
      },
      onError: (Object error) {
        debugPrint(
          'AgriAI FCM opened-app listener error: $error',
        );
      },
    );

    // ------------------------------------------------------------------------
    // NOTIFICATION OPENED FROM TERMINATED STATE
    // ------------------------------------------------------------------------

    try {
      final RemoteMessage? initialMessage =
          await messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'AgriAI FCM initial notification: '
          'id=${initialMessage.messageId}',
        );

        debugPrint(
          'AgriAI FCM initial data: '
          '${initialMessage.data}',
        );

        Future<void>.delayed(
          const Duration(milliseconds: 800),
          () {
            _handleNotificationData(
              initialMessage.data,
            );
          },
        );
      }
    } catch (error) {
      debugPrint(
        'AgriAI FCM initial message error: $error',
      );
    }
  } catch (error, stackTrace) {
    debugPrint(
      'AgriAI FCM initialization error: $error',
    );

    debugPrint(
      stackTrace.toString(),
    );
  }
}

// ============================================================================
// NOTIFICATION PAYLOAD
// ============================================================================

String _buildNotificationPayload(
  RemoteMessage message,
) {
  final Map<String, dynamic> data =
      message.data;

  final String type =
      data['type']?.toString().trim() ?? '';

  final String actionRoute =
      data['actionRoute']?.toString().trim() ?? '';

  final String newsId =
      data['newsId']?.toString().trim() ?? '';

  final String newsUrl =
      data['newsUrl']?.toString().trim() ?? '';

  final String postId =
      data['postId']?.toString().trim() ?? '';

  final String conversationId =
      data['conversationId']?.toString().trim() ?? '';

  final String connectionRequestId =
      data['connectionRequestId']?.toString().trim() ?? '';

  return <String>[
    type,
    actionRoute,
    newsId,
    newsUrl,
    postId,
    conversationId,
    connectionRequestId,
  ].join('|');
}

// ============================================================================
// NOTIFICATION DATA HANDLER
// ============================================================================

void _handleNotificationData(
  Map<String, dynamic> data,
) {
  final String type =
      data['type']?.toString().trim() ?? '';

  final String actionRoute =
      data['actionRoute']?.toString().trim() ?? '';

  debugPrint(
    'AgriAI notification handler: '
    'type=$type, '
    'actionRoute=$actionRoute',
  );

  NotificationService.publishNotificationTap(
    data,
  );

  switch (type) {
    case 'dailyNews':
      _handleDailyNewsNotification(data);
      break;

    case 'message':
      _handleMessageNotification(data);
      break;

    case 'connectionRequest':
    case 'connectionAccepted':
      _handleConnectionNotification(data);
      break;

    case 'like':
    case 'comment':
      _handlePostNotification(data);
      break;

    default:
      _handleGenericNotification(data);
  }
}

// ============================================================================
// DAILY NEWS
// ============================================================================

void _handleDailyNewsNotification(
  Map<String, dynamic> data,
) {
  final String newsId =
      data['newsId']?.toString().trim() ?? '';

  final String newsUrl =
      data['newsUrl']?.toString().trim() ?? '';

  debugPrint(
    'AgriAI Daily News notification opened: '
    'newsId=$newsId, '
    'newsUrl=$newsUrl',
  );

  // HomeScreen consumes this event and opens
  // the existing Agriculture News panel.
}

// ============================================================================
// MESSAGE
// ============================================================================

void _handleMessageNotification(
  Map<String, dynamic> data,
) {
  final String conversationId =
      data['conversationId']?.toString().trim() ?? '';

  debugPrint(
    'AgriAI message notification opened: '
    'conversationId=$conversationId',
  );
}

// ============================================================================
// CONNECTION
// ============================================================================

void _handleConnectionNotification(
  Map<String, dynamic> data,
) {
  final String connectionRequestId =
      data['connectionRequestId']?.toString().trim() ?? '';

  debugPrint(
    'AgriAI connection notification opened: '
    'connectionRequestId=$connectionRequestId',
  );
}

// ============================================================================
// POST
// ============================================================================

void _handlePostNotification(
  Map<String, dynamic> data,
) {
  final String postId =
      data['postId']?.toString().trim() ?? '';

  debugPrint(
    'AgriAI post notification opened: '
    'postId=$postId',
  );
}

// ============================================================================
// GENERIC
// ============================================================================

void _handleGenericNotification(
  Map<String, dynamic> data,
) {
  debugPrint(
    'AgriAI generic notification opened: '
    '$data',
  );
}

// ============================================================================
// AUTHENTICATION NOTIFICATION INITIALIZATION
// ============================================================================

void _initializeNotificationsForUser(
  User? user,
) {
  if (user == null) {
    debugPrint(
      'AgriAI Notification: No authenticated user.',
    );
    return;
  }

  debugPrint(
    'AgriAI Notification: '
    'Authenticated user detected: ${user.uid}',
  );

  unawaited(
    NotificationService.initializeForCurrentUser(),
  );
}

// ============================================================================
// AUTH STATE LISTENER
// ============================================================================

void _listenForAuthenticationChanges() {
  try {
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        _initializeNotificationsForUser(user);
      },
      onError: (Object error) {
        debugPrint(
          'AgriAI Notification: '
          'Auth state listener error: $error',
        );
      },
    );

    _initializeNotificationsForUser(
      FirebaseAuth.instance.currentUser,
    );
  } catch (error, stackTrace) {
    debugPrint(
      'AgriAI authentication listener error: $error',
    );

    debugPrint(
      stackTrace.toString(),
    );
  }
}

// ============================================================================
// MAIN
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT:
  // Do not initialize Firebase/FCM/notifications before runApp().
  // Start Flutter UI first and let the bootstrap widget initialize
  // Firebase safely.
  runApp(
    const AgriAIApp(),
  );
}

// ============================================================================
// AGRIAI APP
// ============================================================================

class AgriAIApp extends StatefulWidget {
  const AgriAIApp({
    super.key,
  });

  @override
  State<AgriAIApp> createState() =>
      _AgriAIAppState();
}

class _AgriAIAppState extends State<AgriAIApp> {
  bool _updateCheckStarted = false;
  bool _updateDialogShowing = false;

  // ==========================================================================
  // APP READY
  // ==========================================================================

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

  // ==========================================================================
  // UPDATE CHECK
  // ==========================================================================

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

  // ==========================================================================
  // UPDATE DIALOG
  // ==========================================================================

  Future<void> _showUpdateDialog(
    AppUpdateInfo updateInfo, {
    required bool mandatory,
  }) async {
    if (_updateDialogShowing) {
      return;
    }

    final NavigatorState? navigator =
        appNavigatorKey.currentState;

    if (navigator == null ||
        !navigator.mounted) {
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
                mainAxisSize: MainAxisSize.min,
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
                                CrossAxisAlignment
                                    .start,
                            children: <Widget>[
                              const Text(
                                'Current version',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                updateInfo
                                    .currentVersion,
                                style: const TextStyle(
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
                          color: Colors.black45,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,
                            children: <Widget>[
                              const Text(
                                'New version',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                updateInfo.latestVersion,
                                style: const TextStyle(
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

  // ==========================================================================
  // OPEN UPDATE LINK
  // ==========================================================================

  Future<void> _openUpdateLink(
    AppUpdateInfo updateInfo,
  ) async {
    final NavigatorState? navigator =
        appNavigatorKey.currentState;

    if (navigator == null ||
        !navigator.mounted) {
      return;
    }

    final TargetPlatform platform =
        Theme.of(
          navigator.context,
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
      mode: LaunchMode.externalApplication,
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

  // ==========================================================================
  // THEME
  // ==========================================================================

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor:
            const Color(0xFF2E7D32),
        brightness:
            Brightness.light,
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

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriAI',
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey:
          appScaffoldMessengerKey,
      theme: _buildTheme(),
      home: FirebaseBootstrap(
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

// ============================================================================
// FIREBASE BOOTSTRAP
// ============================================================================

class FirebaseBootstrap extends StatefulWidget {
  const FirebaseBootstrap({
    super.key,
    required this.onAppReady,
  });

  final VoidCallback onAppReady;

  @override
  State<FirebaseBootstrap> createState() =>
      _FirebaseBootstrapState();
}

class _FirebaseBootstrapState
    extends State<FirebaseBootstrap> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();

    _initialization =
        _initializeFirebaseServices();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (
        BuildContext context,
        AsyncSnapshot<void> snapshot,
      ) {
        // --------------------------------------------------------------------
        // SUCCESS
        // --------------------------------------------------------------------

        if (snapshot.connectionState ==
                ConnectionState.done &&
            snapshot.hasData == false &&
            snapshot.error == null) {
          return SplashScreen(
            onAppReady: widget.onAppReady,
          );
        }

        // --------------------------------------------------------------------
        // ERROR
        // --------------------------------------------------------------------

        if (snapshot.hasError) {
          return FirebaseInitializationErrorScreen(
            error: snapshot.error,
            onRetry: () {
              setState(() {
                _initialization =
                    _initializeFirebaseServices();
              });
            },
          );
        }

        // --------------------------------------------------------------------
        // LOADING
        // --------------------------------------------------------------------

        return const _FirebaseLoadingScreen();
      },
    );
  }
}

// ============================================================================
// FIREBASE LOADING SCREEN
// ============================================================================

class _FirebaseLoadingScreen
    extends StatelessWidget {
  const _FirebaseLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FBF8),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFF2E7D32),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Starting AgriAI...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B1B1B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Initializing secure services',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FIREBASE INITIALIZATION ERROR SCREEN
// ============================================================================

class FirebaseInitializationErrorScreen
    extends StatelessWidget {
  const FirebaseInitializationErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FBF8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFFEBEE),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color:
                        Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'AgriAI could not start',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Firebase initialization failed. '
                  'Please retry the application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF1F3F1),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    error?.toString() ??
                        'Unknown initialization error',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Retry',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}