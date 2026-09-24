import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/data/demo_songs.dart';

void main() {
  test('demo catalog contains Phase 1 test tracks', () {
    expect(demoSongs, isNotEmpty);
    expect(demoSongs.length, greaterThanOrEqualTo(4));
    expect(demoSongs.first.title, 'Golden Horizon');
  });
}
