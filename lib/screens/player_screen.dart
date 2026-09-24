import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/equalizer_profile.dart';
import '../models/song.dart';
import '../models/avatar_outfit.dart';
import '../services/audio_cleanup_service.dart';
import '../services/avatar_profile_service.dart';
import '../services/download_service.dart';
import '../services/equalizer_profile_service.dart';
import '../services/library_store.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_transport_controls.dart';
import 'dance_mode_screen.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import 'equalizer_screen.dart';

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
              if (snapshot.data == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Equalizer',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EqualizerScreen())),
                icon: const Icon(Icons.equalizer_rounded),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            final item = snapshot.data;
            if (item == null) return const Center(child: Text('Choose a song from Home or Search.'));

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
                        border: Border.all(color: Color(0x55FFC857)),
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
                    child: Image.network(item.artUri?.toString() ?? '', fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF17130A), alignment: Alignment.center,
                      child: const Icon(Icons.music_note_rounded, size: 110, color: AppTheme.gold),
                    )),
                  ),
                ),
                const SizedBox(height: 24),
                Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(item.artist ?? 'Unknown artist', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .65), fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  (item.extras?['source']?.toString() ?? 'Local') + ' • ' + (item.extras?['quality']?.toString() ?? 'Source quality'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: .50), fontSize: 12),
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
                      final current = position.inMilliseconds.toDouble()
                          .clamp(0.0, max)
                          .toDouble();
                      return Column(children: [
                        Slider(min: 0, max: max, value: current, onChanged: (v) => audioHandler.seek(Duration(milliseconds: v.round()))),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_format(position)), Text(_format(duration ?? Duration.zero))]),
                      ]);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const InteractiveTransportControls(),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: equalizerProfileService,
                  builder: (context, _) {
                    final recommendation = song == null ? 'Balanced' : equalizerProfileService.recommendationFor(song);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.gold),
                        title: Text(equalizerProfileService.mode == EqualizerMode.automatic ? 'Sangeeta Auto EQ' : 'Manual EQ'),
                        subtitle: Text(equalizerProfileService.mode == EqualizerMode.automatic ? 'Recommended profile: ' + recommendation : 'Manual profile is active'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EqualizerScreen())),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center, spacing: 12, runSpacing: 12,
                  children: [
                    _PlayerAction(icon: Icons.lyrics_rounded, label: 'Lyrics', onTap: () => _showLyrics(context, song, item.title)),
                    _PlayerAction(
                      icon: libraryStore.isDownloaded(item.id) ? Icons.download_done_rounded : Icons.download_rounded,
                      label: libraryStore.isDownloaded(item.id) ? 'Offline' : (song?.isDownloadable == false ? 'Stream only' : 'Download'),
                      onTap: () => _download(context, song),
                    ),
                    _PlayerAction(icon: Icons.auto_fix_high_rounded, label: 'Clean Audio', onTap: () => _clean(context, song)),
                    _PlayerAction(icon: Icons.auto_awesome_rounded, label: 'Dance', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DanceModeScreen(category: category)))),
                    _PlayerAction(
                      icon: Icons.checkroom_rounded,
                      label: 'Dress for song',
                      onTap: () => _chooseOutfit(context, song, item.id),
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

  Future<void> _chooseOutfit(
    BuildContext context,
    Song? song,
    String songId,
  ) async {
    if (song == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF11100E),
      builder: (sheetContext) => SafeArea(
        child: ListenableBuilder(
          listenable: avatarProfileService,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Sangeeta outfit for this song',
                  style: TextStyle(
                    color: AppTheme.gold2,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ...AvatarOutfit.values.map(
                  (outfit) => RadioListTile<AvatarOutfit>(
                    value: outfit,
                    groupValue: avatarProfileService.savedSongOutfit(songId) ??
                        avatarProfileService.outfitForSong(song),
                    onChanged: (value) async {
                      if (value == null) return;
                      await avatarProfileService.setSongOutfit(songId, value);
                      if (context.mounted) Navigator.of(sheetContext).pop();
                    },
                    title: Text(outfit.label),
                    secondary: const Icon(
                      Icons.checkroom_rounded,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await avatarProfileService.clearSongOutfit(songId);
                    await avatarProfileService.setOutfit(
                      avatarProfileService.outfitForSong(song),
                    );
                    if (context.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Use automatic mood / default'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLyrics(BuildContext context, Song? song, String title) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(song?.lyrics.isNotEmpty == true ? song!.lyrics : 'Lyrics are not available for this track yet.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _download(BuildContext context, Song? song) async {
    if (song == null) return;
    if (!song.isDownloadable && !libraryStore.isDownloaded(song.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This source allows streaming but does not mark the track as downloadable.')));
      return;
    }
    if (libraryStore.isDownloaded(song.id)) {
      await libraryStore.removeDownload(song);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline copy removed.')));
      return;
    }
    try {
      await DownloadService.instance.download(song);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved for offline playback.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: ' + e.toString())));
    }
  }

  Future<void> _clean(BuildContext context, Song? song) async {
    if (song == null || !libraryStore.isDownloaded(song.id)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download the track first, then use Clean Audio.')));
      return;
    }
    try {
      final profile = equalizerProfileService.profileFor(song);
      await audioCleanupService.cleanDownloaded(song, profile: profile);
      await audioHandler.playSong(song);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local cleaned FLAC created with denoise, EQ and loudness normalization.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clean Audio failed: ' + e.toString())));
    }
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return minutes + ':' + seconds;
  }
}

class _PlayerAction extends StatelessWidget {
  const _PlayerAction({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context) => SizedBox(
    width: 86, child: Column(children: [IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)), const SizedBox(height: 4), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))]),
  );
}