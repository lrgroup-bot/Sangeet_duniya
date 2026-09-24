import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_outfit.dart';
import '../models/song.dart';

class AvatarProfileService extends ChangeNotifier {
  static const _outfitKey = 'sangeeta_avatar_outfit';
  static const _defaultOutfitKey = 'sangeeta_avatar_default_outfit';
  static const _autoMoodKey = 'sangeeta_avatar_auto_mood';
  static const _songMapKey = 'sangeeta_avatar_song_map';

  AvatarOutfit outfit = AvatarOutfit.romantic;
  AvatarOutfit defaultOutfit = AvatarOutfit.romantic;
  bool autoMood = true;
  final Map<String, String> _songOutfitNames = <String, String>{};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedOutfit = prefs.getString(_outfitKey);
    if (savedOutfit != null) {
      outfit = _parse(savedOutfit, AvatarOutfit.romantic);
    }

    final savedDefault = prefs.getString(_defaultOutfitKey);
    if (savedDefault != null) {
      defaultOutfit = _parse(savedDefault, AvatarOutfit.romantic);
    } else {
      defaultOutfit = outfit;
    }

    autoMood = prefs.getBool(_autoMoodKey) ?? true;

    final savedMap = prefs.getStringList(_songMapKey) ?? const <String>[];
    _songOutfitNames
      ..clear()
      ..addEntries(
        savedMap.map((entry) {
          final split = entry.split('|');
          return split.length == 2
              ? MapEntry(split[0], split[1])
              : const MapEntry('', '');
        }).where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty),
      );

    notifyListeners();
  }

  AvatarOutfit _parse(String value, AvatarOutfit fallback) {
    return AvatarOutfit.values.firstWhere(
      (item) => item.name == value,
      orElse: () => fallback,
    );
  }

  AvatarOutfit outfitForSong(Song song) {
    final mapped = _songOutfitNames[song.id];
    if (mapped != null) {
      return _parse(mapped, defaultOutfit);
    }

    if (autoMood) {
      final mood = song.category.trim().toLowerCase();
      if (mood.contains('party')) return AvatarOutfit.party;
      if (mood.contains('romantic') || mood.contains('love')) {
        return AvatarOutfit.romantic;
      }
      if (mood.contains('sad') || mood.contains('melanch')) {
        return AvatarOutfit.formalSuit;
      }
      if (mood.contains('devotional') ||
          mood.contains('bhajan') ||
          mood.contains('odia')) {
        return AvatarOutfit.traditionalOdia;
      }
      if (mood.contains('dance') || mood.contains('gym')) {
        return AvatarOutfit.gymChill;
      }
    }
    return defaultOutfit;
  }

  Future<void> setOutfit(AvatarOutfit value) async {
    outfit = value;
    await _saveString(_outfitKey, value.name);
    notifyListeners();
  }

  Future<void> setDefaultOutfit(AvatarOutfit value) async {
    defaultOutfit = value;
    outfit = value;
    await _saveString(_defaultOutfitKey, value.name);
    await _saveString(_outfitKey, value.name);
    notifyListeners();
  }

  Future<void> setAutoMood(bool enabled) async {
    autoMood = enabled;
    await (await SharedPreferences.getInstance()).setBool(_autoMoodKey, enabled);
    notifyListeners();
  }

  Future<void> setSongOutfit(String songId, AvatarOutfit outfit) async {
    if (songId.trim().isEmpty) return;
    _songOutfitNames[songId] = outfit.name;
    await _persistSongMap();
    notifyListeners();
  }

  Future<void> clearSongOutfit(String songId) async {
    _songOutfitNames.remove(songId);
    await _persistSongMap();
    notifyListeners();
  }

  AvatarOutfit? savedSongOutfit(String songId) {
    final value = _songOutfitNames[songId];
    return value == null ? null : _parse(value, defaultOutfit);
  }

  Future<void> _saveString(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  Future<void> _persistSongMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _songMapKey,
      _songOutfitNames.entries
          .map((entry) => '${entry.key}|${entry.value}')
          .toList(growable: false),
    );
  }
}

final avatarProfileService = AvatarProfileService();
