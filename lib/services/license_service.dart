import 'dart:convert';

import '../models/license_plan.dart';

class LicenseInfo {
  const LicenseInfo({
    required this.plan,
    required this.issuedAt,
    required this.activatedAt,
    required this.expiresAt,
    required this.phoneNumber,
    required this.userName,
    required this.activationId,
    required this.deviceId,
  });

  final LicensePlan plan;
  final DateTime issuedAt;
  final DateTime activatedAt;
  final DateTime? expiresAt;
  final String phoneNumber;
  final String userName;
  final String activationId;
  final String deviceId;

  bool get isLifetime => expiresAt == null;

  bool get isExpired =>
      expiresAt != null && !DateTime.now().toUtc().isBefore(expiresAt!);

  Duration? get remaining {
    if (expiresAt == null) return null;
    final value = expiresAt!.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'plan': plan.name,
        'issued_at': issuedAt.toIso8601String(),
        'activated_at': activatedAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'phone': phoneNumber,
        'name': userName,
        'activation_id': activationId,
        'device_id': deviceId,
      };
}

class LicenseService {
  LicenseService._();

  static final instance = LicenseService._();

  bool isSixDigitCode(String value) =>
      RegExp(r'^\d{6}$').hasMatch(value.trim());

  LicenseInfo? fromServerPayload(Map<String, dynamic> json) {
    try {
      final activation = json['activation'];
      if (activation is! Map<String, dynamic>) return null;
      if (json['active'] == false) return null;
      return _parseActivation(activation);
    } catch (_) {
      return null;
    }
  }

  LicenseInfo? decodeCache(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final info = _parseActivation(decoded);
      return info.isExpired ? null : info;
    } catch (_) {
      return null;
    }
  }

  String encodeCache(LicenseInfo info) => jsonEncode(info.toJson());

  LicenseInfo _parseActivation(Map<String, dynamic> json) {
    final plan = LicensePlanInfo.fromWire(json['plan']?.toString() ?? '');
    final issuedAt = DateTime.parse(json['issued_at'].toString()).toUtc();
    final activatedAt =
        DateTime.parse(json['activated_at'].toString()).toUtc();
    final expiryRaw = json['expires_at'];
    final expiresAt = expiryRaw == null || expiryRaw.toString().isEmpty
        ? null
        : DateTime.parse(expiryRaw.toString()).toUtc();

    return LicenseInfo(
      plan: plan,
      issuedAt: issuedAt,
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      phoneNumber: json['phone']?.toString() ?? '',
      userName: json['name']?.toString() ?? '',
      activationId: json['activation_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
    );
  }
}
