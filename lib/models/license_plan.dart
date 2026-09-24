enum LicensePlan {
  sevenDays,
  fourteenDays,
  thirtyDays,
  ninetyDays,
  oneEightyDays,
  oneYear,
  ultimate,
}

extension LicensePlanInfo on LicensePlan {
  String get label => switch (this) {
        LicensePlan.sevenDays => '7 Days',
        LicensePlan.fourteenDays => '14 Days',
        LicensePlan.thirtyDays => '30 Days',
        LicensePlan.ninetyDays => '90 Days',
        LicensePlan.oneEightyDays => '180 Days',
        LicensePlan.oneYear => '365 Days',
        LicensePlan.ultimate => 'Lifetime',
      };

  Duration? get duration => switch (this) {
        LicensePlan.sevenDays => const Duration(days: 7),
        LicensePlan.fourteenDays => const Duration(days: 14),
        LicensePlan.thirtyDays => const Duration(days: 30),
        LicensePlan.ninetyDays => const Duration(days: 90),
        LicensePlan.oneEightyDays => const Duration(days: 180),
        LicensePlan.oneYear => const Duration(days: 365),
        LicensePlan.ultimate => null,
      };
}
