import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/registered_user.dart';

class UserRegistryService extends ChangeNotifier {
  static const _key = 'registered_users_v1';

  final List<RegisteredUser> _users = <RegisteredUser>[];

  List<RegisteredUser> get users => List.unmodifiable(_users);
  int get totalCount => _users.length;
  int get activeCount => _users.where((u) => u.isActive).length;
  int get expiredCount => _users.where((u) => !u.isActive).length;
  int get expiringSoonCount => _users
      .where((u) => u.isActive && !u.isLifetime && u.daysLeft <= 7)
      .length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? <String>[];
    _users
      ..clear()
      ..addAll(values.map((raw) {
        try {
          return RegisteredUser.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        } catch (_) {
          return null;
        }
      }).whereType<RegisteredUser>());
    notifyListeners();
  }

  Future<void> saveUser({
    required String name,
    required String phoneNumber,
    required String planCode,
    required DateTime issuedAt,
    required DateTime? expiresAt,
    required String token,
  }) async {
    final phone = phoneNumber.trim();
    final index = _users.indexWhere((u) => u.phoneNumber == phone);
    final id = index >= 0
        ? _users[index].id
        : DateTime.now().microsecondsSinceEpoch.toString();

    final user = RegisteredUser(
      id: id,
      name: name.trim(),
      phoneNumber: phone,
      planCode: planCode,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      token: token.trim(),
    );

    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> removeUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _users.map((u) => jsonEncode(u.toJson())).toList(),
    );
  }
}

final userRegistry = UserRegistryService();
