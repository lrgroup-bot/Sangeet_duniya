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

class ActivationTokenRecord {
  const ActivationTokenRecord({
    required this.token,
    required this.customerName,
    required this.phoneNumber,
    required this.plan,
    required this.issuedAt,
    required this.expiresAt,
    required this.used,
    required this.activatedAt,
  });

  final String token;
  final String customerName;
  final String phoneNumber;
  final LicensePlan plan;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool used;
  final DateTime? activatedAt;

  bool get isLifetime => expiresAt == null;
  bool get isExpired =>
      expiresAt != null && !DateTime.now().toUtc().isBefore(expiresAt!);
  bool get isActive => used && !isExpired;

  LicenseInfo toLicenseInfo({String? phoneOverride}) => LicenseInfo(
        plan: plan,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
        phoneNumber: phoneOverride ?? phoneNumber,
        token: token,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'token': token,
        'customerName': customerName,
        'phone': phoneNumber,
        'plan': plan.name,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'used': used,
        'activatedAt': activatedAt?.toIso8601String(),
      };

  factory ActivationTokenRecord.fromJson(Map<String, dynamic> json) {
    final planName = json['plan']?.toString() ?? LicensePlan.sevenDays.name;
    final plan = LicensePlan.values.firstWhere(
      (value) => value.name == planName,
      orElse: () => LicensePlan.sevenDays,
    );
    final issued =
        DateTime.tryParse(json['issuedAt']?.toString() ?? '') ??
            DateTime.now().toUtc();
    final expiresRaw = json['expiresAt']?.toString();
    final activatedRaw = json['activatedAt']?.toString();

    return ActivationTokenRecord(
      token: json['token']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      phoneNumber: json['phone']?.toString() ?? '',
      plan: plan,
      issuedAt: issued.toUtc(),
      expiresAt: expiresRaw == null || expiresRaw.isEmpty
          ? null
          : DateTime.tryParse(expiresRaw)?.toUtc(),
      used: json['used'] == true,
      activatedAt: activatedRaw == null || activatedRaw.isEmpty
          ? null
          : DateTime.tryParse(activatedRaw)?.toUtc(),
    );
  }
}

class LicenseService {
  LicenseService._();

  static final instance = LicenseService._();

  // Retained only for compatibility with already-issued long tokens.
  static const _productSecret = 'LRS_SANGEET_DUNIYA_PRIVATE_2026';
  static const ownerPin = '333000';
  static const _issuedTokensKey = 'issued_tokens_v1';
  static const _issuedTokenRecordsKey = 'issued_token_records_v2';
  static const _activatedTokenRecordKey = 'activated_token_record_v1';

  /// Legacy long-token generator retained only so previously issued
  /// licenses/tests remain compatible. New customer tokens must use
  /// [generateActivationToken], which creates six-digit numeric codes.
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

  Future<ActivationTokenRecord> generateActivationToken(
    LicensePlan plan, {
    required String customerName,
    required String phoneNumber,
  }) async {
    final cleanName = customerName.trim();
    final cleanPhone = phoneNumber.trim();
    if (cleanName.isEmpty ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      throw ArgumentError(
        'Customer name and a valid 10-digit mobile number are required.',
      );
    }

    final records = await issuedTokenRecords();
    final usedCodes = records.map((record) => record.token).toSet();

    String token;
    do {
      token = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
    } while (usedCodes.contains(token));

    final issuedAt = DateTime.now().toUtc();
    final expiresAt =
        plan.duration == null ? null : issuedAt.add(plan.duration!);

    final record = ActivationTokenRecord(
      token: token,
      customerName: cleanName,
      phoneNumber: cleanPhone,
      plan: plan,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      used: false,
      activatedAt: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _issuedTokenRecordsKey,
      <String>[
        ...records.map((value) => jsonEncode(value.toJson())),
        jsonEncode(record.toJson()),
      ],
    );
    return record;
  }

  Future<List<ActivationTokenRecord>> issuedTokenRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final values =
        prefs.getStringList(_issuedTokenRecordsKey) ?? <String>[];
    return List.unmodifiable(
      values.map((raw) {
        try {
          return ActivationTokenRecord.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        } catch (_) {
          return null;
        }
      }).whereType<ActivationTokenRecord>(),
    );
  }

  Future<List<Map<String, dynamic>>> activationRecordsForSync() async {
    final records = await issuedTokenRecords();
    return records.map((record) => record.toJson()).toList(growable: false);
  }

  Future<ActivationTokenRecord?> consumeActivationToken(
    String rawToken, {
    required String phoneNumber,
  }) async {
    final token = rawToken.trim();
    final cleanPhone = phoneNumber.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(token) ||
        !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final records = await issuedTokenRecords();
    final index = records.indexWhere((record) => record.token == token);
    if (index < 0) return null;

    final record = records[index];
    if (record.used || record.isExpired) return null;
    if (record.phoneNumber != cleanPhone) return null;

    final activated = ActivationTokenRecord(
      token: record.token,
      customerName: record.customerName,
      phoneNumber: record.phoneNumber,
      plan: record.plan,
      issuedAt: record.issuedAt,
      expiresAt: record.expiresAt,
      used: true,
      activatedAt: DateTime.now().toUtc(),
    );

    final updated = [...records];
    updated[index] = activated;
    await prefs.setStringList(
      _issuedTokenRecordsKey,
      updated.map((value) => jsonEncode(value.toJson())).toList(),
    );
    await rememberActivatedRecord(activated);
    return activated;
  }

  Future<void> rememberActivatedRecord(
    ActivationTokenRecord record,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activatedTokenRecordKey,
      jsonEncode(record.toJson()),
    );
  }

  Future<ActivationTokenRecord?> localActivatedRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activatedTokenRecordKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ActivationTokenRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> rememberToken(String token) async {
    final clean = token.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final values =
        prefs.getStringList(_issuedTokensKey) ?? <String>[];
    if (!values.contains(clean)) {
      values.add(clean);
      await prefs.setStringList(_issuedTokensKey, values);
    }
  }

  Future<List<String>> issuedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy =
        prefs.getStringList(_issuedTokensKey) ?? <String>[];
    final records = await issuedTokenRecords();
    return List.unmodifiable(
      <String>{
        ...legacy,
        ...records.map((record) => record.token),
      },
    );
  }

  LicenseInfo? validateToken(String rawToken) {
    final token = rawToken.trim();

    if (RegExp(r'^\d{6}$').hasMatch(token)) {
      final activated = _cachedActivatedRecord;
      if (activated != null &&
          activated.token == token &&
          !activated.isExpired) {
        return activated.toLicenseInfo();
      }
      return null;
    }

    try {
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

  ActivationTokenRecord? _cachedActivatedRecord;

  Future<void> loadActivatedRecord() async {
    _cachedActivatedRecord = await localActivatedRecord();
  }

  bool verifyOwnerPin(String value) => value.trim() == ownerPin;

  String _sign(String payload) {
    return Hmac(
      sha256,
      utf8.encode(_productSecret),
    ).convert(utf8.encode(payload)).toString();
  }
}
