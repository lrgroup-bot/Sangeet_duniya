import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../data/demo_songs.dart';
import '../models/equalizer_profile.dart';
import '../models/song.dart';
import 'avatar_profile_service.dart';
import 'equalizer_profile_service.dart';
import 'library_store.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  MusicAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) unawaited(skipToNext());
    });
  }

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer _loudness = AndroidLoudnessEnhancer();
  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: <AndroidAudioEffect>[_equalizer, _loudness],
    ),
  );

  final List<Song> _queue = <Song>[];
  int _currentIndex = 0;
  double _volume = 1;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;
  double get volume => _volume;

  Future<void> playSong(Song song, {List<Song>? songs}) async {
    if (songs != null && songs.isNotEmpty) {
      _queue
        ..clear()
        ..addAll(songs);
      final index = _queue.indexWhere((item) => item.id == song.id);
      _currentIndex = index < 0 ? 0 : index;
    } else if (_queue.isEmpty) {
      _queue
        ..clear()
        ..addAll(demoSongs);
      final index = _queue.indexWhere((item) => item.id == song.id);
      _currentIndex = index < 0 ? 0 : index;
    } else {
      final index = _queue.indexWhere((item) => item.id == song.id);
      if (index >= 0) _currentIndex = index;
    }

    await libraryStore.rememberSong(song);
    final item = _mediaItem(song);
    mediaItem.add(item);
    queue.add(_queue.map(_mediaItem).toList(growable: false));
    await _player.stop();

    final localPath = libraryStore.localPathFor(song.id);
    final source = localPath != null && await File(localPath).exists()
        ? AudioSource.file(localPath, tag: item)
        : AudioSource.uri(Uri.parse(song.streamUrl), tag: item);

    final duration = await _player.setAudioSource(source);
    if (duration != null) mediaItem.add(item.copyWith(duration: duration));

    await _applyRecommendedEq(song);
    await avatarProfileService.applyMood(song.category);
    await libraryStore.recordPlayed(song);
    await _player.setVolume(_volume);
    await _player.play();
  }

  MediaItem _mediaItem(Song song) => MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        artUri: Uri.tryParse(song.artworkUrl),
        extras: <String, dynamic>{
          'category': song.category,
          'source': song.source,
          'sourcePageUrl': song.sourcePageUrl,
          'quality': song.qualityLabel,
          'downloadable': song.isDownloadable,
        },
      );

  Future<void> _applyRecommendedEq(Song song) async {
    final profile = equalizerProfileService.profileFor(song);
    await applyEqualizer(profile);
  }

  Future<void> applyEqualizer(EqualizerProfile profile) async {
    if (!Platform.isAndroid) return;
    try {
      final parameters = await _equalizer.parameters;
      for (final band in parameters.bands) {
        var nearestIndex = 0;
        var nearestDistance = double.infinity;
        for (var i = 0; i < EqualizerProfile.frequenciesHz.length; i++) {
          final distance =
              (band.centerFrequency - EqualizerProfile.frequenciesHz[i]).abs();
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestIndex = i;
          }
        }
        final gain = profile.gainsDb[nearestIndex]
            .clamp(parameters.minDecibels, parameters.maxDecibels)
            .toDouble();
        await band.setGain(gain);
      }
      await _equalizer.setEnabled(true);
    } catch (_) {}
  }

  Future<void> setLoudnessBoost(bool enabled, {double gainDb = 2}) async {
    if (!Platform.isAndroid) return;
    try {
      await _loudness.setTargetGain(gainDb.clamp(0, 6).toDouble());
      await _loudness.setEnabled(enabled);
    } catch (_) {}
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    await _player.setVolume(_volume);
  }

  Future<void> adjustVolume(double delta) => setVolume(_volume + delta);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) _queue.addAll(demoSongs);
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await playSong(_queue[_currentIndex], songs: _queue);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) _queue.addAll(demoSongs);
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await playSong(_queue[_currentIndex], songs: _queue);
  }

  void _broadcastState(PlaybackEvent event) {
    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ),
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playback alive when the app task is removed.
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
