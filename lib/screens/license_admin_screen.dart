import 'package:flutter/material.dart';

import '../models/license_plan.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';

/// Token generation intentionally lives on the Windows PC in v2.2.
///
/// This compatibility screen remains so older navigation references do not
/// expose a mobile-side token generator or embed an admin signing secret.
class LicenseAdminScreen extends StatelessWidget {
  const LicenseAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activation Codes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.desktop_windows_rounded,
            size: 64,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 12),
          const Text(
            'Activation codes are generated on the Windows PC',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            'The mobile app no longer contains an owner PIN, signing secret, or token generator.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          const Text(
            'Supported validity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          for (final plan in LicensePlan.values)
            ListTile(
              leading:
                  const Icon(Icons.key_rounded, color: AppTheme.gold),
              title: Text(plan.label),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminDashboardScreen(),
              ),
            ),
            icon: const Icon(Icons.lan_rounded),
            label: const Text('PC server settings'),
          ),
        ],
      ),
    );
  }
}
