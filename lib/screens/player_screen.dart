import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../data/demo_songs.dart';
import '../main.dart';
import '../models/song.dart';
import '../services/download_service.dart';
import '../services/library_store.dart';
import '../theme/app_theme.dart';
import '../widgets/dancing_sangeeta.dart';
import 'dance_mode_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              final item = snapshot.data;
              if (item == null) return const SizedBox.shrink();
              return AnimatedBuilder(
                animation: libraryStore,
                builder: (context, _) {
                  final liked = libraryStore.isFavorite(item.id);
                  return IconButton(
                    tooltip: liked ? 'Remove favorite' : 'Favorite',
                    onPressed: () async {
                      final song = _songFor(item.id);
                      if (song != null) await libraryStore.toggleFavorite(song);
                    },
                    icon: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: liked ? AppTheme.gold : null,
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Dance Mode',
            onPressed: () {
              final item = audioHandler.mediaItem.value;
              final category = item?.extras?['category']?.toString() ?? 'Party';
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DanceModeScreen(category: category),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            final item = snapshot.data;
            if (item == null) {
              return const Center(
                child: Text('Choose a song from Home or Search.'),
              );
            }

            final category = item.extras?['category']?.toString() ?? 'Trending';
            final showDancer = category == 'Party' || category == 'Romantic';

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              children: [
                if (showDancer) ...[
                  DancingSangeeta(category: category, compact: true),
                  const SizedBox(height: 14),
                ],
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      item.artUri?.toString() ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF17130A),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 110,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.artist ?? 'Unknown artist',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<Duration>(
                  stream: audioHandler.positionStream,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration?>(
                      stream: audioHandler.durationStream,
                      builder: (context, durationSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = durationSnapshot.data ?? item.duration;
                        final max = (duration?.inMilliseconds ?? 1).toDouble().clamp(1.0, double.infinity);
                        final current = position.inMilliseconds.toDouble().clamp(0.0, max);
                        return Column(
                          children: [
                            Slider(
                              min: 0,
                              max: max,
                              value: current,
                              onChanged: (value) => audioHandler.seek(
                                Duration(milliseconds: value.round()),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_format(position)),
                                Text(_format(duration ?? Duration.zero)),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final playing = state?.playing ?? false;
                    final loading = state?.processingState == AudioProcessingState.loading ||
                        state?.processingState == AudioProcessingState.buffering;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 40,
                          onPressed: audioHandler.skipToPrevious,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        const SizedBox(width: 18),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: AppTheme.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.all(22),
                          ),
                          onPressed: loading
                              ? null
                              : playing
                                  ? audioHandler.pause
                                  : audioHandler.play,
                          child: Icon(
                            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          iconSize: 40,
                          onPressed: audioHandler.skipToNext,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                StreamBuilder<MediaItem?>(
                  stream: audioHandler.mediaItem,
                  builder: (context, itemSnapshot) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PlayerAction(
                          icon: Icons.lyrics_rounded,
                          label: 'Lyrics',
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(item.title),
                              content: const Text(
                                'Lyrics provider will be connected in the music-source phase. '
                                'This Phase 4 build keeps the player free and local-first.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _PlayerAction(
                          icon: libraryStore.isDownloaded(item.id)
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                          label: libraryStore.isDownloaded(item.id)
                              ? 'Offline'
                              : 'Download',
                          onTap: () => _download(context, item),
                        ),
                        _PlayerAction(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Dance',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DanceModeScreen(category: category),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, MediaItem item) async {
    final song = _songFor(item.id);
    if (song == null) return;

    if (libraryStore.isDownloaded(song.id)) {
      await libraryStore.removeDownload(song);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline copy removed.')),
        );
      }
      return;
    }

    try {
      await DownloadService.instance.download(song);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved for offline playback.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $error')),
        );
      }
    }
  }

  Song? _songFor(String id) {
    for (final song in demoSongs) {
      if (song.id == id) return song;
    }
    return null;
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return minutes + ':' + seconds;
  }
}

class _PlayerAction extends StatelessWidget {
  const _PlayerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
