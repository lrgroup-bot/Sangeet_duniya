import 'package:flutter/material.dart';

import '../main.dart';
import '../services/library_store.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: AnimatedBuilder(
        animation: libraryStore,
        builder: (context, _) {
          final songs = libraryStore.downloads;
          if (songs.isEmpty) {
            return const Center(
              child: Text('No offline songs yet. Download a permitted track from the player.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: songs
                .map(
                  (song) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SongCard(
                      song: song,
                      onTap: () async {
                        await audioHandler.playSong(song);
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PlayerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}
