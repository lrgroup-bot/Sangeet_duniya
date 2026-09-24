import 'package:flutter/material.dart';

import '../data/demo_songs.dart';
import '../main.dart';
import '../models/song.dart';
import '../services/avatar_profile_service.dart';
import '../services/library_store.dart';
import '../services/music_catalog_service.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Song>> _trendingFuture;

  @override
  void initState() {
    super.initState();
    _trendingFuture = musicCatalogService.trending(limit: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.black,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LR's Sangeet_Duniya",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Music made personal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Open player',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlayerScreen(),
                  ),
                ),
                icon: const Icon(Icons.graphic_eq_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: ListenableBuilder(
                listenable: avatarProfileService,
                builder: (context, _) => Container(
                  height: 185,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF211607), Color(0xFF0B0906)],
                    ),
                    border: Border.all(color: Color(0x66FFC857)),
                  ),
                  child: Row(
                    children: [
                      RiveAvatarStage(
                        outfit: avatarProfileService.outfit,
                        pose: SangeetaPose.greeting,
                        size: 165,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ହାଇ ଜାନ୍…',
                              style: TextStyle(
                                color: Color(0xFFFFC857),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ମୁଁ Sangeeta। ଗୀତ ଚଳାଇବି, ଖୋଜିବି ଏବଂ Auto EQ ଚୟନ କରିଦେବି।',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Quick moods',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: const [
                  _MoodChip(label: 'Trending'),
                  _MoodChip(label: 'Bikini mood'),
                  _MoodChip(label: 'Party'),
                  _MoodChip(label: 'Odia'),
                  _MoodChip(label: 'Bhajan'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<Song>>(
              future: _trendingFuture,
              builder: (context, snapshot) {
                final songs = snapshot.data ?? demoSongs;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (songs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No trending tracks found.')),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trending Music',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...songs.take(10).map(
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
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: libraryStore,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Text(
                  libraryStore.historySongs.isEmpty
                      ? 'Your history stays on this phone.'
                      : 'Recently played: ' +
                          libraryStore.historySongs.first.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .55),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Chip(
          label: Text(label),
          side: const BorderSide(color: Color(0x44FFC857)),
          backgroundColor: const Color(0x22181818),
        ),
      );
