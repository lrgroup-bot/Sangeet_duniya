import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _LibraryTile(
            icon: Icons.favorite_rounded,
            title: 'Favorites',
            subtitle: 'Your liked music',
          ),
          _LibraryTile(
            icon: Icons.download_rounded,
            title: 'Downloads',
            subtitle: 'Offline music will appear here in Phase 4',
          ),
          _LibraryTile(
            icon: Icons.history_rounded,
            title: 'Recently played',
            subtitle: 'Playback history will be added later',
          ),
          _LibraryTile(
            icon: Icons.queue_music_rounded,
            title: 'My playlists',
            subtitle: 'Playlist manager will be added later',
          ),
        ],
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0x22FFC857),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
