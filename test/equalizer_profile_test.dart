import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/models/equalizer_profile.dart';
import 'package:lrs_sangeet_duniya/models/song.dart';

void main() {
  final song = Song(
    id: 't', title: 'Party Dance', artist: 'Test', album: 'A',
    artworkUrl: '', streamUrl: '', category: 'Party',
  );

  test('auto EQ recommends dance for party metadata', () {
    expect(EqualizerProfile.recommendFor(song), EqualizerPreset.dance);
  });

  test('presets expose five frequency bands', () {
    for (final preset in EqualizerPreset.values) {
      expect(EqualizerProfile.forPreset(preset).gainsDb.length, 5);
    }
  });
}