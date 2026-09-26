import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_outfit.dart';
import '../models/wardrobe_profile.dart';

class AvatarProfileService extends ChangeNotifier {
  static const _outfitKey = 'sangeeta_avatar_outfit';
  static const _categoryKey = 'sangeeta_wardrobe_category_v2';
  static const _hairKey = 'sangeeta_wardrobe_hair_v2';
  static const _earringsKey = 'sangeeta_wardrobe_earrings_v2';
  static const _shoesKey = 'sangeeta_wardrobe_shoes_v2';
  static const _accessoryKey = 'sangeeta_wardrobe_accessory_v2';
  static const _autoMoodKey = 'sangeeta_wardrobe_auto_mood_v2';
  static const _favoritesKey = 'sangeeta_wardrobe_favorites_v2';

  AvatarOutfit outfit = AvatarOutfit.gymChill;
  WardrobeCategory category = WardrobeCategory.gymWear;
  Hairstyle hairstyle = Hairstyle.longWave;
  EarringStyle earrings = EarringStyle.studs;
  ShoeStyle shoes = ShoeStyle.sneakers;
  AccessoryStyle accessory = AccessoryStyle.none;
  bool autoMood = true;
  final Set<WardrobeCategory> _favorites = <WardrobeCategory>{};

  Set<WardrobeCategory> get favorites => Set.unmodifiable(_favorites);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCategory = prefs.getString(_categoryKey);
    if (savedCategory != null) {
      category = WardrobeCategory.values.firstWhere(
        (value) => value.name == savedCategory,
        orElse: () => WardrobeCategory.gymWear,
      );
    } else {
      final oldOutfit = prefs.getString(_outfitKey);
      if (oldOutfit != null) {
        final legacy = AvatarOutfit.values.firstWhere(
          (value) => value.name == oldOutfit,
          orElse: () => AvatarOutfit.gymChill,
        );
        category = _categoryForOutfit(legacy);
      }
    }

    outfit = category.rendererOutfit;
    hairstyle = _enumValue(
      Hairstyle.values,
      prefs.getString(_hairKey),
      Hairstyle.longWave,
    );
    earrings = _enumValue(
      EarringStyle.values,
      prefs.getString(_earringsKey),
      EarringStyle.studs,
    );
    shoes = _enumValue(
      ShoeStyle.values,
      prefs.getString(_shoesKey),
      ShoeStyle.sneakers,
    );
    accessory = _enumValue(
      AccessoryStyle.values,
      prefs.getString(_accessoryKey),
      AccessoryStyle.none,
    );
    autoMood = prefs.getBool(_autoMoodKey) ?? true;

    _favorites
      ..clear()
      ..addAll(
        (prefs.getStringList(_favoritesKey) ?? const <String>[])
            .map(
              (name) => WardrobeCategory.values.where(
                (value) => value.name == name,
              ),
            )
            .where((matches) => matches.isNotEmpty)
            .map((matches) => matches.first),
      );

    notifyListeners();
  }

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  WardrobeCategory _categoryForOutfit(AvatarOutfit value) => switch (value) {
        AvatarOutfit.casual => WardrobeCategory.casual,
        AvatarOutfit.party => WardrobeCategory.party,
        AvatarOutfit.romantic => WardrobeCategory.romantic,
        AvatarOutfit.traditionalOdia => WardrobeCategory.traditionalOdia,
        AvatarOutfit.gymChill => WardrobeCategory.gymWear,
        AvatarOutfit.resortSwimwear => WardrobeCategory.beachResort,
        AvatarOutfit.nightSatin => WardrobeCategory.nightWear,
      };

  Future<void> setCategory(WardrobeCategory value) async {
    category = value;
    outfit = value.rendererOutfit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryKey, value.name);
    await prefs.setString(_outfitKey, outfit.name);
    notifyListeners();
  }

  Future<void> setOutfit(AvatarOutfit value) =>
      setCategory(_categoryForOutfit(value));

  Future<void> setHairstyle(Hairstyle value) async {
    hairstyle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hairKey, value.name);
    notifyListeners();
  }

  Future<void> setEarrings(EarringStyle value) async {
    earrings = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_earringsKey, value.name);
    notifyListeners();
  }

  Future<void> setShoes(ShoeStyle value) async {
    shoes = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shoesKey, value.name);
    notifyListeners();
  }

  Future<void> setAccessory(AccessoryStyle value) async {
    accessory = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessoryKey, value.name);
    notifyListeners();
  }

  Future<void> setAutoMood(bool value) async {
    autoMood = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoMoodKey, value);
    notifyListeners();
  }

  Future<void> toggleFavorite(WardrobeCategory value) async {
    if (!_favorites.remove(value)) _favorites.add(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      _favorites.map((item) => item.name).toList(growable: false),
    );
    notifyListeners();
  }

  Future<void> applyMood(String mood) async {
    if (!autoMood) return;
    final value = mood.toLowerCase();
    final target = value.contains('romantic') || value.contains('love')
        ? WardrobeCategory.romantic
        : value.contains('dj') || value.contains('dance') || value.contains('party')
            ? WardrobeCategory.djStage
            : value.contains('festival') || value.contains('devotional')
                ? WardrobeCategory.festival
                : value.contains('winter') || value.contains('chill')
                    ? WardrobeCategory.winter
                    : value.contains('beach') || value.contains('summer')
                        ? WardrobeCategory.beachResort
                        : value.contains('gym') || value.contains('workout')
                            ? WardrobeCategory.gymWear
                            : value.contains('odia') || value.contains('traditional')
                                ? WardrobeCategory.traditionalOdia
                                : WardrobeCategory.casual;
    if (target != category) await setCategory(target);
  }
}

final avatarProfileService = AvatarProfileService();
