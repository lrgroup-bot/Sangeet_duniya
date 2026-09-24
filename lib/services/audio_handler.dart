import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../data/demo_songs.dart';
import '../models/song.dart';
import 'library_store.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  MusicAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(skipToNext());
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = 0;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;

  Future<void> playSong(Song song) async {
    final index = demoSongs.indexWhere((item) => item.id == song.id);
    if (index >= 0) _currentIndex = index;

    final item = MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      artUri: Uri.tryParse(song.artworkUrl),
      extras: <String, dynamic>{
        'category': song.category,
      },
    );

    mediaItem.add(item);
    await _player.stop();

    final localPath = libraryStore.localPathFor(song.id);
    final source = localPath != null && await File(localPath).exists()
        ? AudioSource.file(localPath, tag: item)
        : AudioSource.uri(Uri.parse(song.streamUrl), tag: item);

    final duration = await _player.setAudioSource(source);
    if (duration != null) {
      mediaItem.add(item.copyWith(duration: duration));
    }

    await libraryStore.recordPlayed(song);
    await _player.play();
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
    final processingState = switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (_player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        androidCompactActionIndices: const [0, 1, 2],
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
    // Keep audio service alive when the app task is swiped/removed.
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
