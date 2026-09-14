import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../language_selection_screen.dart';
import '../../services/app_update_service.dart';
import '../auth/login_screen.dart';

typedef ThemeModeChanged = Future<void> Function(
  ThemeMode mode,
);

class SettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool automaticWeatherUpdates;

  final ValueChanged<bool>? onNotificationsChanged;
  final ValueChanged<bool>? onLocationChanged;
  final ValueChanged<bool>? onAutomaticWeatherChanged;

  final VoidCallback? onLanguageTap;
  final VoidCallback? onAboutTap;
  final ThemeModeChanged? onThemeModeChanged;

  const SettingsScreen({
    super.key,
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.automaticWeatherUpdates = true,
    this.onNotificationsChanged,
    this.onLocationChanged,
    this.onAutomaticWeatherChanged,
    this.onLanguageTap,
    this.onAboutTap,
    this.onThemeModeChanged,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _notificationsKey =
      'settings_notifications';

  static const String _locationKey =
      'settings_location';

  static const String _weatherKey =
      'settings_auto_weather';

  static const String _themeKey =
      'app_theme_mode';

  static const String _updateNotificationsKey =
      'settings_update_notifications';

  static const String _githubUrl =
      'https://github.com/zerokhizar-byte/AgriAI';

  static const String _instagramUrl =
      'https://www.instagram.com/0khizar0?stkn=MWlrMmpzeWg0MTh1bA==';

  static const String _linkedinUrl =
      'https://www.linkedin.com/in/khizar-kachi?utm_source=share_via&utm_content=profile&utm_medium=member_android';

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _automaticWeatherUpdates = true;
  bool _updateNotificationsEnabled = true;

  bool _checkingForUpdate = false;
  bool _loadingUpdateStatus = false;

  String _updateStatus = 'loading';
  String _latestVersion = '';
  String _currentVersion = 'Loading...';
  String _selectedLanguage = 'English';

  ThemeMode _themeMode = ThemeMode.system;

  User? get _user =>
      FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    _notificationsEnabled =
        widget.notificationsEnabled;

    _locationEnabled =
        widget.locationEnabled;

    _automaticWeatherUpdates =
        widget.automaticWeatherUpdates;

    _loadSettings();
    _loadCurrentVersion();
    _loadUpdateStatus();
  }

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

  Future<void> _loadSettings() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final String? savedTheme =
          prefs.getString(_themeKey);

      final String? savedLanguage =
          prefs.getString('selected_language');

      final bool updateNotifications =
          prefs.getBool(
                _updateNotificationsKey,
              ) ??
              true;

      debugPrint(
        'AgriAI Settings - '
        'Update Notifications loaded: '
        '$updateNotifications',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notificationsEnabled =
            prefs.getBool(
                  _notificationsKey,
                ) ??
                widget.notificationsEnabled;

        _locationEnabled =
            prefs.getBool(
                  _locationKey,
                ) ??
                widget.locationEnabled;

        _automaticWeatherUpdates =
            prefs.getBool(
                  _weatherKey,
                ) ??
                widget.automaticWeatherUpdates;

        _updateNotificationsEnabled =
            updateNotifications;

        _selectedLanguage =
            savedLanguage != null &&
                    savedLanguage.trim().isNotEmpty
                ? savedLanguage.trim()
                : 'English';

        _themeMode =
            _themeFromString(savedTheme);
      });
    } catch (error) {
      debugPrint(
        'AgriAI Settings load failed: $error',
      );
    }
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final PackageInfo packageInfo =
          await PackageInfo.fromPlatform();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentVersion =
            packageInfo.version.trim().isEmpty
                ? 'Unknown'
                : packageInfo.version.trim();
      });
    } catch (error) {
      debugPrint(
        'AgriAI version load failed: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentVersion = 'Unknown';
      });
    }
  }

  // ===========================================================================
  // UPDATE STATUS
  // ===========================================================================

  Future<void> _loadUpdateStatus() async {
    if (_loadingUpdateStatus) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadingUpdateStatus = true;
      });
    }

    try {
      final AppUpdateInfo updateInfo =
          await AppUpdateService.checkForUpdate();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentVersion =
            updateInfo.currentVersion;

        _latestVersion =
            updateInfo.latestVersion.trim();

        if (updateInfo.updateRequired) {
          _updateStatus = 'required';
        } else if (updateInfo.updateAvailable) {
          _updateStatus = 'available';
        } else {
          _updateStatus = 'up_to_date';
        }
      });

      debugPrint(
        'AgriAI Settings Update Status: '
        '$_updateStatus',
      );
    } catch (error) {
      debugPrint(
        'AgriAI Settings Update Status Failed: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _updateStatus = 'unknown';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingUpdateStatus = false;
        });
      }
    }
  }

  // ===========================================================================
  // MANUAL UPDATE CHECK
  // ===========================================================================

  Future<void> _checkForUpdates() async {
    if (_checkingForUpdate) {
      return;
    }

    setState(() {
      _checkingForUpdate = true;
    });

    debugPrint(
      'AgriAI Settings: Manual update check started.',
    );

    try {
      final AppUpdateInfo updateInfo =
          await AppUpdateService.checkForUpdate();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentVersion =
            updateInfo.currentVersion;

        _latestVersion =
            updateInfo.latestVersion.trim();

        if (updateInfo.updateRequired) {
          _updateStatus = 'required';
        } else if (updateInfo.updateAvailable) {
          _updateStatus = 'available';
        } else {
          _updateStatus = 'up_to_date';
        }
      });

      debugPrint(
        'AgriAI Settings Manual Check: '
        'current=${updateInfo.currentVersion}, '
        'latest=${updateInfo.latestVersion}, '
        'minimum=${updateInfo.minimumVersion}, '
        'available=${updateInfo.updateAvailable}, '
        'required=${updateInfo.updateRequired}',
      );

      if (updateInfo.updateRequired) {
        await _showUpdateDialog(
          updateInfo,
          mandatory: true,
        );

        return;
      }

      if (updateInfo.updateAvailable) {
        await _showUpdateDialog(
          updateInfo,
          mandatory: false,
        );

        return;
      }

      _showMessage(
        'You are using the latest version of AgriAI.',
      );
    } catch (error) {
      debugPrint(
        'AgriAI manual update check failed: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _updateStatus = 'unknown';
      });

      _showMessage(
        'Unable to check for updates. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdate = false;
        });
      }
    }
  }

  // ===========================================================================
  // UPDATE DIALOG
  // ===========================================================================

  Future<void> _showUpdateDialog(
    AppUpdateInfo updateInfo, {
    required bool mandatory,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
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
            titlePadding:
                const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              8,
            ),
            contentPadding:
                const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              12,
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              16,
            ),
            title: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        AppColors.cardGreen,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color:
                        AppColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    mandatory
                        ? 'Update Required'
                        : updateInfo.title.trim().isEmpty
                            ? 'New AgriAI Update Available'
                            : updateInfo.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w800,
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
                  updateInfo.message.trim().isEmpty
                      ? 'A new version of AgriAI is available. '
                          'Update now to get the latest features '
                          'and improvements.'
                      : updateInfo.message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.cardGreen,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.phone_android_rounded,
                        size: 18,
                        color:
                            AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current: '
                          '${updateInfo.currentVersion}',
                          style:
                              const TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'New: '
                        '${updateInfo.latestVersion}',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (mandatory) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(11),
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
                          size: 19,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This update is required '
                            'to continue using AgriAI.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
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
            actions: <Widget>[
              if (!mandatory)
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text('Later'),
                ),
              FilledButton.icon(
                onPressed: () {
                  final String url =
                      Theme.of(
                        dialogContext,
                      ).platform ==
                              TargetPlatform.iOS
                          ? updateInfo.iosStoreUrl
                          : updateInfo.androidStoreUrl;

                  final Uri? uri =
                      Uri.tryParse(
                    url.trim(),
                  );

                  if (uri == null ||
                      !uri.hasScheme ||
                      !uri.hasAuthority) {
                    _showMessage(
                      'The AgriAI update link is not available yet.',
                    );
                    return;
                  }

                  Navigator.of(
                    dialogContext,
                  ).pop();

                  _openStoreUrl(uri);
                },
                icon: const Icon(
                  Icons.download_rounded,
                  size: 18,
                ),
                label:
                    const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStoreUrl(
    Uri uri,
  ) async {
    try {
      final bool launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'Unable to open the update page.',
        );
      }
    } catch (error) {
      debugPrint(
        'AgriAI store launch failed: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to open the update page.',
        );
      }
    }
  }

  // ===========================================================================
  // THEME
  // ===========================================================================

  ThemeMode _themeFromString(
    String? value,
  ) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeToString(
    ThemeMode mode,
  ) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  String _themeLabel() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  Future<void> _setTheme(
    ThemeMode mode,
  ) async {
    setState(() {
      _themeMode = mode;
    });

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      _themeToString(mode),
    );

    if (!mounted) {
      return;
    }

    final ThemeModeChanged? callback =
        widget.onThemeModeChanged;

    if (callback != null) {
      await callback(mode);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    _showMessage(
      'Appearance saved: ${_themeLabel()}',
    );
  }

  Future<void> _showAppearance() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                const _SheetHeader(
                  icon:
                      Icons.palette_outlined,
                  title:
                      'Appearance',
                  subtitle:
                      'Choose how AgriAI should appear.',
                ),
                const SizedBox(height: 14),
                _ThemeChoice(
                  icon:
                      Icons.brightness_auto_rounded,
                  title:
                      'System default',
                  selected:
                      _themeMode ==
                          ThemeMode.system,
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _setTheme(
                      ThemeMode.system,
                    );
                  },
                ),
                _ThemeChoice(
                  icon:
                      Icons.light_mode_rounded,
                  title:
                      'Light',
                  selected:
                      _themeMode ==
                          ThemeMode.light,
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _setTheme(
                      ThemeMode.light,
                    );
                  },
                ),
                _ThemeChoice(
                  icon:
                      Icons.dark_mode_rounded,
                  title:
                      'Dark',
                  selected:
                      _themeMode ==
                          ThemeMode.dark,
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _setTheme(
                      ThemeMode.dark,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BASIC SETTINGS
  // ===========================================================================

  Future<void> _setNotifications(
    bool value,
  ) async {
    setState(() {
      _notificationsEnabled = value;
    });

    widget.onNotificationsChanged?.call(value);

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _notificationsKey,
      value,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      value
          ? 'Notifications enabled.'
          : 'Notifications disabled.',
    );
  }

  Future<void> _setLocation(
    bool value,
  ) async {
    setState(() {
      _locationEnabled = value;
    });

    widget.onLocationChanged?.call(value);

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _locationKey,
      value,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      value
          ? 'Location services enabled.'
          : 'Location services disabled.',
    );
  }

  Future<void> _setWeather(
    bool value,
  ) async {
    setState(() {
      _automaticWeatherUpdates = value;
    });

    widget.onAutomaticWeatherChanged?.call(value);

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _weatherKey,
      value,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      value
          ? 'Automatic weather updates enabled.'
          : 'Automatic weather updates disabled.',
    );
  }

  Future<void> _setUpdateNotifications(
    bool value,
  ) async {
    debugPrint(
      'AgriAI Update Notifications requested: '
      '$value',
    );

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        _updateNotificationsKey,
        value,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _updateNotificationsEnabled =
            value;
      });

      _showMessage(
        value
            ? 'Update notifications enabled.'
            : 'Update notifications disabled.',
      );
    } catch (error) {
      debugPrint(
        'AgriAI Update Notifications save failed: '
        '$error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save update notification preference.',
      );
    }
  }

  // ===========================================================================
  // LANGUAGE
  // ===========================================================================

  Future<void> _openLanguageSelection() async {
    if (widget.onLanguageTap != null) {
      widget.onLanguageTap!.call();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const LanguageSelectionScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    final String? language =
        prefs.getString(
      'selected_language',
    );

    if (language != null &&
        language.trim().isNotEmpty) {
      setState(() {
        _selectedLanguage =
            language.trim();
      });
    }
  }

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  Future<void> _editProfile() async {
    final TextEditingController controller =
        TextEditingController(
      text:
          _user?.displayName ?? '',
    );

    final bool? saved =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title:
              const Text(
            'Edit Profile',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content:
              TextField(
            controller:
                controller,
            maxLength:
                50,
            textInputAction:
                TextInputAction.done,
            decoration:
                InputDecoration(
              labelText:
                  'Farmer name',
              hintText:
                  'Enter your name',
              prefixIcon:
                  const Icon(
                Icons
                    .person_outline_rounded,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
          ),
          actions:
              <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final String name =
                    controller.text.trim();

                if (name.isEmpty) {
                  _showMessage(
                    'Please enter your name.',
                  );
                  return;
                }

                try {
                  await _user
                      ?.updateDisplayName(
                    name,
                  );

                  await _user?.reload();

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(
                    dialogContext,
                  ).pop(true);
                } catch (_) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(
                    dialogContext,
                  ).pop(false);
                }
              },
              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted ||
        saved != true) {
      return;
    }

    setState(() {});

    _showMessage(
      'Profile updated successfully.',
    );
  }

  // ===========================================================================
  // MORE FEATURES
  // ===========================================================================

  Future<void> _showMoreFeatures() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                const _SheetHeader(
                  icon:
                      Icons.auto_awesome_rounded,
                  title:
                      'More Features',
                  subtitle:
                      'Explore AgriAI tools and insights.',
                ),
                const SizedBox(height: 14),
                _FeatureQuickTile(
                  icon:
                      Icons.history_rounded,
                  title:
                      'Prediction History',
                  subtitle:
                      'Review saved yield predictions',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Prediction history will be available here.',
                    );
                  },
                ),
                _FeatureQuickTile(
                  icon:
                      Icons.agriculture_rounded,
                  title:
                      'Crop Insights',
                  subtitle:
                      'Use crop-specific recommendations',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Crop insights are available through Yield.',
                    );
                  },
                ),
                _FeatureQuickTile(
                  icon:
                      Icons.health_and_safety_outlined,
                  title:
                      'Disease Detection',
                  subtitle:
                      'Analyze plant diseases using AI',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Open Disease from the bottom navigation.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // SOCIAL
  // ===========================================================================

  Future<void> _socialMedia() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                const _SheetHeader(
                  icon:
                      Icons.public_rounded,
                  title:
                      'Connect With Us',
                  subtitle:
                      'Follow the AgriAI developer and project.',
                ),
                const SizedBox(height: 14),
                _SocialTile(
                  icon:
                      Icons.code_rounded,
                  title:
                      'GitHub',
                  subtitle:
                      'AgriAI project repository',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _openExternalLink(
                      _githubUrl,
                    );
                  },
                ),
                _SocialTile(
                  icon:
                      Icons.camera_alt_rounded,
                  title:
                      'Instagram',
                  subtitle:
                      '@0khizar0',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _openExternalLink(
                      _instagramUrl,
                    );
                  },
                ),
                _SocialTile(
                  icon:
                      Icons.business_center_rounded,
                  title:
                      'LinkedIn',
                  subtitle:
                      'Khizar Kachi',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _openExternalLink(
                      _linkedinUrl,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openExternalLink(
    String url,
  ) async {
    final Uri? uri =
        Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme) {
      _showMessage(
        'Invalid link.',
      );
      return;
    }

    try {
      final bool launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched &&
          mounted) {
        _showMessage(
          'Unable to open the link.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to open the link.',
        );
      }
    }
  }

  // ===========================================================================
  // DEVELOPER
  // ===========================================================================

  Future<void> _showDeveloperInfo() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              28,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                const CircleAvatar(
                  radius: 31,
                  backgroundColor:
                      AppColors.cardGreen,
                  child: Icon(
                    Icons.code_rounded,
                    size: 30,
                    color:
                        AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AgriAI Developer',
                  style:
                      TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Crop Yield & Plant Disease Prediction System',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoLine(
                  icon:
                      Icons.phone_android_rounded,
                  label:
                      'Platform',
                  value:
                      'Flutter / Android',
                ),
                _InfoLine(
                  icon:
                      Icons.auto_awesome_rounded,
                  label:
                      'Purpose',
                  value:
                      'AI-assisted agriculture',
                ),
                _InfoLine(
                  icon:
                      Icons.verified_outlined,
                  label:
                      'Version',
                  value:
                      _currentVersion,
                ),
                const SizedBox(height: 14),
                _SocialActionButton(
                  icon:
                      Icons.public_rounded,
                  title:
                      'Open GitHub',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _openExternalLink(
                      _githubUrl,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ABOUT
  // ===========================================================================

  Future<void> _showAbout() async {
    if (widget.onAboutTap != null) {
      widget.onAboutTap!.call();
      return;
    }

    showAboutDialog(
      context: context,
      applicationName:
          'AgriAI',
      applicationVersion:
          _currentVersion,
      applicationLegalese:
          'Smart Agriculture Application',
      children: const <Widget>[
        SizedBox(height: 12),
        Text(
          'AgriAI helps farmers make smarter decisions using crop, soil, weather and AI-based agricultural insights.',
        ),
      ],
    );
  }

  // ===========================================================================
  // PRIVACY / TERMS
  // ===========================================================================

  Future<void> _showPrivacy() async {
    await _showTextPage(
      title:
          'Privacy',
      icon:
          Icons.privacy_tip_outlined,
      paragraphs:
          const <String>[
        'AgriAI uses account and application preferences to provide its features.',
        'Location is used when the user chooses location-based functionality such as Automatic GPS.',
        'Location permission can be controlled from Android settings.',
      ],
    );
  }

  Future<void> _showTerms() async {
    await _showTextPage(
      title:
          'Terms of Use',
      icon:
          Icons.gavel_outlined,
      paragraphs:
          const <String>[
        'AgriAI is an agricultural decision-support and educational application.',
        'Predictions should be reviewed alongside local agricultural knowledge and current field conditions.',
        'The application does not replace professional agronomic or government advice.',
      ],
    );
  }

  Future<void> _showTextPage({
    required String title,
    required IconData icon,
    required List<String> paragraphs,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor:
                0.76,
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.cardGreen,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color:
                              AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...paragraphs.map(
                    (
                      String paragraph,
                    ) =>
                        Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: Text(
                        paragraph,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> _logout() async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title:
              const Text(
            'Log out?',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content:
              const Text(
            'You will need to sign in again to use your AgriAI account.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    try {
      await FirebaseAuth.instance
          .signOut();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to log out. Please try again.',
        );
      }

      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            const LoginScreen(),
      ),
      (Route<dynamic> route) =>
          false,
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final User? user = _user;

    final String name =
        user?.displayName
                    ?.trim()
                    .isNotEmpty ==
                true
            ? user!.displayName!.trim()
            : 'Farmer';

    final String email =
        user?.email
                    ?.trim()
                    .isNotEmpty ==
                true
            ? user!.email!.trim()
            : 'No email available';

    final String initial =
        name.trim().isEmpty
            ? 'F'
            : name
                .trim()
                .characters
                .first
                .toUpperCase();

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar:
          AppBar(
        title:
            const Text(
          'Settings',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation:
            0,
      ),
      body:
          SafeArea(
        child:
            RefreshIndicator(
          color:
              AppColors.primary,
          onRefresh:
              () async {
            await _loadSettings();
            await _loadCurrentVersion();
            await _loadUpdateStatus();
          },
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              34,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFFEAF7EC),
                        Color(0xFFF7FCF8),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    border:
                        Border.all(
                      color:
                          AppColors.border,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color:
                            AppColors.shadow
                                .withValues(
                          alpha:
                              0.06,
                        ),
                        blurRadius:
                            18,
                        offset:
                            const Offset(
                          0,
                          7,
                        ),
                      ),
                    ],
                  ),
                  child:
                      Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius:
                            31,
                        backgroundColor:
                            AppColors.primary,
                        backgroundImage:
                            user?.photoURL
                                        ?.isNotEmpty ==
                                    true
                                ? NetworkImage(
                                    user!.photoURL!,
                                  )
                                : null,
                        child:
                            user?.photoURL
                                        ?.isNotEmpty ==
                                    true
                                ? null
                                : Text(
                                    initial,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          23,
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                      ),
                      const SizedBox(
                        width:
                            13,
                      ),
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Account Settings',
                              style:
                                  TextStyle(
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  2,
                            ),
                            Text(
                              name,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  2,
                            ),
                            Text(
                              email,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    10.5,
                                color:
                                    AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip:
                            'Edit profile',
                        onPressed:
                            _editProfile,
                        icon:
                            const Icon(
                          Icons
                              .edit_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                      24,
                ),

                const _SettingsSectionTitle(
                  title:
                      'Preferences',
                  subtitle:
                      'Control how AgriAI behaves.',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _SettingsCard(
                  children: <Widget>[
                    _SettingsSwitchTile(
                      icon:
                          Icons
                              .notifications_none_rounded,
                      title:
                          'Notifications',
                      subtitle:
                          'Receive farming alerts and recommendations',
                      value:
                          _notificationsEnabled,
                      onChanged:
                          _setNotifications,
                    ),
                    const _SettingsDivider(),
                    _SettingsSwitchTile(
                      icon:
                          Icons
                              .location_on_outlined,
                      title:
                          'Location',
                      subtitle:
                          'Use your location for local weather data',
                      value:
                          _locationEnabled,
                      onChanged:
                          _setLocation,
                    ),
                    const _SettingsDivider(),
                    _SettingsSwitchTile(
                      icon:
                          Icons
                              .cloud_outlined,
                      title:
                          'Automatic Weather Updates',
                      subtitle:
                          'Keep weather information updated automatically',
                      value:
                          _automaticWeatherUpdates,
                      onChanged:
                          _setWeather,
                    ),
                    const _SettingsDivider(),
                    _SettingsSwitchTile(
                      icon:
                          Icons
                              .system_update_outlined,
                      title:
                          'Update Notifications',
                      subtitle:
                          'Notify you when a newer AgriAI version is available',
                      value:
                          _updateNotificationsEnabled,
                      onChanged:
                          _setUpdateNotifications,
                    ),
                    const _SettingsDivider(),
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .palette_outlined,
                      title:
                          'Appearance',
                      subtitle:
                          _themeLabel(),
                      onTap:
                          _showAppearance,
                    ),
                    const _SettingsDivider(),
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .language_rounded,
                      title:
                          'Language',
                      subtitle:
                          _selectedLanguage,
                      onTap:
                          _openLanguageSelection,
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      24,
                ),

                const _SettingsSectionTitle(
                  title:
                      'App Updates',
                  subtitle:
                      'Keep AgriAI up to date.',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _UpdateCard(
                  currentVersion:
                      _currentVersion,
                  latestVersion:
                      _latestVersion,
                  status:
                      _updateStatus,
                  checking:
                      _checkingForUpdate,
                  loadingStatus:
                      _loadingUpdateStatus,
                  onCheck:
                      _checkForUpdates,
                ),

                const SizedBox(
                  height:
                      24,
                ),

                const _SettingsSectionTitle(
                  title:
                      'Connect',
                  subtitle:
                      'Follow the project and developer.',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _SettingsCard(
                  children: <Widget>[
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .public_rounded,
                      title:
                          'Social Media',
                      subtitle:
                          'Instagram, LinkedIn and GitHub',
                      onTap:
                          _socialMedia,
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      24,
                ),

                const _SettingsSectionTitle(
                  title:
                      'AgriAI Tools',
                  subtitle:
                      'Explore more agricultural features.',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _SettingsCard(
                  children: <Widget>[
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .auto_awesome_rounded,
                      title:
                          'More Features',
                      subtitle:
                          'Explore AgriAI tools and insights',
                      onTap:
                          _showMoreFeatures,
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      24,
                ),

                const _SettingsSectionTitle(
                  title:
                      'Developer',
                  subtitle:
                      'Project information and resources.',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _SettingsCard(
                  children: <Widget>[
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .code_rounded,
                      title:
                          'Developer Info',
                      subtitle:
                          'Project and technology information',
                      onTap:
                          _showDeveloperInfo,
                    ),
                    const _SettingsDivider(),
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .public_rounded,
                      title:
                          'GitHub',
                      subtitle:
                          'Open the AgriAI source repository',
                      onTap:
                          () => _openExternalLink(
                        _githubUrl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      24,
                ),

                const _SettingsSectionTitle(
                  title:
                      'About',
                  subtitle:
                      'Information about AgriAI.',
                ),

                const SizedBox(
                  height:
                      10,
                ),

                _SettingsCard(
                  children: <Widget>[
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .info_outline_rounded,
                      title:
                          'About AgriAI',
                      subtitle:
                          'App information and project details',
                      onTap:
                          _showAbout,
                    ),
                    const _SettingsDivider(),
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .privacy_tip_outlined,
                      title:
                          'Privacy',
                      subtitle:
                          'Permissions and data handling',
                      onTap:
                          _showPrivacy,
                    ),
                    const _SettingsDivider(),
                    _SettingsNavigationTile(
                      icon:
                          Icons
                              .gavel_outlined,
                      title:
                          'Terms of Use',
                      subtitle:
                          'Application usage terms',
                      onTap:
                          _showTerms,
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      24,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.cardGreen,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    border:
                        Border.all(
                      color:
                          AppColors.border,
                    ),
                  ),
                  child:
                      const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons
                            .eco_outlined,
                        size:
                            24,
                        color:
                            AppColors.primary,
                      ),
                      SizedBox(
                        width:
                            12,
                      ),
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Smart farming with AgriAI',
                              style:
                                  TextStyle(
                                fontSize:
                                    13,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height:
                                  5,
                            ),
                            Text(
                              'Make smarter agricultural decisions using weather, soil, crop and AI-based insights.',
                              style:
                                  TextStyle(
                                fontSize:
                                    11.5,
                                height:
                                    1.45,
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

                const SizedBox(
                  height:
                      22,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _logout,
                    icon:
                        const Icon(
                      Icons
                          .logout_rounded,
                    ),
                    label:
                        const Text(
                      'Log out',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.danger,
                      side:
                          const BorderSide(
                        color:
                            AppColors.danger,
                      ),
                      minimumSize:
                          const Size(
                        double.infinity,
                        54,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      15,
                ),

                Center(
                  child:
                      Text(
                    'AgriAI • Version $_currentVersion',
                    style:
                        const TextStyle(
                      fontSize:
                          10.5,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppColors.textMuted,
                    ),
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

// ============================================================================
// UPDATE CARD
// ============================================================================

class _UpdateCard extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String status;
  final bool checking;
  final bool loadingStatus;
  final VoidCallback onCheck;

  const _UpdateCard({
    required this.currentVersion,
    required this.latestVersion,
    required this.status,
    required this.checking,
    required this.loadingStatus,
    required this.onCheck,
  });

  String get _statusLabel {
    switch (status) {
      case 'required':
        return 'UPDATE REQUIRED';
      case 'available':
        return 'UPDATE AVAILABLE';
      case 'up_to_date':
        return 'UP TO DATE';
      default:
        return 'CHECKING...';
    }
  }

  Color get _statusBackground {
    switch (status) {
      case 'required':
        return const Color(0xFFFFEBEE);
      case 'available':
        return const Color(0xFFFFF3E0);
      case 'up_to_date':
        return AppColors.cardGreen;
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color get _statusForeground {
    switch (status) {
      case 'required':
        return const Color(0xFFC62828);
      case 'available':
        return const Color(0xFFE65100);
      case 'up_to_date':
        return AppColors.primary;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusMessage {
    switch (status) {
      case 'required':
        return 'A newer version is required to continue using AgriAI.';
      case 'available':
        return latestVersion.isEmpty
            ? 'A newer version of AgriAI is available.'
            : 'Version $latestVersion is available.';
      case 'up_to_date':
        return 'You are using the latest version of AgriAI.';
      default:
        return 'Checking the latest AgriAI version...';
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                AppColors.shadow
                    .withValues(
              alpha:
                  0.05,
            ),
            blurRadius:
                14,
            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child:
          Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width:
                    48,
                height:
                    48,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child:
                    const Icon(
                  Icons.system_update_rounded,
                  color:
                      AppColors.primary,
                  size:
                      24,
                ),
              ),
              const SizedBox(
                width:
                    13,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'AgriAI Updates',
                      style:
                          TextStyle(
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height:
                          4,
                    ),
                    Text(
                      'Current version: $currentVersion',
                      style:
                          const TextStyle(
                        fontSize:
                            11,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    if (latestVersion.isNotEmpty)
                      const SizedBox(
                        height:
                            2,
                      ),
                    if (latestVersion.isNotEmpty)
                      Text(
                        'Latest version: $latestVersion',
                        style:
                            const TextStyle(
                          fontSize:
                              10.5,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(
                width:
                    8,
              ),
              if (loadingStatus)
                const SizedBox(
                  width:
                      20,
                  height:
                      20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                    color:
                        AppColors.primary,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        9,
                    vertical:
                        6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        _statusBackground,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child:
                      Text(
                    _statusLabel,
                    style:
                        TextStyle(
                      fontSize:
                          7.5,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          _statusForeground,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height:
                12,
          ),
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  12,
              vertical:
                  10,
            ),
            decoration:
                BoxDecoration(
              color:
                  _statusBackground,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child:
                Row(
              children: <Widget>[
                Icon(
                  status == 'required'
                      ? Icons
                          .warning_amber_rounded
                      : status == 'available'
                          ? Icons
                              .new_releases_outlined
                          : status == 'up_to_date'
                              ? Icons
                                  .check_circle_outline
                              : Icons
                                  .sync_rounded,
                  size:
                      18,
                  color:
                      _statusForeground,
                ),
                const SizedBox(
                  width:
                      8,
                ),
                Expanded(
                  child:
                      Text(
                    _statusMessage,
                    style:
                        TextStyle(
                      fontSize:
                          10.5,
                      height:
                          1.3,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          _statusForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height:
                15,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton.icon(
              onPressed:
                  checking
                      ? null
                      : onCheck,
              icon:
                  checking
                      ? const SizedBox(
                          width:
                              17,
                          height:
                              17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .refresh_rounded,
                          size:
                              19,
                        ),
              label:
                  Text(
                checking
                    ? 'Checking for Updates...'
                    : 'Check for Updates',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                minimumSize:
                    const Size(
                  double.infinity,
                  50,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE WIDGETS
// ============================================================================

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: <Widget>[
        Container(
          width:
              50,
          height:
              50,
          decoration:
              BoxDecoration(
            color:
                AppColors.cardGreen,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child:
              Icon(
            icon,
            color:
                AppColors.primary,
            size:
                26,
          ),
        ),
        const SizedBox(
          height:
              10,
        ),
        Text(
          title,
          style:
              const TextStyle(
            fontSize:
                19,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(
          height:
              4,
        ),
        Text(
          subtitle,
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            fontSize:
                11,
            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionTitle
    extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style:
              const TextStyle(
            fontSize:
                16,
            fontWeight:
                FontWeight.w900,
            color:
                AppColors.textPrimary,
          ),
        ),
        const SizedBox(
          height:
              2,
        ),
        Text(
          subtitle,
          style:
              const TextStyle(
            fontSize:
                10.5,
            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard
    extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                AppColors.shadow
                    .withValues(
              alpha:
                  0.045,
            ),
            blurRadius:
                13,
            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child:
          Column(
        children:
            children,
      ),
    );
  }
}

class _SettingsSwitchTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>
      onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.all(14),
      child:
          Row(
        children: <Widget>[
          _SettingsIcon(
            icon:
                icon,
          ),
          const SizedBox(
            width:
                12,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize:
                        13.5,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                const SizedBox(
                  height:
                      3,
                ),
                Text(
                  subtitle,
                  maxLines:
                      2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize:
                        10.5,
                    height:
                        1.3,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width:
                6,
          ),
          Switch.adaptive(
            value:
                value,
            activeThumbColor:
                Colors.white,
            activeTrackColor:
                AppColors.primary,
            onChanged:
                onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsNavigationTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          AppDimensions.radius18,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.all(14),
          child:
              Row(
            children: <Widget>[
              _SettingsIcon(
                icon:
                    icon,
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize:
                            13.5,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      subtitle,
                      maxLines:
                          2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize:
                            10.5,
                        height:
                            1.3,
                        fontWeight:
                            FontWeight.w500,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width:
                    8,
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size:
                    22,
                color:
                    AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon
    extends StatelessWidget {
  final IconData icon;

  const _SettingsIcon({
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          43,
      height:
          43,
      decoration:
          BoxDecoration(
        color:
            AppColors.cardGreen,
        borderRadius:
            BorderRadius.circular(13),
      ),
      child:
          Icon(
        icon,
        size:
            21,
        color:
            AppColors.primary,
      ),
    );
  }
}

class _SettingsDivider
    extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Padding(
      padding:
          EdgeInsets.only(
        left:
            69,
      ),
      child:
          Divider(
        height:
            1,
        color:
            AppColors.divider,
      ),
    );
  }
}

class _ThemeChoice
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      leading:
          _SettingsIcon(
        icon:
            icon,
      ),
      title:
          Text(
        title,
        style:
            const TextStyle(
          fontSize:
              13.5,
          fontWeight:
              FontWeight.w700,
        ),
      ),
      trailing:
          Icon(
        selected
            ? Icons
                .radio_button_checked_rounded
            : Icons
                .radio_button_off_rounded,
        color:
            selected
                ? AppColors.primary
                : AppColors.textMuted,
      ),
      onTap:
          onTap,
    );
  }
}

class _FeatureQuickTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureQuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      leading:
          _SettingsIcon(
        icon:
            icon,
      ),
      title:
          Text(
        title,
        style:
            const TextStyle(
          fontSize:
              13.5,
          fontWeight:
              FontWeight.w700,
        ),
      ),
      subtitle:
          Text(
        subtitle,
        style:
            const TextStyle(
          fontSize:
              10.5,
          color:
              AppColors.textSecondary,
        ),
      ),
      trailing:
          const Icon(
        Icons.chevron_right_rounded,
        color:
            AppColors.textMuted,
      ),
      onTap:
          onTap,
    );
  }
}

class _SocialTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SocialTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      leading:
          _SettingsIcon(
        icon:
            icon,
      ),
      title:
          Text(
        title,
        style:
            const TextStyle(
          fontSize:
              13.5,
          fontWeight:
              FontWeight.w700,
        ),
      ),
      subtitle:
          Text(
        subtitle,
        style:
            const TextStyle(
          fontSize:
              10.5,
          color:
              AppColors.textSecondary,
        ),
      ),
      trailing:
          const Icon(
        Icons.open_in_new_rounded,
        size:
            19,
        color:
            AppColors.textMuted,
      ),
      onTap:
          onTap,
    );
  }
}

class _SocialActionButton
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SocialActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width:
          double.infinity,
      child:
          OutlinedButton.icon(
        onPressed:
            onTap,
        icon:
            Icon(icon),
        label:
            Text(title),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              AppColors.primary,
          side:
              const BorderSide(
            color:
                AppColors.primary,
          ),
          minimumSize:
              const Size(
            double.infinity,
            48,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _InfoLine
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            5,
      ),
      child:
          Row(
        children: <Widget>[
          Icon(
            icon,
            size:
                19,
            color:
                AppColors.primary,
          ),
          const SizedBox(
            width:
                10,
          ),
          Expanded(
            child:
                Text(
              label,
              style:
                  const TextStyle(
                fontSize:
                    12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child:
                Text(
                  value,
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    fontSize:
                        10.5,
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