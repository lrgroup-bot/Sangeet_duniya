import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import 'library_store.dart';

class DownloadService {
  DownloadService._();
  static final instance = DownloadService._();

  Future<String> download(Song song, {void Function(double progress)? onProgress}) async {
    if (!song.isDownloadable) {
      throw StateError('This source does not mark the track as downloadable.');
    }
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(directory.path + '/sangeet_duniya/downloads');
    await downloadsDir.create(recursive: true);
    final file = File(downloadsDir.path + '/' + _safeName(song.title) + '-' + song.id + '.audio');
    final request = http.Request('GET', Uri.parse(song.streamUrl));
    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Download failed with HTTP ' + response.statusCode.toString());
    }
    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
    } catch (_) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }
    await libraryStore.saveDownload(song, file.path);
    onProgress?.call(1);
    return file.path;
  }

  String _safeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '').replaceAll(RegExp(r'\s+'), '_').trim();
    return cleaned.isEmpty ? 'track' : cleaned;
  }
}