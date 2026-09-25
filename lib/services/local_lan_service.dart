import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Client for the Windows PC admin server.
///
/// The PC can be reached through a same-Wi-Fi address or a Tailscale address.
/// The mobile application never hosts the admin service.
class LocalLanService extends ChangeNotifier {
  static const int defaultPort = 40425;
  static const String _savedServerKey = 'sangeet_pc_admin_server_v2';

  String _serverUrl = '';
  bool _reachable = false;
  DateTime? _lastContact;

  String get serverUrl => _serverUrl;
  bool get isReachable => _reachable;
  DateTime? get lastContact => _lastContact;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_savedServerKey) ?? '';
    notifyListeners();
  }

  Future<void> setServerUrl(String value) async {
    final normalized = normalizeServerUrl(value);
    _serverUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_savedServerKey);
    } else {
      await prefs.setString(_savedServerKey, normalized);
    }
    notifyListeners();
  }

  String normalizeServerUrl(String value) {
    var text = value.trim();
    if (text.isEmpty) return '';
    if (!text.contains('://')) text = 'http://$text';

    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return '';

    final scheme = uri.scheme == 'https' ? 'https' : 'http';
    final port = uri.hasPort ? uri.port : defaultPort;
    return Uri(
      scheme: scheme,
      host: uri.host,
      port: port,
    ).toString().replaceFirst(RegExp(r'/$'), '');
  }

  Future<bool> checkHealth([String? url]) async {
    final base = normalizeServerUrl(url ?? _serverUrl);
    if (base.isEmpty) return false;

    try {
      final response = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 4));
      final decoded = jsonDecode(response.body);
      _reachable = response.statusCode == 200 &&
          decoded is Map<String, dynamic> &&
          decoded['ok'] == true;
      if (_reachable) _lastContact = DateTime.now();
    } catch (_) {
      _reachable = false;
    }
    notifyListeners();
    return _reachable;
  }

  Future<Map<String, dynamic>?> activate({
    required String serverUrl,
    required String code,
    required String name,
    required String phoneNumber,
    required String deviceId,
  }) async {
    final base = normalizeServerUrl(serverUrl);
    if (base.isEmpty) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$base/api/activate'),
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'code': code.trim(),
              'name': name.trim(),
              'phone': phoneNumber.trim(),
              'device_id': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 7));

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      _reachable = true;
      _lastContact = DateTime.now();
      if (response.statusCode == 200 && decoded['ok'] == true) {
        await setServerUrl(base);
      }
      notifyListeners();
      return decoded;
    } catch (_) {
      _reachable = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> syncActivation({
    required String activationId,
    required String deviceId,
  }) async {
    if (_serverUrl.isEmpty || activationId.isEmpty || deviceId.isEmpty) {
      return null;
    }

    final uri = Uri.parse('$_serverUrl/api/status').replace(
      queryParameters: <String, String>{
        'activation_id': activationId,
        'device_id': deviceId,
      },
    );

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      _reachable = true;
      _lastContact = DateTime.now();
      notifyListeners();
      return decoded;
    } catch (_) {
      _reachable = false;
      notifyListeners();
      return null;
    }
  }
}

final localLanService = LocalLanService();
