import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'license_service.dart';
import 'local_lan_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _activationKey = 'sangeet_pc_activation_v2';
  static const _phoneNumberKey = 'license_phone';
  static const _nameKey = 'license_name';
  static const _deviceIdKey = 'sangeet_device_id_v2';

  Timer? _expiryTimer;

  bool ready = false;
  bool isActivated = false;
  bool syncing = false;
  String phoneNumber = '';
  String userName = '';
  String deviceId = '';
  LicenseInfo? license;

  String get serverUrl => localLanService.serverUrl;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString(_phoneNumberKey) ?? '';
    userName = prefs.getString(_nameKey) ?? '';
    deviceId = prefs.getString(_deviceIdKey) ?? '';

    if (deviceId.isEmpty) {
      deviceId = _newDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    final raw = prefs.getString(_activationKey);
    if (raw != null) {
      license = LicenseService.instance.decodeCache(raw);
      if (license != null) {
        isActivated = true;
        phoneNumber = license!.phoneNumber;
        userName = license!.userName;
        _scheduleExpiry();
      } else {
        await prefs.remove(_activationKey);
      }
    }

    ready = true;
    notifyListeners();

    if (isActivated && localLanService.serverUrl.isNotEmpty) {
      unawaited(syncWithAdmin());
    }
  }

  Future<bool> activateWithCode(
    String code, {
    required String phoneNumber,
    required String name,
    required String serverUrl,
  }) async {
    final cleanPhone = phoneNumber.trim();
    final cleanName = name.trim();
    final cleanCode = code.trim();

    if (cleanName.isEmpty ||
        cleanPhone.length < 7 ||
        !LicenseService.instance.isSixDigitCode(cleanCode)) {
      return false;
    }

    syncing = true;
    notifyListeners();

    final response = await localLanService.activate(
      serverUrl: serverUrl,
      code: cleanCode,
      name: cleanName,
      phoneNumber: cleanPhone,
      deviceId: deviceId,
    );

    final info = response == null
        ? null
        : LicenseService.instance.fromServerPayload(response);

    syncing = false;

    if (info == null || info.isExpired) {
      notifyListeners();
      return false;
    }

    await _storeActivation(info);
    notifyListeners();
    return true;
  }

  Future<bool> syncWithAdmin() async {
    final current = license;
    if (current == null) return false;

    syncing = true;
    notifyListeners();

    final response = await localLanService.syncActivation(
      activationId: current.activationId,
      deviceId: deviceId,
    );

    syncing = false;

    if (response == null) {
      notifyListeners();
      return false;
    }

    if (response['ok'] != true || response['active'] == false) {
      await _clearActivation();
      notifyListeners();
      return false;
    }

    final info = LicenseService.instance.fromServerPayload(response);
    if (info == null || info.isExpired) {
      await _clearActivation();
      notifyListeners();
      return false;
    }

    await _storeActivation(info);
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await _clearActivation();
    phoneNumber = '';
    userName = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_nameKey);
    notifyListeners();
  }

  String get statusText {
    final info = license;
    if (!isActivated || info == null) return 'Activation required';
    if (info.isLifetime) return 'Lifetime • PC verified';

    final remaining = info.remaining;
    if (remaining == null || remaining <= Duration.zero) {
      return 'Expired';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    if (days > 0) {
      return '${info.plan.label} • ${days}d ${hours}h left';
    }
    final minutes = remaining.inMinutes.remainder(60);
    return '${info.plan.label} • ${hours}h ${minutes}m left';
  }

  Future<void> _storeActivation(LicenseInfo info) async {
    license = info;
    phoneNumber = info.phoneNumber;
    userName = info.userName;
    isActivated = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activationKey,
      LicenseService.instance.encodeCache(info),
    );
    await prefs.setString(_phoneNumberKey, phoneNumber);
    await prefs.setString(_nameKey, userName);
    _scheduleExpiry();
  }

  Future<void> _clearActivation() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    license = null;
    isActivated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activationKey);
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiresAt = license?.expiresAt;
    if (expiresAt == null) return;

    final delay = expiresAt.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      unawaited(_clearActivation().then((_) => notifyListeners()));
      return;
    }
    _expiryTimer = Timer(delay, () {
      unawaited(_clearActivation().then((_) => notifyListeners()));
    });
  }

  String _newDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

final authProvider = AuthProvider();
