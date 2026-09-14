import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final String title;
  final String message;
  final String androidStoreUrl;
  final String iosStoreUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.title,
    required this.message,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  /// Returns true when a newer version is available.
  bool get updateAvailable {
    return AppUpdateService.isVersionGreater(
      latestVersion,
      currentVersion,
    );
  }

  /// Returns true when the installed version is below
  /// the minimum supported version.
  bool get updateRequired {
    return AppUpdateService.isVersionGreater(
      minimumVersion,
      currentVersion,
    );
  }
}

class AppUpdateService {
  AppUpdateService._();

  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  /// Checks Firebase Remote Config for the latest app version.
  static Future<AppUpdateInfo> checkForUpdate() async {
    final PackageInfo packageInfo =
        await PackageInfo.fromPlatform();

    await _configureRemoteConfig();

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (error) {
      // If the network request fails, continue using
      // the last activated values or the local defaults.
      //
      // This prevents the update system from breaking
      // the application when the device is offline.
    }

    return AppUpdateInfo(
      currentVersion: packageInfo.version.trim(),

      latestVersion:
          _remoteConfig.getString('latest_version').trim(),

      minimumVersion:
          _remoteConfig.getString('minimum_version').trim(),

      title:
          _remoteConfig.getString('update_title').trim(),

      message:
          _remoteConfig.getString('update_message').trim(),

      androidStoreUrl:
          _remoteConfig.getString('android_store_url').trim(),

      iosStoreUrl:
          _remoteConfig.getString('ios_store_url').trim(),
    );
  }

  /// Configures Firebase Remote Config.
  static Future<void> _configureRemoteConfig() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),

        // TEMPORARY FOR TESTING.
        //
        // This allows Firebase Remote Config to fetch the
        // new value immediately instead of waiting one hour.
        minimumFetchInterval: Duration.zero,
      ),
    );

    await _remoteConfig.setDefaults(
      <String, dynamic>{
        'latest_version': '1.0.0',
        'minimum_version': '1.0.0',

        'update_title':
            'New AgriAI Update Available',

        'update_message':
            'A new version of AgriAI is available. '
            'Update now to get the latest features '
            'and improvements.',

        'android_store_url': '',
        'ios_store_url': '',
      },
    );
  }

  /// Compares two semantic versions.
  ///
  /// Examples:
  /// 2.0.0 > 1.0.0  -> true
  /// 1.1.0 > 1.0.0  -> true
  /// 1.0.1 > 1.0.0  -> true
  /// 1.0.0 > 1.0.0  -> false
  /// 1.0.0 > 1.1.0  -> false
  static bool isVersionGreater(
    String first,
    String second,
  ) {
    final List<int> firstParts =
        _parseVersion(first);

    final List<int> secondParts =
        _parseVersion(second);

    final int length = firstParts.length >
            secondParts.length
        ? firstParts.length
        : secondParts.length;

    for (int i = 0; i < length; i++) {
      final int firstValue =
          i < firstParts.length
              ? firstParts[i]
              : 0;

      final int secondValue =
          i < secondParts.length
              ? secondParts[i]
              : 0;

      if (firstValue > secondValue) {
        return true;
      }

      if (firstValue < secondValue) {
        return false;
      }
    }

    return false;
  }

  /// Converts a version string such as:
  ///
  /// 1.2.3
  /// 1.2.3+15
  /// 2.0
  ///
  /// into integer components.
  static List<int> _parseVersion(
    String version,
  ) {
    final String cleanVersion =
        version.trim().split('+').first;

    if (cleanVersion.isEmpty) {
      return <int>[0];
    }

    return cleanVersion
        .split('.')
        .map(
          (String part) =>
              int.tryParse(part.trim()) ?? 0,
        )
        .toList();
  }
}