import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/license_plan.dart';
import 'license_service.dart';
import 'local_lan_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _ownerModeKey = 'owner_mode';
  static const _licenseTokenKey = 'license_token';
  static const _phoneNumberKey = 'license_phone';
  static const _nameKey = 'license_name';

  Timer? _expiryTimer;

  bool ready = false;
  bool isOwner = false;
  bool isActivated = false;
  String phoneNumber = '';
  String userName = '';
  LicenseInfo? license;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await LicenseService.instance.loadActivatedRecord();

    isOwner = prefs.getBool(_ownerModeKey) ?? false;
    phoneNumber = prefs.getString(_phoneNumberKey) ?? '';
    userName = prefs.getString(_nameKey) ?? '';

    if (isOwner) {
      isActivated = true;
      await localLanService.start();
      ready = true;
      notifyListeners();
      return;
    }

    final token = prefs.getString(_licenseTokenKey);
    if (token != null) {
      final info = LicenseService.instance.validateToken(token);
      if (info != null) {
        license = info;
        if (info.phoneNumber.isNotEmpty) {
          phoneNumber = info.phoneNumber;
        }
        isActivated = true;
        _scheduleExpiry();
      } else {
        await prefs.remove(_licenseTokenKey);
        isActivated = false;
      }
    }

    ready = true;
    notifyListeners();
  }

  Future<bool> activateFromRecord(
    ActivationTokenRecord record, {
    required String phoneNumber,
    required String name,
  }) async {
    final cleanPhone = phoneNumber.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) return false;
    if (record.phoneNumber != cleanPhone || record.isExpired) return false;

    final prefs = await SharedPreferences.getInstance();
    await LicenseService.instance.rememberActivatedRecord(record);
    await prefs.setString(_licenseTokenKey, record.token);
    await prefs.setString(_phoneNumberKey, cleanPhone);
    await prefs.setString(_nameKey, name.trim());
    await prefs.remove(_ownerModeKey);

    license = record.toLicenseInfo(phoneOverride: cleanPhone);
    this.phoneNumber = cleanPhone;
    userName = name.trim();
    isOwner = false;
    isActivated = true;
    _scheduleExpiry();
    notifyListeners();
    return true;
  }

  Future<bool> activateWithToken(
    String token, {
    required String phoneNumber,
    String name = '',
  }) async {
    final cleanPhone = phoneNumber.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) return false;

    final info = LicenseService.instance.validateToken(token);
    if (info == null) return false;
    if (info.phoneNumber.isNotEmpty && info.phoneNumber != cleanPhone) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseTokenKey, info.token);
    await prefs.setString(_phoneNumberKey, cleanPhone);
    await prefs.setString(_nameKey, name.trim());
    await prefs.remove(_ownerModeKey);

    license = info;
    this.phoneNumber = cleanPhone;
    userName = name.trim();
    isOwner = false;
    isActivated = true;
    _scheduleExpiry();
    notifyListeners();
    return true;
  }

  Future<bool> unlockOwnerMode(String pin) async {
    if (!LicenseService.instance.verifyOwnerPin(pin)) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ownerModeKey, true);
    await prefs.remove(_licenseTokenKey);
    await prefs.remove(_nameKey);

    license = null;
    isOwner = true;
    isActivated = true;
    userName = 'Owner';
    await localLanService.start();
    notifyListeners();
    return true;
  }

  Future<ActivationTokenRecord?> generateActivationToken(
    LicensePlan plan, {
    required String customerName,
    required String phoneNumber,
  }) async {
    if (!isOwner) return null;
    final record = await LicenseService.instance.generateActivationToken(
      plan,
      customerName: customerName,
      phoneNumber: phoneNumber,
    );
    await localLanService.syncTokensToRemote();
    return record;
  }

  Future<String?> generateToken(
    LicensePlan plan, {
    String phoneNumber = '',
  }) async {
    if (!isOwner) return null;
    final record = await LicenseService.instance.generateActivationToken(
      plan,
      customerName: '',
      phoneNumber: phoneNumber,
    );
    await localLanService.syncTokensToRemote();
    return record.token;
  }

  Future<void> signOut() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseTokenKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_ownerModeKey);

    isActivated = false;
    isOwner = false;
    license = null;
    phoneNumber = '';
    userName = '';
    await localLanService.stop();
    notifyListeners();
  }

  String get statusText {
    if (isOwner) return 'Owner device • Unlimited';
    if (!isActivated || license == null) return 'Activation required';
    if (license!.isLifetime) return 'Lifetime access';
    final remaining = license!.remaining;
    if (remaining == null) return license!.plan.label;
    final days = remaining.inDays < 1 ? 1 : remaining.inDays;
    return license!.plan.label + ' • ' + days.toString() + ' day(s) left';
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiresAt = license?.expiresAt;
    if (expiresAt == null) return;

    final delay = expiresAt.difference(DateTime.now().toUtc());
    if (delay.isNegative) {
      _expireNow();
      return;
    }

    _expiryTimer = Timer(delay, _expireNow);
  }

  Future<void> _expireNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseTokenKey);
    isActivated = false;
    license = null;
    _expiryTimer = null;
    notifyListeners();
  }
}

final authProvider = AuthProvider();
