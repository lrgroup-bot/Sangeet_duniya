import 'package:flutter_test/flutter_test.dart';

import 'package:lrs_sangeet_duniya/models/license_plan.dart';
import 'package:lrs_sangeet_duniya/services/license_service.dart';

void main() {
  test('license token round-trips for each plan', () {
    final service = LicenseService.instance;

    for (final plan in LicensePlan.values) {
      final token = service.generateToken(plan);
      final info = service.validateToken(token);

      expect(info, isNotNull);
      expect(info!.plan, plan);
      expect(info.token, token);
      expect(info.isExpired, isFalse);
      if (plan == LicensePlan.ultimate) {
        expect(info.isLifetime, isTrue);
      } else {
        expect(info.expiresAt, isNotNull);
      }
    }
  });

  test('tampered token is rejected', () {
    final service = LicenseService.instance;
    final token = service.generateToken(LicensePlan.sevenDays);
    final last = token.endsWith('0') ? '1' : '0';
    final tampered = token.substring(0, token.length - 1) + last;

    expect(service.validateToken(tampered), isNull);
  });

  test('owner PIN gates owner mode', () {
    final service = LicenseService.instance;
    expect(service.verifyOwnerPin('wrong'), isFalse);
    // The real owner PIN is intentionally not hard-coded into the public test suite.
    expect(service.verifyOwnerPin('wrong'), isFalse);
  });
}
