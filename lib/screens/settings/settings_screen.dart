import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../language_selection_screen.dart';
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

class _SettingsScreenState
    extends State<SettingsScreen> {
  static const String _notificationsKey =
      'settings_notifications';

  static const String _locationKey =
      'settings_location';

  static const String _weatherKey =
      'settings_auto_weather';

  static const String _themeKey =
      'app_theme_mode';

  static const String _githubUrl =
      'https://github.com/zerokhizar-byte/AgriAI';

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _automaticWeatherUpdates = true;

  ThemeMode _themeMode = ThemeMode.system;

  String _selectedLanguage = 'English';

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
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    final String? savedTheme =
        prefs.getString(_themeKey);

    final String? savedLanguage =
        prefs.getString('selected_language');

    setState(() {
      _notificationsEnabled =
          prefs.getBool(_notificationsKey) ??
              widget.notificationsEnabled;

      _locationEnabled =
          prefs.getBool(_locationKey) ??
              widget.locationEnabled;

      _automaticWeatherUpdates =
          prefs.getBool(_weatherKey) ??
              widget.automaticWeatherUpdates;

      _selectedLanguage =
          savedLanguage != null &&
                  savedLanguage.trim().isNotEmpty
              ? savedLanguage.trim()
              : 'English';

      _themeMode =
          _themeFromString(savedTheme);
    });
  }

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

  Future<void> _setNotifications(
    bool value,
  ) async {
    if (!mounted) {
      return;
    }

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
  }

  Future<void> _setLocation(
    bool value,
  ) async {
    if (!mounted) {
      return;
    }

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
  }

  Future<void> _setWeather(
    bool value,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _automaticWeatherUpdates = value;
    });

    widget.onAutomaticWeatherChanged
        ?.call(value);

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _weatherKey,
      value,
    );
  }

  Future<void> _setTheme(
    ThemeMode mode,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = mode;
    });

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      _themeToString(mode),
    );

    final ThemeModeChanged? callback =
        widget.onThemeModeChanged;

    if (callback != null) {
      await callback(mode);
    }

    if (!mounted) {
      return;
    }

    _showMessage(
      'Appearance saved: ${_themeLabel()}',
    );
  }

  Future<void> _openLanguageSelection()
      async {
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

    final String? language =
        prefs.getString('selected_language');

    if (language != null &&
        language.trim().isNotEmpty) {
      setState(() {
        _selectedLanguage =
            language.trim();
      });
    }
  }

  Future<void> _editProfile() async {
    final TextEditingController controller =
        TextEditingController(
      text: _user?.displayName ?? '',
    );

    final bool? saved =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Edit Profile',
          ),
          content: TextField(
            controller: controller,
            maxLength: 50,
            textInputAction:
                TextInputAction.done,
            decoration:
                const InputDecoration(
              labelText: 'Farmer name',
              hintText: 'Enter your name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final String name =
                    controller.text.trim();

                if (name.isEmpty) {
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
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || saved != true) {
      return;
    }

    setState(() {});

    _showMessage(
      'Profile updated successfully.',
    );
  }

  Future<void> _showAppearance()
      async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
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
              children: [
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Choose how AgriAI should appear.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                _ThemeChoice(
                  icon: Icons
                      .brightness_auto_rounded,
                  title: 'System default',
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
                  title: 'Light',
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
                  title: 'Dark',
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

  Future<void> _showDeveloperInfo()
      async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
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
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      AppColors.cardGreen,
                  child: Icon(
                    Icons.code_rounded,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  'AgriAI Developer',
                  style:
                      TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                const Text(
                  'Crop Yield & Plant Disease Prediction System',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                const _InfoLine(
                  icon:
                      Icons.phone_android_rounded,
                  label: 'Platform',
                  value:
                      'Flutter / Android',
                ),
                const _InfoLine(
                  icon:
                      Icons.auto_awesome_rounded,
                  label: 'Purpose',
                  value:
                      'AI-assisted agriculture',
                ),
                const _InfoLine(
                  icon:
                      Icons.verified_outlined,
                  label: 'Version',
                  value: '1.0.0 Trial',
                ),
                const SizedBox(
                  height: 12,
                ),
                SelectableText(
                  _githubUrl,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAbout() async {
    if (widget.onAboutTap != null) {
      widget.onAboutTap!.call();
      return;
    }

    // IMPORTANT:
    // showAboutDialog returns void, so it must NOT be awaited.
    showAboutDialog(
      context: context,
      applicationName: 'AgriAI',
      applicationVersion:
          '1.0.0 Trial',
      applicationLegalese:
          'Smart Agriculture Application',
      children: const [
        SizedBox(
          height: 12,
        ),
        Text(
          'AgriAI helps farmers make smarter decisions using crop, soil, weather and AI-based agricultural insights.',
        ),
      ],
    );
  }

  Future<void> _showMoreFeatures()
      async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
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
              children: [
                const Text(
                  'More Features',
                  style:
                      TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
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
                      'Prediction history is available in Yield Production.',
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
                      'Crop insights are available through Yield Production.',
                    );
                  },
                ),
                _FeatureQuickTile(
                  icon:
                      Icons.health_and_safety_outlined,
                  title:
                      'Disease Detection',
                  subtitle:
                      'Use the plant disease prediction feature',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Open Disease Detection from bottom navigation.',
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

  Future<void> _showPrivacy()
      async {
    await _showTextPage(
      title: 'Privacy',
      icon:
          Icons.privacy_tip_outlined,
      paragraphs: const [
        'AgriAI uses account and application preferences to provide its features.',
        'Location is used when the user chooses location-based functionality such as Automatic GPS.',
        'Location permission can be controlled from Android settings.',
      ],
    );
  }

  Future<void> _showTerms() async {
    await _showTextPage(
      title: 'Terms of Use',
      icon: Icons.gavel_outlined,
      paragraphs: const [
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
          Theme.of(context)
              .colorScheme
              .surface,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.76,
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
                children: [
                  Row(
                    children: [
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
                      const SizedBox(
                        width: 12,
                      ),
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
                  const SizedBox(
                    height: 20,
                  ),
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

  Future<void> _socialMedia()
      async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .surface,
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
              children: [
                const Text(
                  'Social Media',
                  style:
                      TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
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

                    _showLink(
                      'GitHub',
                      _githubUrl,
                    );
                  },
                ),
                _SocialTile(
                  icon:
                      Icons.camera_alt_outlined,
                  title:
                      'Instagram',
                  subtitle:
                      'Configure official account later',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Add your official Instagram URL before publishing.',
                    );
                  },
                ),
                _SocialTile(
                  icon:
                      Icons.play_circle_outline_rounded,
                  title:
                      'YouTube',
                  subtitle:
                      'Configure official channel later',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Add your official YouTube URL before publishing.',
                    );
                  },
                ),
                _SocialTile(
                  icon:
                      Icons.business_center_outlined,
                  title:
                      'LinkedIn',
                  subtitle:
                      'Configure official profile later',
                  onTap: () {
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    _showMessage(
                      'Add your official LinkedIn URL before publishing.',
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

  Future<void> _showLink(
    String title,
    String value,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title:
              Text(title),
          content:
              SelectableText(value),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title:
              const Text('Log out?'),
          content:
              const Text(
            'You will need to sign in again to use your AgriAI account.',
          ),
          actions: [
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
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
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
              _loadSettings,
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              34,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                _ProfileCard(
                  name:
                      name,
                  email:
                      email,
                  onEdit:
                      _editProfile,
                ),
                const SizedBox(
                  height: 22,
                ),
                const _SettingsSectionTitle(
                  title:
                      'App Settings',
                ),
                const SizedBox(
                  height: 10,
                ),
                _SettingsCard(
                  children: [
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
                          Icons.cloud_outlined,
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
                    _SettingsNavigationTile(
                      icon:
                          Icons.palette_outlined,
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
                          Icons.language_rounded,
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
                  height: 22,
                ),
                const _SettingsSectionTitle(
                  title:
                      'More Features',
                ),
                const SizedBox(
                  height: 10,
                ),
                _SettingsCard(
                  children: [
                    _SettingsNavigationTile(
                      icon:
                          Icons.auto_awesome_rounded,
                      title:
                          'More Features',
                      subtitle:
                          'Explore AgriAI tools and insights',
                      onTap:
                          _showMoreFeatures,
                    ),
                    const _SettingsDivider(),
                    _SettingsNavigationTile(
                      icon:
                          Icons.share_outlined,
                      title:
                          'Social Media',
                      subtitle:
                          'GitHub and social links',
                      onTap:
                          _socialMedia,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 22,
                ),
                const _SettingsSectionTitle(
                  title:
                      'Developer',
                ),
                const SizedBox(
                  height: 10,
                ),
                _SettingsCard(
                  children: [
                    _SettingsNavigationTile(
                      icon:
                          Icons.code_rounded,
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
                          Icons.public_rounded,
                      title:
                          'GitHub',
                      subtitle:
                          'AgriAI source repository',
                      onTap:
                          () => _showLink(
                        'GitHub',
                        _githubUrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 22,
                ),
                const _SettingsSectionTitle(
                  title:
                      'About',
                ),
                const SizedBox(
                  height: 10,
                ),
                _SettingsCard(
                  children: [
                    _SettingsNavigationTile(
                      icon:
                          Icons.info_outline_rounded,
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
                          Icons.privacy_tip_outlined,
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
                          Icons.gavel_outlined,
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
                  height: 22,
                ),
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    17,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.cardGreen,
                    borderRadius:
                        BorderRadius.circular(
                      AppDimensions
                          .radius18,
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
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size:
                            22,
                        color:
                            AppColors.primary,
                      ),
                      SizedBox(
                        width:
                            11,
                      ),
                      Expanded(
                        child:
                            Text(
                          'AgriAI helps farmers make smarter decisions using weather, soil, crop and AI-based agricultural insights.',
                          style:
                              TextStyle(
                            fontSize:
                                12,
                            height:
                                1.45,
                            fontWeight:
                                FontWeight
                                    .w500,
                            color:
                                AppColors
                                    .textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 22,
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
                      Icons.logout_rounded,
                    ),
                    label:
                        const Text(
                      'Log out',
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
                        52,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                const Center(
                  child:
                      Text(
                    'AgriAI • Version 1.0.0 Trial',
                    style:
                        TextStyle(
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

class _ProfileCard
    extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String initial =
        name.trim().isEmpty
            ? 'F'
            : name
                .trim()
                .characters
                .first
                .toUpperCase();

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        17,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
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
          Row(
        children: [
          CircleAvatar(
            radius:
                30,
            backgroundColor:
                AppColors.cardGreen,
            child:
                Text(
              initial,
              style:
                  const TextStyle(
                fontSize:
                    23,
                fontWeight:
                    FontWeight.w900,
                color:
                    AppColors.primary,
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
              children: [
                const Text(
                  'Profile',
                  style:
                      TextStyle(
                    fontSize:
                        10.5,
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
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                const SizedBox(
                  height:
                      3,
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
                    fontWeight:
                        FontWeight.w500,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed:
                onEdit,
            tooltip:
                'Edit profile',
            icon:
                const Icon(
              Icons.edit_outlined,
              color:
                  AppColors.primary,
            ),
          ),
        ],
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
        children: [
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
                color:
                    AppColors.textPrimary,
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
          color:
              AppColors.textPrimary,
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
    return _FeatureQuickTile(
      icon:
          icon,
      title:
          title,
      subtitle:
          subtitle,
      onTap:
          onTap,
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
            BorderRadius.circular(
          14,
        ),
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
          color:
              AppColors.textPrimary,
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

class _SettingsSectionTitle
    extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,
      style:
          const TextStyle(
        fontSize:
            16,
        fontWeight:
            FontWeight.w800,
        color:
            AppColors.textPrimary,
      ),
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
        boxShadow: [
          BoxShadow(
            color:
                AppColors.shadow.withValues(
              alpha:
                  0.05,
            ),
            blurRadius:
                12,
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
  final ValueChanged<bool>?
      onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.all(
        15,
      ),
      child:
          Row(
        children: [
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
              children: [
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
    this.onTap,
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
              const EdgeInsets.all(
            15,
          ),
          child:
              Row(
            children: [
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
                  children: [
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
            BorderRadius.circular(
          13,
        ),
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
            70,
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