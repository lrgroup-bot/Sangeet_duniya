import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import '../models/equalizer_profile.dart';
import '../models/song.dart';
import 'library_store.dart';

class AudioCleanupService {
  AudioCleanupService._();
  static final instance = AudioCleanupService._();

  Future<String> cleanDownloaded(Song song, {required EqualizerProfile profile}) async {
    final inputPath = libraryStore.localPathFor(song.id);
    if (inputPath == null || !await File(inputPath).exists()) throw StateError('Download the song first.');
    final input = File(inputPath);
    final outputPath = input.parent.path + Platform.pathSeparator + _baseName(input.path) + '.clean.flac';
    final filters = <String>['afftdn=nf=-25', 'highpass=f=30'];
    for (var i = 0; i < EqualizerProfile.frequenciesHz.length; i++) {
      filters.add('equalizer=f=' + EqualizerProfile.frequenciesHz[i].toString() + ':t=q:w=1:g=' + profile.gainsDb[i].toString());
    }
    filters.add('loudnorm=I=-14:TP=-1.5:LRA=11');
    final command = '-y -i ' + _quote(input.path) + ' -af ' + _quote(filters.join(',')) + ' -c:a flac ' + _quote(outputPath);
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !await File(outputPath).exists()) throw StateError('Clean Audio failed.');
    await libraryStore.saveDownload(song, outputPath);
    return outputPath;
  }
  String _baseName(String path) {
    final name = File(path).uri.pathSegments.isEmpty ? 'track' : File(path).uri.pathSegments.last;
    return name.replaceFirst(RegExp(r'\.[^.]+$'), '');
  }
  String _quote(String value) => "'" + value.replaceAll("'", "'\\\\''") + "'";
}
final audioCleanupService = AudioCleanupService.instance;