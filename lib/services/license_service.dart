import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/license_plan.dart';

class LicenseInfo {
  const LicenseInfo({
    required this.plan,
    required this.issuedAt,
    required this.expiresAt,
    required this.phoneNumber,
    required this.token,
  });

  final LicensePlan plan;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String phoneNumber;
  final String token;

  bool get isLifetime => expiresAt == null;
  bool get isExpired =>
      expiresAt != null && !DateTime.now().toUtc().isBefore(expiresAt!);

  Duration? get remaining {
    if (expiresAt == null) return null;
    final value = expiresAt!.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }
}

class LicenseService {
  LicenseService._();

  static final instance = LicenseService._();

  // Practical private-app gate. A public commercial release should use
  // server-backed licensing or asymmetric signatures.
  static const _productSecret = 'LRS_SANGEET_DUNIYA_PRIVATE_2026';
  static const ownerPin = 'LRS-OWNER-2026';
  static const _issuedTokensKey = 'issued_tokens_v1';

  String generateToken(
    LicensePlan plan, {
    String phoneNumber = '',
  }) {
    final now = DateTime.now().toUtc();
    final expiry = plan.duration == null ? null : now.add(plan.duration!);

    final payload = <String, dynamic>{
      'v': 1,
      'plan': plan.name,
      'issued': now.millisecondsSinceEpoch,
      'expires': expiry?.millisecondsSinceEpoch ?? 0,
      'phone': phoneNumber.trim(),
      'nonce': Random.secure().nextInt(0x7fffffff),
    };

    final payloadText =
        base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
    return 'LRS1.' + payloadText + '.' + _sign(payloadText);
  }

  Future<void> rememberToken(String token) async {
    final clean = token.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_issuedTokensKey) ?? <String>[];
    if (!values.contains(clean)) {
      values.add(clean);
      await prefs.setStringList(_issuedTokensKey, values);
    }
  }

  Future<List<String>> issuedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return List.unmodifiable(
      prefs.getStringList(_issuedTokensKey) ?? <String>[],
    );
  }

  LicenseInfo? validateToken(String rawToken) {
    try {
      final token = rawToken.trim();
      final parts = token.split('.');
      if (parts.length != 3 || parts.first != 'LRS1') return null;

      final payloadText = parts[1];
      if (_sign(payloadText) != parts[2]) return null;

      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(payloadText))),
      );
      if (decoded is! Map<String, dynamic> || decoded['v'] != 1) {
        return null;
      }

      final plan = LicensePlan.values.firstWhere(
        (value) => value.name == decoded['plan']?.toString(),
      );
      final issuedMs = int.parse(decoded['issued'].toString());
      final expiresMs = int.parse(decoded['expires'].toString());

      final expiresAt = expiresMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true);
      if (expiresAt != null && !DateTime.now().toUtc().isBefore(expiresAt)) {
        return null;
      }

      return LicenseInfo(
        plan: plan,
        issuedAt: DateTime.fromMillisecondsSinceEpoch(
          issuedMs,
          isUtc: true,
        ),
        expiresAt: expiresAt,
        phoneNumber: decoded['phone']?.toString() ?? '',
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  bool verifyOwnerPin(String value) => value.trim() == ownerPin;

  String _sign(String payload) {
    return Hmac(
      sha256,
      utf8.encode(_productSecret),
    ).convert(utf8.encode(payload)).toString();
  }
}
