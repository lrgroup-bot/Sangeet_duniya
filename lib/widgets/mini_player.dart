import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        return Material(
          color: const Color(0xFF15130F),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.artUri?.toString() ?? '',
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 46,
                        height: 46,
                        color: const Color(0x222A200D),
                        child: const Icon(Icons.music_note_rounded, color: AppTheme.gold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(item.artist ?? 'Unknown artist', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous',
                    onPressed: audioHandler.skipToPrevious,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, state) {
                      final playing = state.data?.playing ?? false;
                      return IconButton(
                        tooltip: playing ? 'Pause' : 'Play',
                        onPressed: playing ? audioHandler.pause : audioHandler.play,
                        icon: Icon(
                          playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: AppTheme.gold,
                          size: 34,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Next',
                    onPressed: audioHandler.skipToNext,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
