import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lrs_sangeet_duniya/data/demo_songs.dart';
import 'package:lrs_sangeet_duniya/services/library_store.dart';

void main() {
  test('favorites and playlists persist in the local store', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final store = LibraryStore();
    await store.load();

    expect(store.favorites, isEmpty);
    await store.toggleFavorite(demoSongs.first);
    expect(store.isFavorite(demoSongs.first.id), isTrue);

    await store.createPlaylist('Road Trip');
    await store.addToPlaylist('Road Trip', demoSongs.first);

    expect(store.playlistNames, contains('Road Trip'));
    expect(
      store.songsInPlaylist('Road Trip').map((song) => song.id),
      contains(demoSongs.first.id),
    );

    await store.recordPlayed(demoSongs.first);
    expect(store.historySongs.first.id, demoSongs.first.id);
  });
}
