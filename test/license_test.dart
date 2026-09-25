import 'package:flutter_test/flutter_test.dart';

import 'package:lrs_sangeet_duniya/models/license_plan.dart';
import 'package:lrs_sangeet_duniya/services/license_service.dart';

void main() {
  test('v2.2 exposes all requested validity periods', () {
    expect(
      LicensePlan.values.map((plan) => plan.durationDays),
      containsAll(<int?>[7, 14, 30, 90, 180, 365, null]),
    );
  });

  test('activation code must be exactly six digits', () {
    final service = LicenseService.instance;
    expect(service.isSixDigitCode('123456'), isTrue);
    expect(service.isSixDigitCode('12345'), isFalse);
    expect(service.isSixDigitCode('1234567'), isFalse);
    expect(service.isSixDigitCode('12A456'), isFalse);
  });

  test('server activation payload round-trips through offline cache', () {
    final service = LicenseService.instance;
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'ok': true,
      'active': true,
      'activation': <String, dynamic>{
        'plan': LicensePlan.ninetyDays.name,
        'issued_at': now.toIso8601String(),
        'activated_at': now.toIso8601String(),
        'expires_at':
            now.add(const Duration(days: 90)).toIso8601String(),
        'phone': '+919999999999',
        'name': 'Test User',
        'activation_id': 'activation-test',
        'device_id': 'device-test',
      },
    };

    final info = service.fromServerPayload(payload);
    expect(info, isNotNull);
    expect(info!.plan, LicensePlan.ninetyDays);
    expect(info.isExpired, isFalse);

    final cached = service.decodeCache(service.encodeCache(info));
    expect(cached?.activationId, 'activation-test');
    expect(cached?.deviceId, 'device-test');
  });
}
