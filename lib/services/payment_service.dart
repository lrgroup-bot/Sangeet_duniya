class PaymentService {
  PaymentService._();

  static final instance = PaymentService._();

  static const bool paymentsEnabled = false;

  bool get isPaymentEnabled => paymentsEnabled;

  Never startCheckout() {
    throw StateError('Payments are disabled in LR\'s Sangeet_Duniya.');
  }
}
