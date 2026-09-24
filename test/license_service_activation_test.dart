import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/models/license_plan.dart';
import '../lib/services/license_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('owner PIN is 333000', () {
    expect(LicenseService.instance.verifyOwnerPin('333000'), isTrue);
    expect(LicenseService.instance.verifyOwnerPin('000000'), isFalse);
  });

  test('generates unique six digit token with exact validity', () async {
    final record = await LicenseService.instance.generateActivationToken(
      LicensePlan.fourteenDays,
      customerName: 'Test User',
      phoneNumber: '9876543210',
    );

    expect(RegExp(r'^\d{6}$').hasMatch(record.token), isTrue);
    expect(
      record.expiresAt!.difference(record.issuedAt),
      const Duration(days: 14),
    );
    expect(record.customerName, 'Test User');
    expect(record.phoneNumber, '9876543210');
    expect(record.used, isFalse);
  });

  test('activation consumes token once and binds phone', () async {
    final record = await LicenseService.instance.generateActivationToken(
      LicensePlan.thirtyDays,
      customerName: 'Test User',
      phoneNumber: '9876543210',
    );

    final wrongPhone = await LicenseService.instance.consumeActivationToken(
      record.token,
      phoneNumber: '9123456789',
    );
    expect(wrongPhone, isNull);

    final activated = await LicenseService.instance.consumeActivationToken(
      record.token,
      phoneNumber: '9876543210',
    );
    expect(activated, isNotNull);
    expect(activated!.used, isTrue);
    expect(activated.activatedAt, isNotNull);

    final secondAttempt =
        await LicenseService.instance.consumeActivationToken(
      record.token,
      phoneNumber: '9876543210',
    );
    expect(secondAttempt, isNull);

    await LicenseService.instance.loadActivatedRecord();
    final info = LicenseService.instance.validateToken(record.token);
    expect(info, isNotNull);
    expect(info!.expiresAt, activated.expiresAt);
  });
}