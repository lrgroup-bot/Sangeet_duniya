class RegisteredUser {
  const RegisteredUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.planCode,
    required this.issuedAt,
    required this.activatedAt,
    required this.expiresAt,
    required this.token,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String planCode;
  final DateTime issuedAt;
  final DateTime activatedAt;
  final DateTime? expiresAt;
  final String token;

  bool get isLifetime => expiresAt == null;

  bool get isActive =>
      expiresAt == null || DateTime.now().toUtc().isBefore(expiresAt!);

  int get daysLeft {
    if (expiresAt == null) return -1;
    final value = expiresAt!.difference(DateTime.now().toUtc()).inDays;
    return value < 0 ? 0 : value;
  }

  Duration? get remaining {
    if (expiresAt == null) return null;
    final value = expiresAt!.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'phone': phoneNumber,
        'plan': planCode,
        'issued': issuedAt.toIso8601String(),
        'activated': activatedAt.toIso8601String(),
        'expires': expiresAt?.toIso8601String(),
        'token': token,
      };

  factory RegisteredUser.fromJson(Map<String, dynamic> json) {
    final issued = DateTime.tryParse(json['issued']?.toString() ?? '') ??
        DateTime.now().toUtc();
    return RegisteredUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone']?.toString() ?? '',
      planCode: json['plan']?.toString() ?? 'sevenDays',
      issuedAt: issued,
      activatedAt: DateTime.tryParse(
            json['activated']?.toString() ?? '',
          ) ??
          issued,
      expiresAt: json['expires'] == null
          ? null
          : DateTime.tryParse(json['expires'].toString()),
      token: json['token']?.toString() ?? '',
    );
  }
}
