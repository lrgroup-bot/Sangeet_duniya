import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'local_lan_service.dart';

class LiveAvatarService extends ChangeNotifier {
  bool checking = false;
  bool available = false;
  String provider = 'Local animated avatar';
  String message = 'PC avatar not connected';
  String videoUrl = '';

  Future<void> refresh() async {
    final link = localLanService.remoteAdminLink.trim();
    if (link.isEmpty) {
      available = false;
      provider = 'Local animated avatar';
      message = 'PC avatar not connected';
      videoUrl = '';
      notifyListeners();
      return;
    }
    final parsed = Uri.tryParse(link);
    final key = parsed?.queryParameters['key'];
    if (parsed == null || key == null || key.isEmpty) {
      available = false;
      provider = 'Local animated avatar';
      message = 'PC avatar link needs an access key';
      videoUrl = '';
      notifyListeners();
      return;
    }
    checking = true;
    notifyListeners();
    try {
      final uri = parsed.replace(
        path: _append(parsed.path, '/avatar/status'),
        queryParameters: <String, String>{'key': key},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw StateError('HTTP ' + response.statusCode.toString());
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid avatar response');
      }
      available = decoded['available'] == true;
      provider = decoded['provider']?.toString() ?? 'PC live avatar';
      message = decoded['message']?.toString() ?? 'PC avatar status received';
      var value = decoded['videoUrl']?.toString() ?? '';
      if (value.isNotEmpty && !value.contains('://')) {
        value = parsed.replace(
          path: value,
          queryParameters: <String, String>{'key': key},
        ).toString();
      }
      videoUrl = value;
    } catch (_) {
      available = false;
      provider = 'Local animated avatar';
      message = 'PC avatar unreachable; local avatar remains active';
      videoUrl = '';
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  String _append(String path, String endpoint) {
    final clean = path.replaceFirst(RegExp(r'/+$'), '');
    return clean.isEmpty ? endpoint : clean + endpoint;
  }
}

final liveAvatarService = LiveAvatarService();
