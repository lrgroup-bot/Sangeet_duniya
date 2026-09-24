import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DistributionService extends ChangeNotifier {
  static const _urlKey = 'distribution_url';

  String downloadUrl =
      'https://github.com/lrgroup-bot/Sangeet_duniya/releases/latest';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    downloadUrl = prefs.getString(_urlKey) ?? downloadUrl;
    notifyListeners();
  }

  Future<void> setDownloadUrl(String value) async {
    final clean = value.trim();
    if (clean.isEmpty) return;
    downloadUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, clean);
    notifyListeners();
  }
}

final distributionService = DistributionService();
