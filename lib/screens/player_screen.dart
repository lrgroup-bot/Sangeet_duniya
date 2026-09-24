import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            tooltip: 'Dance Mode (Phase 3)',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sangeeta Dance Mode arrives in Phase 3.'),
              ),
            ),
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

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              children: [
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
                          color: Color(0xFFFFC857),
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
                    color: Colors.white.withValues(alpha: 0.65),
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
                        final rawMax = (duration?.inMilliseconds ?? 1).toDouble();
                        final maxSeconds = rawMax < 1 ? 1.0 : rawMax;
                        final rawValue = position.inMilliseconds.toDouble();
                        final value = rawValue.clamp(0.0, maxSeconds);
                        return Column(
                          children: [
                            Slider(
                              min: 0,
                              max: maxSeconds,
                              value: value,
                              onChanged: (newValue) => audioHandler.seek(
                                Duration(milliseconds: newValue.round()),
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
                    final processing = state?.processingState;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 38,
                          onPressed: audioHandler.skipToPrevious,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        const SizedBox(width: 20),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(22),
                          ),
                          onPressed: processing == AudioProcessingState.loading ||
                                  processing == AudioProcessingState.buffering
                              ? null
                              : playing
                                  ? audioHandler.pause
                                  : audioHandler.play,
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          iconSize: 38,
                          onPressed: audioHandler.skipToNext,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PlayerAction(
                      icon: Icons.lyrics_rounded,
                      label: 'Lyrics',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lyrics integration is planned for Phase 4.'),
                        ),
                      ),
                    ),
                    _PlayerAction(
                      icon: Icons.download_rounded,
                      label: 'Download',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Download manager is planned for Phase 4.',
                          ),
                        ),
                      ),
                    ),
                    _PlayerAction(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Dance',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dance Mode is planned for Phase 3.'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
