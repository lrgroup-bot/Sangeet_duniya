import '../models/song.dart';

enum EqualizerMode { automatic, manual }
enum EqualizerPreset { balanced, bassBoost, vocalClarity, dance, rock, acoustic, classical }

class EqualizerProfile {
  const EqualizerProfile({required this.preset, required this.gainsDb});
  final EqualizerPreset preset;
  final List<double> gainsDb;
  static const frequenciesHz = <double>[60, 230, 910, 3600, 14000];
  static const balanced = EqualizerProfile(
    preset: EqualizerPreset.balanced, gainsDb: <double>[0, 0, 0, 0, 0],
  );
  static const presets = <EqualizerPreset, List<double>>{
    EqualizerPreset.balanced: <double>[0, 0, 0, 0, 0],
    EqualizerPreset.bassBoost: <double>[5, 3, 1, 0, 2],
    EqualizerPreset.vocalClarity: <double>[0, -1, 3, 4, 2],
    EqualizerPreset.dance: <double>[5, 3, 0, 2, 4],
    EqualizerPreset.rock: <double>[4, 2, -1, 3, 4],
    EqualizerPreset.acoustic: <double>[2, 1, 2, 3, 3],
    EqualizerPreset.classical: <double>[2, 1, 0, 2, 3],
  };
  static EqualizerPreset recommendFor(Song song) {
    final text = (song.title + ' ' + song.artist + ' ' + song.category).toLowerCase();
    if (text.contains('dance') || text.contains('edm') || text.contains('electro') || text.contains('party') || text.contains('house')) return EqualizerPreset.dance;
    if (text.contains('rock') || text.contains('metal')) return EqualizerPreset.rock;
    if (text.contains('vocal') || text.contains('voice') || text.contains('podcast') || text.contains('devotional') || text.contains('bhajan')) return EqualizerPreset.vocalClarity;
    if (text.contains('classical') || text.contains('orchestra')) return EqualizerPreset.classical;
    if (text.contains('acoustic') || text.contains('folk')) return EqualizerPreset.acoustic;
    if (text.contains('romantic') || text.contains('bass')) return EqualizerPreset.bassBoost;
    return EqualizerPreset.balanced;
  }
  static EqualizerProfile forPreset(EqualizerPreset preset) => EqualizerProfile(
    preset: preset,
    gainsDb: List<double>.from(presets[preset] ?? presets[EqualizerPreset.balanced]!),
  );
}

extension EqualizerPresetLabel on EqualizerPreset {
  String get label => switch (this) {
    EqualizerPreset.balanced => 'Balanced',
    EqualizerPreset.bassBoost => 'Bass Boost',
    EqualizerPreset.vocalClarity => 'Vocal Clarity',
    EqualizerPreset.dance => 'Dance',
    EqualizerPreset.rock => 'Rock',
    EqualizerPreset.acoustic => 'Acoustic',
    EqualizerPreset.classical => 'Classical',
  };
}