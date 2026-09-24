import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo_songs.dart';
import '../models/license_plan.dart';
import '../main.dart';
import '../models/song.dart';
import '../services/auth_provider.dart';
import '../services/library_store.dart';
import '../services/music_catalog_service.dart';
import '../widgets/song_card.dart';
import 'player_screen.dart';
import 'admin_dashboard_screen.dart';

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

  String _remainingText() {
    if (authProvider.isOwner) return 'OWNER • Unlimited';
    final license = authProvider.license;
    if (!authProvider.isActivated || license == null) {
      return 'Activation required';
    }
    if (license.isLifetime) return 'LIFETIME';
    final remaining = license.remaining;
    if (remaining == null || remaining.isNegative) return 'Expired';
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} • ${days.toString().padLeft(2, '0')} days left';
  }

  String _formatDateTime(DateTime value) {
    final v = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(v.day)}/${two(v.month)}/${v.year} ${two(v.hour)}:${two(v.minute)}';
  }

  Future<void> _showValidity() async {
    final license = authProvider.license;
    final expiresAt = license?.expiresAt;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final owner = authProvider.isOwner;
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFFFFC857)),
              SizedBox(width: 8),
              Text('App Access'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authProvider.userName.isEmpty ? "LR's Sangeet_Duniya" : authProvider.userName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Text('Validity: ${owner ? 'Owner' : (license?.plan.label ?? 'Not activated')}'),
              const SizedBox(height: 7),
              Text(
                'Time left: ${_remainingText()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFC857),
                ),
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: 7),
                Text('Valid until: ${_formatDateTime(expiresAt)}'),
              ],
            ],
          ),
          actions: [
            if (owner)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  );
                },
                child: const Text('Admin Console'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOwnerDialog() async {
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> unlock() async {
              final ok = await authProvider.unlockOwnerMode(controller.text);
              if (!mounted) return;
              if (!ok) {
                setDialogState(() => error = 'Incorrect owner PIN.');
                return;
              }
              Navigator.of(dialogContext).pop();
              await Navigator.of(this.context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminDashboardScreen(),
                ),
              );
            }
            return AlertDialog(
              title: const Text('Owner Access'),
              content: TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: 'Owner PIN',
                  errorText: error,
                  counterText: '',
                ),
                onSubmitted: (_) => unlock(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: unlock, child: const Text('Unlock')),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.black,
            leading: GestureDetector(
            onTap: _showValidity,
            onLongPress: _showOwnerDialog,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: SangeetaLogo(size: 42, showTagline: false),
            ),
          ),
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
              if (authProvider.isOwner)
                IconButton(
                  tooltip: 'Owner Console',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                ),
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
              child: Container(
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

}
