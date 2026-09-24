enum LicensePlan {
  sevenDays,
  thirtyDays,
  oneYear,
  ultimate,
}

extension LicensePlanInfo on LicensePlan {
  String get label => switch (this) {
        LicensePlan.sevenDays => '7 Days',
        LicensePlan.thirtyDays => '30 Days',
        LicensePlan.oneYear => '365 Days',
        LicensePlan.ultimate => 'Ultimate • Lifetime',
      };

  Duration? get duration => switch (this) {
        LicensePlan.sevenDays => const Duration(days: 7),
        LicensePlan.thirtyDays => const Duration(days: 30),
        LicensePlan.oneYear => const Duration(days: 365),
        LicensePlan.ultimate => null,
      };
}
