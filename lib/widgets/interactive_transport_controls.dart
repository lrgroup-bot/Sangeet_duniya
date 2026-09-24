import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';

class InteractiveTransportControls extends StatelessWidget {
  const InteractiveTransportControls({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final shuffle = state?.shuffleMode == AudioServiceShuffleMode.all;
        final repeat = state?.repeatMode ?? AudioServiceRepeatMode.none;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
                  onPressed: () => audioHandler.setShuffleMode(
                    shuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
                  ),
                  icon: Icon(Icons.shuffle_rounded, color: shuffle ? AppTheme.gold : Colors.white54),
                ),
                IconButton(
                  tooltip: 'Previous',
                  onPressed: audioHandler.skipToPrevious,
                  icon: const Icon(Icons.skip_previous_rounded, size: 36),
                ),
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFEAA2), Color(0xFFFFC857), Color(0xFFB56C08)],
                    ),
                  ),
                  child: IconButton(
                    onPressed: playing ? audioHandler.pause : audioHandler.play,
                    icon: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 44,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next',
                  onPressed: audioHandler.skipToNext,
                  icon: const Icon(Icons.skip_next_rounded, size: 36),
                ),
                IconButton(
                  tooltip: repeat == AudioServiceRepeatMode.one
                      ? 'Repeat one'
                      : repeat == AudioServiceRepeatMode.all
                          ? 'Repeat all'
                          : 'Repeat off',
                  onPressed: () {
                    final next = repeat == AudioServiceRepeatMode.none
                        ? AudioServiceRepeatMode.all
                        : repeat == AudioServiceRepeatMode.all
                            ? AudioServiceRepeatMode.one
                            : AudioServiceRepeatMode.none;
                    audioHandler.setRepeatMode(next);
                  },
                  icon: Icon(
                    repeat == AudioServiceRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: repeat == AudioServiceRepeatMode.none ? Colors.white54 : AppTheme.gold,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
