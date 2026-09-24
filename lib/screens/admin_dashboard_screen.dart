import 'package:flutter/material.dart';

import '../models/registered_user.dart';
import '../services/distribution_service.dart';
import '../services/user_registry_service.dart';
import '../theme/app_theme.dart';
import 'distribution_qr_screen.dart';
import 'license_admin_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  String _daysLabel(RegisteredUser user) {
    if (user.isLifetime) return 'Lifetime';
    if (!user.isActive) return 'Expired';
    return user.daysLeft.toString() + ' days left';
  }

  Color _statusColor(RegisteredUser user) {
    if (!user.isActive) return Colors.redAccent;
    if (!user.isLifetime && user.daysLeft <= 7) return Colors.orangeAccent;
    return AppTheme.gold2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sangeet Admin Dashboard')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          userRegistry,
          distributionService,
        ]),
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: userRegistry.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        title: 'Registered',
                        value: userRegistry.totalCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.verified_rounded,
                        title: 'Active',
                        value: userRegistry.activeCount.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timer_rounded,
                        title: 'Expiring ≤ 7d',
                        value: userRegistry.expiringSoonCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_busy_rounded,
                        title: 'Expired',
                        value: userRegistry.expiredCount.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free distribution',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'QR target: ' + distributionService.downloadUrl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .65),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const DistributionQrScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.qr_code_2_rounded),
                                label: const Text('QR / Link'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const LicenseAdminScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.key_rounded),
                                label: const Text('Create token'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Users & token validity',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (userRegistry.users.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No users yet. Create a token from License Manager and save the recipient name and phone number.',
                      ),
                    ),
                  )
                else
                  for (final user in userRegistry.users.reversed)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.gold.withValues(alpha: .14),
                          child: Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: AppTheme.gold2),
                          ),
                        ),
                        title: Text(
                          user.name.isEmpty ? 'Unnamed user' : user.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          user.phoneNumber + '\nPlan: ' + user.planCode,
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _daysLabel(user),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: _statusColor(user),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'This dashboard is fully local and uses no paid server. It shows records created on this administrator phone. Cross-device live counting would require a shared backend.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.gold, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
