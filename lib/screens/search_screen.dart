import 'package:flutter/material.dart';

import '../data/demo_songs.dart';
import '../main.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _query = _controller.text.trim().toLowerCase());
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = demoSongs.where((song) {
      if (_query.isEmpty) return true;
      return song.title.toLowerCase().contains(_query) ||
          song.artist.toLowerCase().contains(_query) ||
          song.category.toLowerCase().contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search songs, artists, moods...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _query.isEmpty ? 'All test tracks' : 'Results for “$_query”',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (songs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No matching demo tracks.')),
            )
          else
            ...songs.map(
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
            ),
        ],
      ),
    );
  }
}
