import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/song.dart';
import '../services/audio_cleanup_service.dart';
import '../services/avatar_profile_service.dart';
import '../services/download_service.dart';
import '../services/equalizer_profile_service.dart';
import '../services/library_store.dart';
import '../services/lyrics_sync.dart';
import '../services/sleep_timer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_transport_controls.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import 'dance_mode_screen.dart';
import 'equalizer_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            tooltip: 'Queue',
            onPressed: () => _showQueue(context),
            icon: const Icon(Icons.queue_music_rounded),
          ),
          IconButton(
            tooltip: 'Equalizer',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EqualizerScreen()),
            ),
            icon: const Icon(Icons.equalizer_rounded),
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
            final song = libraryStore.songById(item.id);

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              children: [
                ListenableBuilder(
                  listenable: avatarProfileService,
                  builder: (context, _) => StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, stateSnapshot) => Container(
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF211607), Color(0xFF0B0906)],
                        ),
                        border: Border.all(color: const Color(0x55FFC857)),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: RiveAvatarStage(
                        outfit: avatarProfileService.outfit,
                        pose: (stateSnapshot.data?.playing ?? false)
                            ? SangeetaPose.dance
                            : SangeetaPose.sit,
                        size: 150,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      item.artUri?.toString() ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
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
                const SizedBox(height: 24),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
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
                const SizedBox(height: 18),
                StreamBuilder<Duration>(
                  stream: audioHandler.positionStream,
                  builder: (context, positionSnapshot) => StreamBuilder<Duration?>(
                    stream: audioHandler.durationStream,
                    builder: (context, durationSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final duration = durationSnapshot.data ?? item.duration;
                      final max = ((duration?.inMilliseconds ?? 1).toDouble())
                          .clamp(1.0, double.infinity)
                          .toDouble();
                      final current = position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, max)
                          .toDouble();
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
                  ),
                ),
                const SizedBox(height: 12),
                const InteractiveTransportControls(),
                const SizedBox(height: 18),
                _LyricsPanel(song: song),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PlayerAction(
                      icon: libraryStore.isDownloaded(item.id)
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                      label: libraryStore.isDownloaded(item.id)
                          ? 'Offline'
                          : (song?.isDownloadable == false
                              ? 'Stream only'
                              : 'Download'),
                      onTap: () => _download(context, song),
                    ),
                    _PlayerAction(
                      icon: Icons.bedtime_rounded,
                      label: 'Sleep',
                      onTap: () => _showSleepTimer(context),
                    ),
                    _PlayerAction(
                      icon: Icons.auto_fix_high_rounded,
                      label: 'Clean Audio',
                      onTap: () => _clean(context, song),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: audioHandler.queueSongs.length,
          itemBuilder: (context, index) {
            final song = audioHandler.queueSongs[index];
            return ListTile(
              leading: Icon(
                index == audioHandler.currentIndex
                    ? Icons.graphic_eq_rounded
                    : Icons.music_note_rounded,
                color: index == audioHandler.currentIndex
                    ? AppTheme.gold
                    : null,
              ),
              title: Text(song.title),
              subtitle: Text(song.artist),
              onTap: () {
                Navigator.pop(context);
                audioHandler.playQueueIndex(index);
              },
            );
          },
        ),
      ),
    );
  }

  void _showSleepTimer(BuildContext context) {
    const values = <int>[15, 30, 45, 60, 90];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: AnimatedBuilder(
          animation: sleepTimerService,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.bedtime_rounded, color: AppTheme.gold),
                  title: const Text('Sleep Timer'),
                  subtitle: Text(
                    sleepTimerService.isActive
                        ? 'Pauses in ' + sleepTimerService.remainingLabel
                        : 'Timer is off',
                  ),
                  trailing: sleepTimerService.isActive
                      ? TextButton(
                          onPressed: sleepTimerService.cancel,
                          child: const Text('Cancel'),
                        )
                      : null,
                ),
                Wrap(
                  spacing: 8,
                  children: values
                      .map(
                        (minutes) => ActionChip(
                          label: Text(minutes.toString() + ' min'),
                          onPressed: () {
                            sleepTimerService.start(
                              Duration(minutes: minutes),
                              onElapsed: audioHandler.pause,
                            );
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, Song? song) async {
    if (song == null) return;
    if (!song.isDownloadable && !libraryStore.isDownloaded(song.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This source does not allow downloads.')),
      );
      return;
    }
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
          SnackBar(content: Text('Download failed: ' + error.toString())),
        );
      }
    }
  }

  Future<void> _clean(BuildContext context, Song? song) async {
    if (song == null || !libraryStore.isDownloaded(song.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download the track before Clean Audio.')),
      );
      return;
    }
    try {
      final profile = equalizerProfileService.profileFor(song);
      await audioCleanupService.cleanDownloaded(song, profile: profile);
      await audioHandler.playSong(song);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local cleaned FLAC created.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clean Audio failed: ' + error.toString())),
        );
      }
    }
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return minutes + ':' + seconds;
  }
}

class _LyricsPanel extends StatelessWidget {
  const _LyricsPanel({required this.song});
  final Song? song;

  @override
  Widget build(BuildContext context) {
    final raw = song?.lyrics ?? '';
    if (raw.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Lyrics are not available for this track yet.'),
        ),
      );
    }

    final synced = LyricsSync.parse(raw);
    if (synced.isEmpty) {
      return Card(
        child: ExpansionTile(
          leading: const Icon(Icons.lyrics_rounded, color: AppTheme.gold),
          title: const Text('Lyrics'),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: [SelectableText(raw)],
        ),
      );
    }

    return StreamBuilder<Duration>(
      stream: audioHandler.positionStream,
      builder: (context, snapshot) {
        final line = LyricsSync.lineAt(
          synced,
          snapshot.data ?? Duration.zero,
        );
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.lyrics_rounded, color: AppTheme.gold),
                    SizedBox(width: 8),
                    Text(
                      'Synced lyrics',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  line?.text ?? synced.first.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        );
      },
    );
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
  Widget build(BuildContext context) => SizedBox(
        width: 86,
        child: Column(
          children: [
            IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
}
