import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicCatalogService {
  MusicCatalogService._();
  static final instance = MusicCatalogService._();
  static const _apiBase = 'https://api.audius.co/v1';
  static const _appName = 'LRsSangeetDuniya';

  Future<List<Song>> search(String query, {int limit = 25}) async {
    final clean = query.trim();
    if (clean.isEmpty) return trending(limit: limit);
    final uri = Uri.parse(_apiBase + '/tracks/search').replace(
      queryParameters: <String, String>{
        'query': clean, 'limit': limit.toString(), 'app_name': _appName,
      },
    );
    return _getTracks(uri);
  }

  Future<List<Song>> trending({int limit = 20}) async {
    final uri = Uri.parse(_apiBase + '/tracks/trending').replace(
      queryParameters: <String, String>{
        'limit': limit.toString(), 'app_name': _appName,
      },
    );
    return _getTracks(uri);
  }

  Future<List<Song>> _getTracks(Uri uri) async {
    final response = await http.get(uri, headers: const <String, String>{
      'accept': 'application/json',
    }).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Music source returned HTTP ' + response.statusCode.toString() + '.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid music-source response.');
    }
    final raw = decoded['data'];
    if (raw is! List) return const <Song>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_toSong)
        .whereType<Song>()
        .toList(growable: false);
  }

  Song? _toSong(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    if (id == null || id.isEmpty || title == null || title.isEmpty) return null;
    final user = json['user'];
    final artist = user is Map<String, dynamic>
        ? (user['name']?.toString() ?? 'Unknown artist')
        : 'Unknown artist';
    final artwork = json['artwork'];
    var artworkUrl = '';
    if (artwork is Map<String, dynamic>) {
      artworkUrl = artwork['_480x480']?.toString() ??
          artwork['_1000x1000']?.toString() ??
          artwork['_150x150']?.toString() ?? '';
    }
    final genre = json['genre']?.toString() ?? 'Trending';
    final permalink = json['permalink']?.toString() ?? '';
    final downloadable = json['downloadable'] == true;
    final streamUrl = _apiBase + '/tracks/' + Uri.encodeComponent(id) +
        '/stream?app_name=' + _appName;
    return Song(
      id: 'audius-' + id,
      title: title,
      artist: artist,
      album: 'Audius',
      artworkUrl: artworkUrl,
      streamUrl: streamUrl,
      category: genre,
      source: 'Audius',
      sourcePageUrl: permalink,
      qualityLabel: 'Provider stream quality',
      isDownloadable: downloadable,
    );
  }
}

final musicCatalogService = MusicCatalogService.instance;