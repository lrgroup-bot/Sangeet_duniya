import 'package:flutter/material.dart';
import '../data/demo_songs.dart';
import '../main.dart';
import '../models/song.dart';
import '../services/music_catalog_service.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Song> _songs = const <Song>[];
  bool _loading = false;
  String? _error;

  @override void initState() { super.initState(); _search(''); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _search(String query) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await musicCatalogService.search(query, limit: 30);
      if (!mounted) return;
      setState(() { _songs = results; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _songs = demoSongs; _loading = false; _error = 'Internet music source is unavailable. Showing local test tracks.'; });
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Music')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: 'Search songs, artists, moods...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () => _search(_controller.text),
                icon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          const SizedBox(height: 10),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (!_loading && _songs.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No songs found.'))),
          if (!_loading) ..._songs.map((song) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SongCard(
              song: song,
              onTap: () async {
                await audioHandler.playSong(song, queue: _songs);
                if (!context.mounted) return;
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlayerScreen()));
              },
            ),
          )),
          const SizedBox(height: 12),
          Text(
            'Ad-free LR\'s Sangeet_Duniya interface • content availability follows the source.',
            style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}