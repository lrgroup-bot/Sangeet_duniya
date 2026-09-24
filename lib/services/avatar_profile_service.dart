import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_outfit.dart';

class AvatarProfileService extends ChangeNotifier {
  static const _outfitKey = 'sangeeta_avatar_outfit';

  AvatarOutfit outfit = AvatarOutfit.casual;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOutfit = prefs.getString(_outfitKey);
    if (savedOutfit != null) {
      outfit = AvatarOutfit.values.firstWhere(
        (value) => value.name == savedOutfit,
        orElse: () => AvatarOutfit.casual,
      );
    }
    notifyListeners();
  }

  Future<void> setOutfit(AvatarOutfit value) async {
    outfit = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outfitKey, value.name);
    notifyListeners();
  }
}

final avatarProfileService = AvatarProfileService();
