import 'package:flutter/material.dart';

import '../models/song.dart';

class SongCard extends StatelessWidget {
  const SongCard({
    required this.song,
    required this.onTap,
    super.key,
  });

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  song.artworkUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackArt(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, size: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackArt() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0x22FFC857),
      alignment: Alignment.center,
      child: const Icon(Icons.music_note_rounded),
    );
  }
}
