
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/registered_user.dart';
import 'license_service.dart';
import 'user_registry_service.dart';

/// Same-Wi-Fi registration bridge.
/// The administrator phone hosts a tiny HTTP server on the local network.
/// No cloud server, database, analytics, or remote account system is used.
class LocalLanService extends ChangeNotifier {
  static const int port = 40425;
  static const String _keyKey = 'local_admin_lan_key';
  static const String _savedLinkKey = 'local_admin_saved_link';

  HttpServer? _server;
  String _accessKey = '';
  String _savedAdminLink = '';
  List<String> _localIpv4 = <String>[];

  bool get isRunning => _server != null;
  String get savedAdminLink => _savedAdminLink;
  List<String> get localIpv4 => List.unmodifiable(_localIpv4);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessKey = prefs.getString(_keyKey) ?? '';
    _savedAdminLink = prefs.getString(_savedLinkKey) ?? '';
    if (_accessKey.isEmpty) {
      _accessKey = _newAccessKey();
      await prefs.setString(_keyKey, _accessKey);
    }
    await refreshNetworkInfo(notify: false);
    notifyListeners();
  }

  Future<void> start() async {
    if (_server != null) return;

    if (_accessKey.isEmpty) {
      await load();
    }

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _server!.listen(
        _handleRequest,
        onError: (_, __) {},
        cancelOnError: false,
      );
      await refreshNetworkInfo(notify: false);
    } catch (_) {
      _server = null;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    notifyListeners();
  }

  Future<void> refreshNetworkInfo({bool notify = true}) async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      final addresses = <String>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final value = address.address;
          if (value.startsWith('127.')) continue;
          if (value.startsWith('169.254.')) continue;
          if (!addresses.contains(value)) addresses.add(value);
        }
      }
      _localIpv4 = addresses;
    } catch (_) {
      _localIpv4 = <String>[];
    }
    if (notify) notifyListeners();
  }

  String get connectionLink {
    final host = _localIpv4.isNotEmpty ? _localIpv4.first : '127.0.0.1';
    return 'http://$host:$port/connect?key=\${Uri.encodeQueryComponent(_accessKey)}';
  }

  Future<bool> registerUser({
    required String adminLink,
    required String name,
    required String phoneNumber,
    required String token,
  }) async {
    final parsed = _parseLink(adminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final registerUri = parsed.replace(
      path: '/register',
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .post(
            registerUri,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'name': name.trim(),
              'phone': phoneNumber.trim(),
              'token': token.trim(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['ok'] != true) return false;

      _savedAdminLink = adminLink.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedLinkKey, _savedAdminLink);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> syncFromAdmin() async {
    final parsed = _parseLink(_savedAdminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final usersUri = parsed.replace(
      path: '/users',
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .get(usersUri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
        return false;
      }

      final rawUsers = decoded['users'];
      if (rawUsers is! List) return false;

      final users = rawUsers
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return RegisteredUser.fromJson(json);
            } catch (_) {
              return null;
            }
          })
          .whereType<RegisteredUser>()
          .toList();

      await userRegistry.replaceUsers(users);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'OPTIONS') {
        _respond(
          request,
          204,
          null,
          headers: <String, String>{
            'access-control-allow-origin': '*',
            'access-control-allow-methods': 'GET,POST,OPTIONS',
            'access-control-allow-headers': 'content-type',
          },
        );
        return;
      }

      if (request.uri.path == '/health') {
        _respond(request, 200, <String, dynamic>{
          'ok': true,
          'app': "LR's Sangeet_Duniya",
          'localOnly': true,
        });
        return;
      }

      final key = request.uri.queryParameters['key'] ?? '';
      if (key.isEmpty || !_constantTimeEquals(key, _accessKey)) {
        _respond(request, 401, <String, dynamic>{
          'ok': false,
          'error': 'Admin connection key required.',
        });
        return;
      }

      switch (request.uri.path) {
        case '/connect':
          _respond(request, 200, <String, dynamic>{
            'ok': true,
            'message': 'Connected to LR\\'s Sangeet_Duniya admin phone.',
          });
          return;
        case '/register':
          await _handleRegister(request);
          return;
        case '/users':
          _respond(request, 200, <String, dynamic>{
            'ok': true,
            'users': userRegistry.users
                .map(_userToNetwork)
                .toList(growable: false),
          });
          return;
        default:
          _respond(request, 404, <String, dynamic>{
            'ok': false,
            'error': 'Not found',
          });
          return;
      }
    } catch (_) {
      _respond(request, 500, <String, dynamic>{
        'ok': false,
        'error': 'Local admin service error.',
      });
    }
  }

  Future<void> _handleRegister(HttpRequest request) async {
    if (request.method != 'POST') {
      _respond(request, 405, <String, dynamic>{
        'ok': false,
        'error': 'POST required.',
      });
      return;
    }

    final body = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Invalid registration payload.',
      });
      return;
    }

    final name = decoded['name']?.toString().trim() ?? '';
    final phone = decoded['phone']?.toString().trim() ?? '';
    final token = decoded['token']?.toString().trim() ?? '';

    if (name.isEmpty || phone.length < 7 || token.isEmpty) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Name, phone and token are required.',
      });
      return;
    }

    final info = LicenseService.instance.validateToken(token);
    if (info == null) {
      _respond(request, 403, <String, dynamic>{
        'ok': false,
        'error': 'Token is invalid or expired.',
      });
      return;
    }

    if (info.phoneNumber.isNotEmpty && info.phoneNumber != phone) {
      _respond(request, 403, <String, dynamic>{
        'ok': false,
        'error': 'Token is bound to a different phone number.',
      });
      return;
    }

    await userRegistry.saveUser(
      name: name,
      phoneNumber: phone,
      planCode: info.plan.name,
      issuedAt: info.issuedAt,
      expiresAt: info.expiresAt,
      token: info.token,
    );

    _respond(request, 200, <String, dynamic>{
      'ok': true,
      'name': name,
      'phone': phone,
      'plan': info.plan.name,
      'issuedAt': info.issuedAt.toIso8601String(),
      'expiresAt': info.expiresAt?.toIso8601String(),
    });
  }

  Map<String, dynamic> _userToNetwork(RegisteredUser user) {
    return <String, dynamic>{
      'id': user.id,
      'name': user.name,
      'phone': user.phoneNumber,
      'plan': user.planCode,
      'issued': user.issuedAt.toIso8601String(),
      'expires': user.expiresAt?.toIso8601String(),
    };
  }

  void _respond(
    HttpRequest request,
    int statusCode,
    Object? body, {
    Map<String, String> headers = const <String, String>{},
  }) {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    for (final entry in headers.entries) {
      request.response.headers.set(entry.key, entry.value);
    }
    if (body != null) request.response.write(jsonEncode(body));
    request.response.close();
  }

  Uri? _parseLink(String input) {
    try {
      var value = input.trim();
      if (value.isEmpty) return null;
      if (!value.contains('://')) value = 'http://$value';
      return Uri.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _newAccessKey() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    return List.generate(
      28,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var value = 0;
    for (var i = 0; i < a.length; i++) {
      value |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return value == 0;
  }
}

final localLanService = LocalLanService();
