import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_songs.dart';
import '../models/song.dart';

class LibraryStore extends ChangeNotifier {
  static const _favoriteKey = 'favorite_song_ids';
  static const _historyKey = 'play_history_ids';
  static const _playlistNamesKey = 'playlist_names';

  SharedPreferences? _prefs;
  final Set<String> _favorites = <String>{};
  final Map<String, String> _downloads = <String, String>{};
  final List<String> _history = <String>[];
  final Map<String, Set<String>> _playlists = <String, Set<String>>{};

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    _favorites
      ..clear()
      ..addAll(_prefs!.getStringList(_favoriteKey) ?? const <String>[]);
    _history
      ..clear()
      ..addAll(_prefs!.getStringList(_historyKey) ?? const <String>[]);

    _downloads.clear();
    for (final id in demoSongs.map((song) => song.id)) {
      final path = _prefs!.getString('download_path_' + id);
      if (path != null && await File(path).exists()) {
        _downloads[id] = path;
      } else if (path != null) {
        await _prefs!.remove('download_path_' + id);
      }
    }

    final names = _prefs!.getStringList(_playlistNamesKey) ?? const <String>[];
    _playlists
      ..clear()
      ..addEntries(
        names.map(
          (name) => MapEntry(
            name,
            (_prefs!.getStringList('playlist_' + name) ?? const <String>[])
                .toSet(),
          ),
        ),
      );
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.contains(id);
  bool isDownloaded(String id) => _downloads.containsKey(id);
  String? localPathFor(String id) => _downloads[id];

  List<Song> get favorites => demoSongs
      .where((song) => _favorites.contains(song.id))
      .toList(growable: false);

  List<Song> get downloads => demoSongs
      .where((song) => _downloads.containsKey(song.id))
      .toList(growable: false);

  List<Song> get historySongs => _history
      .map(
        (id) => demoSongs.cast<Song?>().firstWhere(
          (song) => song?.id == id,
          orElse: () => null,
        ),
      )
      .whereType<Song>()
      .toList(growable: false);

  List<String> get playlistNames => _playlists.keys.toList(growable: false);

  List<Song> songsInPlaylist(String name) {
    final ids = _playlists[name] ?? const <String>{};
    return demoSongs
        .where((song) => ids.contains(song.id))
        .toList(growable: false);
  }

  Future<void> toggleFavorite(Song song) async {
    _requirePrefs();
    if (!_favorites.remove(song.id)) {
      _favorites.add(song.id);
    }
    await _prefs!.setStringList(_favoriteKey, _favorites.toList());
    notifyListeners();
  }

  Future<void> recordPlayed(Song song) async {
    _requirePrefs();
    _history
      ..remove(song.id)
      ..insert(0, song.id);
    if (_history.length > 30) {
      _history.removeRange(30, _history.length);
    }
    await _prefs!.setStringList(_historyKey, _history);
    notifyListeners();
  }

  Future<void> saveDownload(Song song, String path) async {
    _requirePrefs();
    _downloads[song.id] = path;
    await _prefs!.setString('download_path_' + song.id, path);
    notifyListeners();
  }

  Future<void> removeDownload(Song song) async {
    _requirePrefs();
    final path = _downloads.remove(song.id);
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _prefs!.remove('download_path_' + song.id);
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    _requirePrefs();
    final clean = name.trim();
    if (clean.isEmpty || _playlists.containsKey(clean)) return;
    _playlists[clean] = <String>{};
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String name) async {
    _requirePrefs();
    _playlists.remove(name);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addToPlaylist(String name, Song song) async {
    _requirePrefs();
    _playlists[name]?.add(song.id);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeFromPlaylist(String name, Song song) async {
    _requirePrefs();
    _playlists[name]?.remove(song.id);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    await _prefs!.setStringList(_playlistNamesKey, _playlists.keys.toList());
    for (final entry in _playlists.entries) {
      await _prefs!.setStringList(
        'playlist_' + entry.key,
        entry.value.toList(),
      );
    }
  }

  void _requirePrefs() {
    if (_prefs == null) {
      throw StateError('LibraryStore.load() must run before use.');
    }
  }
}

final libraryStore = LibraryStore();
