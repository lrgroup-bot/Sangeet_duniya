import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/registered_user.dart';
import 'license_service.dart';
import 'user_registry_service.dart';

/// Local admin bridge. The admin phone exposes this service on the LAN.
/// Customers automatically discover it; no admin URL is shown on the login page.
class LocalLanService extends ChangeNotifier {
  static const int port = 40425;
  static const int discoveryPort = 40424;

  // Optional remote fallback for the Windows PC when Tailscale Serve is
  // intentionally configured on this host/port.
  static const String defaultRemotePcBase =
      'https://desktop-k7hn8f9.tailad23c2.ts.net:8443';

  static const String _keyKey = 'local_admin_lan_key';
  static const String _savedLinkKey = 'local_admin_saved_link';
  static const String _remoteAdminLinkKey = 'tailscale_admin_link';
  static const String _pendingRequestsKey = 'pending_access_requests_v1';

  HttpServer? _server;
  RawDatagramSocket? _discoverySocket;
  String _accessKey = '';
  String _savedAdminLink = '';
  String _remoteAdminLink = '';
  List<String> _localIpv4 = <String>[];
  List<Map<String, dynamic>> _pendingRequests = <Map<String, dynamic>>[];

  bool get isRunning => _server != null;
  String get savedAdminLink => _savedAdminLink;
  String get remoteAdminLink => _remoteAdminLink;
  List<String> get localIpv4 => List.unmodifiable(_localIpv4);
  List<Map<String, dynamic>> get pendingRequests => List.unmodifiable(_pendingRequests.map(Map<String, dynamic>.from));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessKey = prefs.getString(_keyKey) ?? '';
    _savedAdminLink = prefs.getString(_savedLinkKey) ?? '';
    _remoteAdminLink = prefs.getString(_remoteAdminLinkKey) ?? '';
    final pendingRaw =
        prefs.getStringList(_pendingRequestsKey) ?? <String>[];
    _pendingRequests
      ..clear()
      ..addAll(
        pendingRaw.map((raw) {
          try {
            final value = jsonDecode(raw);
            return value is Map<String, dynamic>
                ? Map<String, dynamic>.from(value)
                : null;
          } catch (_) {
            return null;
          }
        }).whereType<Map<String, dynamic>>(),
      );

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
        onError: (_, _) {},
        cancelOnError: false,
      );
      await refreshNetworkInfo(notify: false);
      await _startDiscoveryResponder();
    } catch (_) {
      _server = null;
    }
    notifyListeners();
  }

  Future<void> _startDiscoveryResponder() async {
    if (_discoverySocket != null) return;

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
      _discoverySocket = socket;

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;

        Datagram? datagram;
        try {
          datagram = socket.receive();
        } catch (_) {
          return;
        }
        if (datagram == null) return;

        final message = utf8.decode(datagram.data, allowMalformed: true).trim();
        if (message != 'LRS_DISCOVER_V1') return;

        final host =
            _localIpv4.isNotEmpty ? _localIpv4.first : datagram.address.address;
        final response = jsonEncode(<String, dynamic>{
          'v': 1,
          'app': "LR's Sangeet_Duniya",
          'host': host,
          'port': port,
          'key': _accessKey,
        });

        socket.send(
          utf8.encode(response),
          datagram.address,
          datagram.port,
        );
      });
    } catch (_) {
      _discoverySocket = null;
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _discoverySocket?.close();
    _discoverySocket = null;

    if (server != null) {
      await server.close(force: true);
    }
    notifyListeners();
  }

  Future<void> setRemoteAdminLink(String link) async {
    _remoteAdminLink = link.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_remoteAdminLink.isEmpty) {
      await prefs.remove(_remoteAdminLinkKey);
    } else {
      await prefs.setString(_remoteAdminLinkKey, _remoteAdminLink);
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
    return 'http://' +
        host +
        ':' +
        port.toString() +
        '/connect?key=' +
        Uri.encodeQueryComponent(_accessKey);
  }

  /// Customer-side activation. First discovers an admin phone on the same
  /// Wi-Fi. When unavailable, it falls back to the configured Tailscale PC.
  Future<ActivationTokenRecord?> activateToken({
    required String name,
    required String phoneNumber,
    required String token,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phoneNumber.trim();
    final cleanToken = token.trim();

    if (cleanName.isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone) ||
        !RegExp(r'^\d{6}$').hasMatch(cleanToken)) {
      return null;
    }

    final localEndpoints = await _discoverAdminEndpoints();
    for (final endpoint in localEndpoints) {
      final record = await _activateAgainstBase(
        endpoint,
        key: endpoint.queryParameters['key'] ?? '',
        name: cleanName,
        phoneNumber: cleanPhone,
        token: cleanToken,
      );
      if (record != null) return record;
    }

    return _activateAgainstRemotePc(
      name: cleanName,
      phoneNumber: cleanPhone,
      token: cleanToken,
    );
  }

  Future<List<Uri>> _discoverAdminEndpoints() async {
    final results = <String, Uri>{};

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;

      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;

        Datagram? datagram;
        try {
          datagram = socket.receive();
        } catch (_) {
          return;
        }
        if (datagram == null) return;

        try {
          final decoded = jsonDecode(
            utf8.decode(datagram.data, allowMalformed: true),
          );
          if (decoded is! Map<String, dynamic> || decoded['v'] != 1) {
            return;
          }

          final host = decoded['host']?.toString() ?? '';
          final valuePort = int.tryParse(decoded['port']?.toString() ?? '');
          final key = decoded['key']?.toString() ?? '';
          if (host.isEmpty || valuePort == null || key.isEmpty) return;

          final uri = Uri(
            scheme: 'http',
            host: host,
            port: valuePort,
            path: '/activate',
            queryParameters: <String, String>{'key': key},
          );
          results[uri.toString()] = uri;
        } catch (_) {}
      });

      socket.send(
        utf8.encode('LRS_DISCOVER_V1'),
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );

      await Future<void>.delayed(const Duration(seconds: 2));
      await subscription.cancel();
      socket.close();
    } catch (_) {}

    return results.values.toList(growable: false);
  }

  Future<ActivationTokenRecord?> _activateAgainstBase(
    Uri base, {
    required String key,
    required String name,
    required String phoneNumber,
    required String token,
  }) async {
    if (key.isEmpty) return null;

    final uri = base.replace(
      path: _appendEndpoint(base.path, '/activate'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'name': name,
              'phone': phoneNumber,
              'token': token,
            }),
          )
          .timeout(const Duration(seconds: 8));

      return _recordFromActivationResponse(response);
    } catch (_) {
      return null;
    }
  }

  Future<ActivationTokenRecord?> _activateAgainstRemotePc({
    required String name,
    required String phoneNumber,
    required String token,
  }) async {
    final preferred =
        _remoteAdminLink.isNotEmpty ? _remoteAdminLink : defaultRemotePcBase;
    final parsed = _parseLink(preferred);
    if (parsed == null) return null;

    final base = parsed.replace(queryParameters: const <String, String>{});

    try {
      final keyUri = base.replace(
        path: _appendEndpoint(base.path, '/public/user-key'),
      );
      final keyResponse = await http
          .get(keyUri)
          .timeout(const Duration(seconds: 5));
      if (keyResponse.statusCode != 200) return null;

      final keyBody = jsonDecode(keyResponse.body);
      if (keyBody is! Map<String, dynamic> || keyBody['ok'] != true) {
        return null;
      }

      final key = keyBody['key']?.toString() ?? '';
      if (key.isEmpty) return null;

      return await _activateAgainstBase(
        base,
        key: key,
        name: name,
        phoneNumber: phoneNumber,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  ActivationTokenRecord? _recordFromActivationResponse(
    http.Response response,
  ) {
    if (response.statusCode != 200) return null;

    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['ok'] != true) {
        return null;
      }
      final activation = body['activation'];
      if (activation is! Map<String, dynamic>) return null;
      return ActivationTokenRecord.fromJson(activation);
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestAccess({
    required String name,
    required String phoneNumber,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phoneNumber.trim();
    if (cleanName.length < 2 ||
        !RegExp(r'^[6-9]\d{9}    required String adminLink,
    required String name,
    required String phoneNumber,
    required String token,
  }) async {
    final parsed = _parseLink(adminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final registerUri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/register'),
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
          .timeout(const Duration(seconds: 8));

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
    final target =
        _remoteAdminLink.isNotEmpty ? _remoteAdminLink : _savedAdminLink;
    final parsed = _parseLink(target);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final usersUri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/users'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .get(usersUri)
          .timeout(const Duration(seconds: 8));
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

  Future<bool> syncTokensToRemote() async {
    if (_remoteAdminLink.isEmpty) return false;

    final parsed = _parseLink(_remoteAdminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final records = await LicenseService.instance.activationRecordsForSync();
    final tokens = await LicenseService.instance.issuedTokens();

    final uri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/tokens'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'activationTokens': records,
              'tokens': tokens,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> && body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkRemoteAdmin() async {
    if (_remoteAdminLink.isEmpty) return false;
    final parsed = _parseLink(_remoteAdminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final uri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/health'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
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
            'message': "Connected to LR's Sangeet_Duniya admin phone.",
          });
          return;
        case '/activate':
          await _handleActivate(request);
          return;
        case '/request-access':
          await _handleAccessRequest(request);
          return;
        case '/pending':
          await _handlePending(request);
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

  Future<void> _handleActivate(HttpRequest request) async {
    if (request.method != 'POST') {
      _respond(request, 405, <String, dynamic>{'ok': false, 'error': 'POST required.'});
      return;
    }

    final bodyText = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(bodyText);
    if (decoded is! Map<String, dynamic>) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Invalid activation payload.',
      });
      return;
    }

    final name = decoded['name']?.toString().trim() ?? '';
    final phone = decoded['phone']?.toString().trim() ?? '';
    final token = decoded['token']?.toString().trim() ?? '';

    if (name.isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(phone) ||
        !RegExp(r'^\d{6}$').hasMatch(token)) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Name, 10-digit phone number and 6-digit token are required.',
      });
      return;
    }

    final record = await LicenseService.instance.consumeActivationToken(
      token,
      phoneNumber: phone,
    );
    if (record == null) {
      _respond(request, 403, <String, dynamic>{
        'ok': false,
        'error': 'Invalid, expired, already-used, or phone-bound token.',
      });
      return;
    }

    await userRegistry.saveUser(
      name: name,
      phoneNumber: phone,
      planCode: record.plan.name,
      issuedAt: record.issuedAt,
      expiresAt: record.expiresAt,
      token: record.token,
      activatedAt: record.activatedAt ?? DateTime.now().toUtc(),
    );

    _respond(request, 200, <String, dynamic>{
      'ok': true,
      'activation': record.toJson(),
    });
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

    if (name.isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(phone) ||
        token.isEmpty) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Name, 10-digit phone number and token are required.',
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
      activatedAt: DateTime.now().toUtc(),
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
      'activated': user.activatedAt.toIso8601String(),
      'expires': user.expiresAt?.toIso8601String(),
      'token': user.token,
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
    request.response.headers.set('access-control-allow-origin', '*');
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

  String _appendEndpoint(String basePath, String endpoint) {
    final trimmed = basePath.replaceFirst(RegExp(r'/+$'), '');
    if (trimmed.isEmpty || trimmed == '/') return endpoint;
    return trimmed + endpoint;
  }

  String _newAccessKey() {
    final random = Random.secure();
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
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
).hasMatch(cleanPhone)) {
      return false;
    }

    final localEndpoints = await _discoverAdminEndpoints();
    for (final endpoint in localEndpoints) {
      if (await _postAccessRequest(
        endpoint,
        key: endpoint.queryParameters['key'] ?? '',
        name: cleanName,
        phoneNumber: cleanPhone,
      )) {
        return true;
      }
    }

    return _requestAccessAgainstRemotePc(
      name: cleanName,
      phoneNumber: cleanPhone,
    );
  }

  Future<bool> _postAccessRequest(
    Uri base, {
    required String key,
    required String name,
    required String phoneNumber,
  }) async {
    if (key.isEmpty) return false;
    final uri = base.replace(
      path: _appendEndpoint(base.path, '/request-access'),
      queryParameters: <String, String>{'key': key},
    );
    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'name': name,
              'phone': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _requestAccessAgainstRemotePc({
    required String name,
    required String phoneNumber,
  }) async {
    final preferred =
        _remoteAdminLink.isNotEmpty ? _remoteAdminLink : defaultRemotePcBase;
    final parsed = _parseLink(preferred);
    if (parsed == null) return false;
    final base = parsed.replace(queryParameters: const <String, String>{});

    try {
      final keyUri = base.replace(
        path: _appendEndpoint(base.path, '/public/user-key'),
      );
      final keyResponse =
          await http.get(keyUri).timeout(const Duration(seconds: 5));
      if (keyResponse.statusCode != 200) return false;

      final body = jsonDecode(keyResponse.body);
      if (body is! Map<String, dynamic> || body['ok'] != true) {
        return false;
      }

      final key = body['key']?.toString() ?? '';
      if (key.isEmpty) return false;

      return _postAccessRequest(
        base,
        key: key,
        name: name,
        phoneNumber: phoneNumber,
      );
    } catch (_) {
      return false;
    }
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
      path: _appendEndpoint(parsed.path, '/register'),
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
          .timeout(const Duration(seconds: 8));

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
    final target =
        _remoteAdminLink.isNotEmpty ? _remoteAdminLink : _savedAdminLink;
    final parsed = _parseLink(target);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final usersUri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/users'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .get(usersUri)
          .timeout(const Duration(seconds: 8));
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

  Future<bool> syncTokensToRemote() async {
    if (_remoteAdminLink.isEmpty) return false;

    final parsed = _parseLink(_remoteAdminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final records = await LicenseService.instance.activationRecordsForSync();
    final tokens = await LicenseService.instance.issuedTokens();

    final uri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/tokens'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .post(
            uri,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'activationTokens': records,
              'tokens': tokens,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> && body['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkRemoteAdmin() async {
    if (_remoteAdminLink.isEmpty) return false;
    final parsed = _parseLink(_remoteAdminLink);
    if (parsed == null) return false;

    final key = parsed.queryParameters['key'] ?? '';
    if (key.isEmpty) return false;

    final uri = parsed.replace(
      path: _appendEndpoint(parsed.path, '/health'),
      queryParameters: <String, String>{'key': key},
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
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
            'message': "Connected to LR's Sangeet_Duniya admin phone.",
          });
          return;
        case '/activate':
          await _handleActivate(request);
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

  Future<void> _handleActivate(HttpRequest request) async {
    if (request.method != 'POST') {
      _respond(request, 405, <String, dynamic>{'ok': false, 'error': 'POST required.'});
      return;
    }

    final bodyText = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(bodyText);
    if (decoded is! Map<String, dynamic>) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Invalid activation payload.',
      });
      return;
    }

    final name = decoded['name']?.toString().trim() ?? '';
    final phone = decoded['phone']?.toString().trim() ?? '';
    final token = decoded['token']?.toString().trim() ?? '';

    if (name.isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(phone) ||
        !RegExp(r'^\d{6}$').hasMatch(token)) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Name, 10-digit phone number and 6-digit token are required.',
      });
      return;
    }

    final record = await LicenseService.instance.consumeActivationToken(
      token,
      phoneNumber: phone,
    );
    if (record == null) {
      _respond(request, 403, <String, dynamic>{
        'ok': false,
        'error': 'Invalid, expired, already-used, or phone-bound token.',
      });
      return;
    }

    await userRegistry.saveUser(
      name: name,
      phoneNumber: phone,
      planCode: record.plan.name,
      issuedAt: record.issuedAt,
      expiresAt: record.expiresAt,
      token: record.token,
      activatedAt: record.activatedAt ?? DateTime.now().toUtc(),
    );

    _respond(request, 200, <String, dynamic>{
      'ok': true,
      'activation': record.toJson(),
    });
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

    if (name.isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(phone) ||
        token.isEmpty) {
      _respond(request, 400, <String, dynamic>{
        'ok': false,
        'error': 'Name, 10-digit phone number and token are required.',
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
      activatedAt: DateTime.now().toUtc(),
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
      'activated': user.activatedAt.toIso8601String(),
      'expires': user.expiresAt?.toIso8601String(),
      'token': user.token,
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
    request.response.headers.set('access-control-allow-origin', '*');
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

  String _appendEndpoint(String basePath, String endpoint) {
    final trimmed = basePath.replaceFirst(RegExp(r'/+$'), '');
    if (trimmed.isEmpty || trimmed == '/') return endpoint;
    return trimmed + endpoint;
  }

  String _newAccessKey() {
    final random = Random.secure();
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
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
