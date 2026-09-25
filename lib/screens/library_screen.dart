import 'package:flutter/material.dart';

import '../main.dart';
import '../models/song.dart';
import '../services/library_store.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({this.initialSection = 0, super.key});

  final int initialSection;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late int _section;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.clamp(0, 3).toInt();
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await libraryStore.createPlaylist(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'New playlist',
            onPressed: _createPlaylist,
            icon: const Icon(Icons.playlist_add_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: libraryStore,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(label: 'Favorites', selected: _section == 0, onTap: () => setState(() => _section = 0)),
                  _Chip(label: 'Downloads', selected: _section == 1, onTap: () => setState(() => _section = 1)),
                  _Chip(label: 'History', selected: _section == 2, onTap: () => setState(() => _section = 2)),
                  _Chip(label: 'Playlists', selected: _section == 3, onTap: () => setState(() => _section = 3)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            switch (_section) {
              0 => _songs(title: 'Favorite songs', songs: libraryStore.favorites),
              1 => _songs(title: 'Offline songs', songs: libraryStore.downloads),
              2 => _songs(title: 'Recently played', songs: libraryStore.historySongs),
              _ => _playlists(),
            },
          ],
        ),
      ),
    );
  }

  Widget _songs({required String title, required List<Song> songs}) {
    if (songs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.library_music_outlined, size: 46),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Nothing here yet. Use a song action to save it.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...songs.map(
          (song) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SongCard(
              song: song,
              onTap: () async {
                await audioHandler.playSong(song);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _playlists() {
    if (libraryStore.playlistNames.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.queue_music_rounded, size: 46),
              const SizedBox(height: 12),
              const Text('No playlists yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Create one, then add songs from a song card menu.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _createPlaylist,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Create playlist'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: libraryStore.playlistNames.map((name) {
        final count = libraryStore.songsInPlaylist(name).length;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.queue_music_rounded)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(count.toString() + ' songs'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlaylistDetailScreen(name: name),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Delete playlist',
              onPressed: () => libraryStore.deletePlaylist(name),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({required this.name, super.key});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: AnimatedBuilder(
        animation: libraryStore,
        builder: (context, _) {
          final songs = libraryStore.songsInPlaylist(name);
          if (songs.isEmpty) return const Center(child: Text('This playlist is empty.'));
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SongCard(
                  song: song,
                  onTap: () async {
                    await audioHandler.playSong(song);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}
