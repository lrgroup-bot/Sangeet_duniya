import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../data/demo_songs.dart';
import '../models/song.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  MusicAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = 0;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> playSong(Song song) async {
    final index = demoSongs.indexWhere((item) => item.id == song.id);
    if (index >= 0) {
      _currentIndex = index;
    }

    final item = MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      artUri: Uri.tryParse(song.artworkUrl),
      duration: await _safeDuration(song.streamUrl),
    );

    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(song.streamUrl),
        tag: item,
      ),
    );
    await _player.play();
  }

  Future<Duration?> _safeDuration(String url) async {
    try {
      final duration = await _player.setUrl(url);
      return duration;
    } catch (_) {
      return null;
    }
  }

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
    _currentIndex = (_currentIndex + 1) % demoSongs.length;
    await playSong(demoSongs[_currentIndex]);
  }

  @override
  Future<void> skipToPrevious() async {
    _currentIndex = (_currentIndex - 1 + demoSongs.length) % demoSongs.length;
    await playSong(demoSongs[_currentIndex]);
  }

  void _broadcastState(PlaybackEvent event) {
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;

    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [1, 2, 3],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ),
    );

    if (_player.currentIndex != null) {
      _currentIndex = _player.currentIndex!;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> close() async {
    await _player.dispose();
    await super.stop();
  }
}
