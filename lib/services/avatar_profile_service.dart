import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_outfit.dart';

class AvatarProfileService extends ChangeNotifier {
  static const _outfitKey = 'sangeeta_avatar_outfit';
  static const _riveUrlKey = 'sangeeta_rive_url';
  static const _riveStateMachineKey = 'sangeeta_rive_state_machine';

  AvatarOutfit outfit = AvatarOutfit.casual;
  String riveUrl = '';
  String riveStateMachine = '';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOutfit = prefs.getString(_outfitKey);
    if (savedOutfit != null) {
      outfit = AvatarOutfit.values.firstWhere(
        (value) => value.name == savedOutfit,
        orElse: () => AvatarOutfit.casual,
      );
    }
    riveUrl = prefs.getString(_riveUrlKey) ?? '';
    riveStateMachine = prefs.getString(_riveStateMachineKey) ?? '';
    notifyListeners();
  }

  Future<void> setOutfit(AvatarOutfit value) async {
    outfit = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outfitKey, value.name);
    notifyListeners();
  }

  Future<void> setRiveSource({
    required String url,
    required String stateMachine,
  }) async {
    riveUrl = url.trim();
    riveStateMachine = stateMachine.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_riveUrlKey, riveUrl);
    await prefs.setString(_riveStateMachineKey, riveStateMachine);
    notifyListeners();
  }

  Future<void> clearRiveSource() async {
    riveUrl = '';
    riveStateMachine = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_riveUrlKey);
    await prefs.remove(_riveStateMachineKey);
    notifyListeners();
  }
}

final avatarProfileService = AvatarProfileService();
