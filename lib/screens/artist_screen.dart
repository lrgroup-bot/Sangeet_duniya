import 'package:flutter/material.dart';

import '../data/demo_songs.dart';
import '../main.dart';
import '../models/song.dart';
import '../services/music_catalog_service.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class ArtistScreen extends StatefulWidget {
  const ArtistScreen({required this.artistName, super.key});

  final String artistName;

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _load();
  }

  Future<List<Song>> _load() async {
    try {
      final results =
          await musicCatalogService.search(widget.artistName, limit: 30);
      if (results.isNotEmpty) return results;
    } catch (_) {}
    return demoSongs
        .where((song) =>
            song.artist.toLowerCase().contains(widget.artistName.toLowerCase()))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artistName)),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          final songs = snapshot.data ?? const <Song>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (songs.isEmpty) {
            return Center(
              child: Text('No tracks found for ' + widget.artistName + '.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 42,
                child: Text(
                  widget.artistName.isEmpty
                      ? '?'
                      : widget.artistName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.artistName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              ...songs.map(
                (song) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SongCard(
                    song: song,
                    onTap: () async {
                      await audioHandler.playSong(song, songs: songs);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PlayerScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
