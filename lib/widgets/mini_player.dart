import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/avatar_profile_service.dart';
import '../screens/player_screen.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';

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
          color: const Color(0xFF151515),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PlayerScreen(),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ListenableBuilder(
                        listenable: avatarProfileService,
                        builder: (context, _) => RiveAvatarStage(
                          outfit: avatarProfileService.outfit,
                          pose: (audioHandler.playbackState.value.playing)
                              ? SangeetaPose.dance
                              : SangeetaPose.sit,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.artUri?.toString() ?? '',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 46,
                          height: 46,
                          color: const Color(0x22FFC857),
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item.artist ?? 'Unknown artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, state) {
                        final playing = state.data?.playing ?? false;
                        return IconButton(
                          tooltip: playing ? 'Pause' : 'Play',
                          onPressed: playing
                              ? audioHandler.pause
                              : audioHandler.play,
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 34,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
