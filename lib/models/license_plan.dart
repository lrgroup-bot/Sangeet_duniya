enum LicensePlan {
  sevenDays,
  fourteenDays,
  thirtyDays,
  ninetyDays,
  oneHundredEightyDays,
  oneYear,
  lifetime,
}

extension LicensePlanInfo on LicensePlan {
  String get label => switch (this) {
        LicensePlan.sevenDays => '7 Days',
        LicensePlan.fourteenDays => '14 Days',
        LicensePlan.thirtyDays => '30 Days',
        LicensePlan.ninetyDays => '90 Days',
        LicensePlan.oneHundredEightyDays => '180 Days',
        LicensePlan.oneYear => '365 Days',
        LicensePlan.lifetime => 'Lifetime',
      };

  int? get durationDays => switch (this) {
        LicensePlan.sevenDays => 7,
        LicensePlan.fourteenDays => 14,
        LicensePlan.thirtyDays => 30,
        LicensePlan.ninetyDays => 90,
        LicensePlan.oneHundredEightyDays => 180,
        LicensePlan.oneYear => 365,
        LicensePlan.lifetime => null,
      };

}

LicensePlan licensePlanFromWire(String value) {
  for (final plan in LicensePlan.values) {
    if (plan.name == value) return plan;
  }
  throw FormatException('Unknown license plan: $value');
}
