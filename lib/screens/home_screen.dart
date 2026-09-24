import 'package:flutter/material.dart';

import '../data/demo_songs.dart';
import '../main.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2B2110), Color(0xFF151515)],
                  ),
                  border: Border.all(color: const Color(0x55FFC857)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sangeeta',
                            style: TextStyle(
                              color: Color(0xFFFFC857),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your music companion is coming.',
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Phase 1 foundation is ready for playback testing.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 72,
                      color: Color(0xFFFFC857),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Quick moods',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
                  _MoodChip(label: 'Romantic'),
                  _MoodChip(label: 'Party'),
                  _MoodChip(label: 'Odia'),
                  _MoodChip(label: 'Bhajan'),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Phase 1 test tracks',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: demoSongs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final song = demoSongs[index];
                return SongCard(
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
                );
              },
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Chip(
        label: Text(label),
        side: const BorderSide(color: Color(0x44FFC857)),
        backgroundColor: const Color(0x22181818),
      ),
    );
  }
}
