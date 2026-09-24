import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DistributionPlatform {
  android,
  ios,
  both,
}

extension DistributionPlatformLabel on DistributionPlatform {
  String get label => switch (this) {
        DistributionPlatform.android => 'Android',
        DistributionPlatform.ios => 'iOS',
        DistributionPlatform.both => 'Both',
      };
}

class DistributionService extends ChangeNotifier {
  static const _androidUrlKey = 'distribution_android_url';
  static const _iosUrlKey = 'distribution_ios_url';

  String androidUrl =
      'https://github.com/lrgroup-bot/Sangeet_duniya/releases/latest';
  String iosUrl =
      'https://github.com/lrgroup-bot/Sangeet_duniya/releases/latest';

  String get downloadUrl => androidUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    androidUrl = prefs.getString(_androidUrlKey) ?? androidUrl;
    iosUrl = prefs.getString(_iosUrlKey) ?? iosUrl;
    notifyListeners();
  }

  String urlFor(DistributionPlatform platform) => switch (platform) {
        DistributionPlatform.android => androidUrl,
        DistributionPlatform.ios => iosUrl,
        DistributionPlatform.both => androidUrl,
      };

  Future<void> setAndroidUrl(String value) async {
    final clean = value.trim();
    if (clean.isEmpty) return;
    androidUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_androidUrlKey, clean);
    notifyListeners();
  }

  Future<void> setIosUrl(String value) async {
    final clean = value.trim();
    if (clean.isEmpty) return;
    iosUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_iosUrlKey, clean);
    notifyListeners();
  }

  Future<void> setDownloadUrl(String value) => setAndroidUrl(value);
}

final distributionService = DistributionService();