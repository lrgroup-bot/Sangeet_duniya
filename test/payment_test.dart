import 'package:flutter_test/flutter_test.dart';

import 'package:lrs_sangeet_duniya/services/payment_service.dart';

void main() {
  test('payments are permanently disabled', () {
    final service = PaymentService.instance;
    expect(service.isPaymentEnabled, isFalse);
    expect(PaymentService.paymentsEnabled, isFalse);
  });
}
