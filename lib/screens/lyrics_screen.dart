import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({required this.song, super.key});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lyrics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              song.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              song.artist,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.gold2),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  song.lyrics.isEmpty
                      ? 'Lyrics are not available for this track yet.'
                      : song.lyrics,
                  style: const TextStyle(fontSize: 17, height: 1.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
