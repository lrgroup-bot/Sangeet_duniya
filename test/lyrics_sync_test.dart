import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/services/lyrics_sync.dart';

void main() {
  test('parses LRC timestamps and returns active line', () {
    final lines = LyricsSync.parse(
      '[00:01.00]First\n[00:05.50]Second\n[00:10.00]Third',
    );
    expect(lines.length, 3);
    expect(
      LyricsSync.lineAt(lines, const Duration(seconds: 6))?.text,
      'Second',
    );
  });

  test('plain lyrics do not pretend to be synchronized', () {
    expect(LyricsSync.parse('hello\nworld'), isEmpty);
  });
}
