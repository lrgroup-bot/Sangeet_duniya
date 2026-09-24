import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/license_plan.dart';

class LicenseInfo {
  const LicenseInfo({
    required this.plan,
    required this.issuedAt,
    required this.expiresAt,
    required this.token,
  });

  final LicensePlan plan;
  final DateTime issuedAt;
  final DateTime? expiresAt;
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

  // Practical private-app gate. For a public commercial release, use
  // server-backed licensing or an asymmetric signature scheme.
  static const _productSecret = 'LRS_SANGEET_DUNIYA_PRIVATE_2026';
  static const ownerPin = 'LRS-OWNER-2026';

  String generateToken(LicensePlan plan) {
    final now = DateTime.now().toUtc();
    final expiry = plan.duration == null ? null : now.add(plan.duration!);

    final payload = <String, dynamic>{
      'v': 1,
      'plan': plan.name,
      'issued': now.millisecondsSinceEpoch,
      'expires': expiry?.millisecondsSinceEpoch ?? 0,
      'nonce': Random.secure().nextInt(0x7fffffff),
    };

    final payloadText =
        base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
    final signature = _sign(payloadText);
    return 'LRS1.$payloadText.$signature';
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

      final planName = decoded['plan']?.toString();
      final plan = LicensePlan.values.firstWhere(
        (value) => value.name == planName,
      );
      final issuedMs = int.parse(decoded['issued'].toString());
      final expiresMs = int.parse(decoded['expires'].toString());

      final issuedAt = DateTime.fromMillisecondsSinceEpoch(
        issuedMs,
        isUtc: true,
      );
      final expiresAt = expiresMs == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true);

      if (expiresAt != null && !DateTime.now().toUtc().isBefore(expiresAt)) {
        return null;
      }

      return LicenseInfo(
        plan: plan,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  bool verifyOwnerPin(String value) => value.trim() == ownerPin;

  String _sign(String payload) {
    final mac = Hmac(sha256, utf8.encode(_productSecret));
    return mac.convert(utf8.encode(payload)).toString();
  }
}
