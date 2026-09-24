import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/license_plan.dart';
import 'license_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _ownerModeKey = 'owner_mode';
  static const _licenseTokenKey = 'license_token';
  static const _phoneNumberKey = 'license_phone';

  bool ready = false;
  bool isOwner = false;
  bool isActivated = false;
  String phoneNumber = '';
  LicenseInfo? license;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isOwner = prefs.getBool(_ownerModeKey) ?? false;
    phoneNumber = prefs.getString(_phoneNumberKey) ?? '';

    if (isOwner) {
      isActivated = true;
      ready = true;
      notifyListeners();
      return;
    }

    final token = prefs.getString(_licenseTokenKey);
    if (token != null) {
      final info = LicenseService.instance.validateToken(token);
      if (info != null) {
        license = info;
        phoneNumber = info.phoneNumber;
        isActivated = true;
      } else {
        await prefs.remove(_licenseTokenKey);
      }
    }

    ready = true;
    notifyListeners();
  }

  Future<bool> activateWithToken(
    String token, {
    required String phoneNumber,
  }) async {
    final cleanPhone = phoneNumber.trim();
    if (cleanPhone.length < 7) return false;

    final info = LicenseService.instance.validateToken(token);
    if (info == null) return false;
    if (info.phoneNumber.isNotEmpty && info.phoneNumber != cleanPhone) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseTokenKey, info.token);
    await prefs.setString(_phoneNumberKey, cleanPhone);
    await prefs.remove(_ownerModeKey);

    license = info;
    this.phoneNumber = cleanPhone;
    isOwner = false;
    isActivated = true;
    notifyListeners();
    return true;
  }

  Future<bool> unlockOwnerMode(String pin) async {
    if (!LicenseService.instance.verifyOwnerPin(pin)) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ownerModeKey, true);
    await prefs.remove(_licenseTokenKey);

    license = null;
    isOwner = true;
    isActivated = true;
    notifyListeners();
    return true;
  }

  Future<String?> generateToken(
    LicensePlan plan, {
    String phoneNumber = '',
  }) async {
    if (!isOwner) return null;
    return LicenseService.instance.generateToken(
      plan,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseTokenKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_ownerModeKey);
    isActivated = false;
    isOwner = false;
    license = null;
    phoneNumber = '';
    notifyListeners();
  }

  String get statusText {
    if (isOwner) return 'Owner device • Unlimited';
    if (!isActivated || license == null) return 'Activation required';
    if (license!.isLifetime) return 'Ultimate • Lifetime';
    final remaining = license!.remaining;
    if (remaining == null) return license!.plan.label;
    final days = remaining.inDays < 1 ? 1 : remaining.inDays;
    return license!.plan.label + ' • ' + days.toString() + ' day(s) left';
  }
}

final authProvider = AuthProvider();
