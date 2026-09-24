import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/models/song.dart';

void main() {
  test('song metadata round trips locally', () {
    const original = Song(
      id: 'audius-1',
      title: 'Demo',
      artist: 'Artist',
      album: 'Album',
      artworkUrl: 'https://example.com/a.jpg',
      streamUrl: 'https://example.com/a.mp3',
      category: 'Dance',
      source: 'Audius',
      qualityLabel: 'Provider stream quality',
      sourcePageUrl: 'https://example.com/track',
      isDownloadable: true,
    );

    final decoded = Song.fromJson(original.toJson());
    expect(decoded.id, original.id);
    expect(decoded.source, 'Audius');
    expect(decoded.isDownloadable, isTrue);
    expect(decoded.streamUrl, original.streamUrl);
  });
}
