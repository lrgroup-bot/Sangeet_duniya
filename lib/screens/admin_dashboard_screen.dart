import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/registered_user.dart';
import '../services/license_service.dart';
import '../services/distribution_service.dart';
import '../services/local_lan_service.dart';
import '../services/user_registry_service.dart';
import '../theme/app_theme.dart';
import 'distribution_qr_screen.dart';
import 'license_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Timer? _timer;

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return local.year.toString() +
        '-' +
        two(local.month) +
        '-' +
        two(local.day) +
        ' ' +
        two(local.hour) +
        ':' +
        two(local.minute) +
        ':' +
        two(local.second);
  }

  String _remainingLabel(RegisteredUser user) {
    if (user.isLifetime) return 'Lifetime';
    final remaining = user.remaining ?? Duration.zero;
    if (remaining <= Duration.zero) return 'Expired';
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    return days.toString() + 'd ' +
        hours.toString() + 'h ' +
        minutes.toString() +
        'm left';
  }

  Future<void> _manualAddUser() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final tokenController = TextEditingController();

    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual add user'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'User name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tokenController,
                minLines: 3,
                maxLines: 4,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Existing token ID'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              <String>[
                nameController.text.trim(),
                phoneController.text.trim(),
                tokenController.text.trim(),
              ],
            ),
            child: const Text('Add user'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    tokenController.dispose();

    if (!mounted || values == null) return;

    final name = values[0];
    final phone = values[1];
    final token = values[2];
    final info = LicenseService.instance.validateToken(token);

    if (name.isEmpty || phone.length < 7 || info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, phone or token is invalid/expired.')),
      );
      return;
    }

    if (info.phoneNumber.isNotEmpty && info.phoneNumber != phone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This token is bound to a different phone number.')),
      );
      return;
    }

    await userRegistry.saveUser(
      name: name,
      phoneNumber: phone,
      planCode: info.plan.name,
      issuedAt: info.issuedAt,
      activatedAt: DateTime.now().toUtc(),
      expiresAt: info.expiresAt,
      token: info.token,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added with exact activation time.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    localLanService.start();
    _refreshRemote();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshRemote();
    });
  }

  Future<void> _refreshRemote() async {
    await localLanService.refreshNetworkInfo();
    await localLanService.syncFromAdmin();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _statusColor(RegisteredUser user) {
    if (!user.isActive) return Colors.redAccent;
    if (!user.isLifetime && user.daysLeft <= 7) return Colors.orangeAccent;
    return AppTheme.gold2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sangeet Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Manual add user',
            onPressed: _manualAddUser,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          userRegistry,
          distributionService,
          localLanService,
        ]),
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _refreshRemote,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        title: 'Signed up',
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
                          'Admin Wi-Fi connection',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localLanService.isRunning
                              ? 'Share this link with a phone that is on the same Wi-Fi.'
                              : 'Starting local admin service…',
                        ),
                        const SizedBox(height: 12),
                        if (localLanService.isRunning) ...[
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.white,
                              child: QrImageView(
                                data: localLanService.connectionLink,
                                size: 190,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            localLanService.connectionLink,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: localLanService.connectionLink,
                                      ),
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Admin Wi-Fi link copied.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copy link'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: _refreshRemote,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Sync'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User sign-ups',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'New sign-ups arrive automatically over the same Wi-Fi and refresh every 5 seconds while this dashboard is open.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (userRegistry.users.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No users have signed up yet. Generate a token first, then give the token and Admin Wi-Fi link to the user.',
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
                          user.phoneNumber +
                              '\nToken: ' +
                              user.token +
                              '\nActivated: ' +
                              _formatTime(user.activatedAt) +
                              '\nExpires: ' +
                              (user.expiresAt == null
                                  ? 'Lifetime'
                                  : _formatTime(user.expiresAt!)),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _remainingLabel(user),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: _statusColor(user),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Mobile-only architecture: no Supabase, no Vercel, no cloud database. The administrator phone is the local registration server.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .70),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.key_rounded, color: AppTheme.gold),
                  title: const Text('License Manager'),
                  subtitle: const Text(
                    'Create free 7-day, 30-day, 365-day or lifetime tokens',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LicenseAdminScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppTheme.gold,
                  ),
                  title: const Text('Download QR'),
                  subtitle: Text(distributionService.downloadUrl),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DistributionQrScreen(),
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
