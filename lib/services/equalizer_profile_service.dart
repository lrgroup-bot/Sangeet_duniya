import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equalizer_profile.dart';
import '../models/song.dart';

class EqualizerProfileService extends ChangeNotifier {
  static const _modeKey = 'equalizer_mode';
  static const _presetKey = 'equalizer_preset';
  static const _manualKey = 'equalizer_manual_gains';
  EqualizerMode mode = EqualizerMode.automatic;
  EqualizerPreset preset = EqualizerPreset.balanced;
  List<double> manualGainsDb = List<double>.from(EqualizerProfile.balanced.gainsDb);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_modeKey);
    final savedPreset = prefs.getString(_presetKey);
    final savedManual = prefs.getStringList(_manualKey);
    if (savedMode != null) {
      mode = EqualizerMode.values.firstWhere(
        (v) => v.name == savedMode,
        orElse: () => EqualizerMode.automatic,
      );
    }
    if (savedPreset != null) {
      preset = EqualizerPreset.values.firstWhere(
        (v) => v.name == savedPreset,
        orElse: () => EqualizerPreset.balanced,
      );
    }
    if (savedManual != null && savedManual.length == EqualizerProfile.frequenciesHz.length) {
      manualGainsDb = savedManual.map((v) => double.tryParse(v) ?? 0).toList();
    }
    notifyListeners();
  }
  EqualizerProfile profileFor(Song song) => mode == EqualizerMode.automatic
      ? EqualizerProfile.forPreset(EqualizerProfile.recommendFor(song))
      : EqualizerProfile(preset: preset, gainsDb: List<double>.from(manualGainsDb));
  String recommendationFor(Song song) => EqualizerProfile.recommendFor(song).label;
  Future<void> setMode(EqualizerMode value) async {
    mode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, value.name);
    notifyListeners();
  }
  Future<void> setPreset(EqualizerPreset value) async {
    preset = value;
    manualGainsDb = List<double>.from(EqualizerProfile.forPreset(value).gainsDb);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, value.name);
    await prefs.setStringList(_manualKey, manualGainsDb.map((v) => v.toString()).toList());
    notifyListeners();
  }
  Future<void> setManualGain(int index, double value) async {
    if (index < 0 || index >= manualGainsDb.length) return;
    manualGainsDb[index] = value.clamp(-10, 10).toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_manualKey, manualGainsDb.map((v) => v.toString()).toList());
    notifyListeners();
  }
}
final equalizerProfileService = EqualizerProfileService();