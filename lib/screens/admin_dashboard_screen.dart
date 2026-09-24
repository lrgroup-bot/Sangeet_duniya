import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/license_plan.dart';
import '../services/auth_provider.dart';
import '../services/avatar_profile_service.dart';
import '../services/license_service.dart';
import '../services/local_lan_service.dart';
import '../services/user_registry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import 'distribution_qr_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _remote = TextEditingController();

  LicensePlan _plan = LicensePlan.thirtyDays;
  ActivationTokenRecord? _last;
  List<ActivationTokenRecord> _history = <ActivationTokenRecord>[];
  Map<String, dynamic>? _verified;
  bool _pcOnline = false;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remote.text = localLanService.remoteAdminLink;
    localLanService.start();
    userRegistry.load();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _phone.dispose();
    _remote.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await localLanService.syncPendingFromRemote();
    await userRegistry.load();
    final tokens = await LicenseService.instance.issuedTokenRecords();
    final online = await localLanService.checkRemoteAdmin();
    if (!mounted) return;
    setState(() {
      _history = tokens.reversed.toList(growable: false);
      _pcOnline = online;
      if (_remote.text != localLanService.remoteAdminLink) {
        _remote.text = localLanService.remoteAdminLink;
      }
    });
  }

  Future<void> _sync() async {
    if (_busy) return;
    setState(() => _busy = true);

    final pending = await localLanService.syncPendingFromRemote();
    final users = await localLanService.syncFromAdmin();
    final tokens = await localLanService.syncTokensToRemote();
    final online = await localLanService.checkRemoteAdmin();
    await _refresh();

    if (!mounted) return;
    setState(() {
      _pcOnline = online;
      _busy = false;
    });
    _snack(
      pending || users || tokens
          ? 'PC sync completed.'
          : 'PC is not reachable; local admin mode remains active.',
    );
  }

  Future<void> _verify(Map<String, dynamic> request) async {
    final name = request['name']?.toString().trim() ?? '';
    final phone = request['phone']?.toString().trim() ?? '';
    if (name.length < 2 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _snack('Invalid customer request.');
      return;
    }

    await localLanService.markPendingVerified(phone);
    if (!mounted) return;

    setState(() {
      _verified = <String, dynamic>{...request, 'status': 'verified'};
      _name.text = name;
      _phone.text = phone;
    });
    _snack('Verified. Generate Token is now unlocked.');
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    final phone = request['phone']?.toString() ?? '';
    await localLanService.removePending(phone);
    if (!mounted) return;
    if (_verified?['phone']?.toString() == phone) {
      setState(() => _verified = null);
    }
    _snack('Request removed.');
  }

  Future<void> _generate() async {
    if (!authProvider.isOwner || _verified == null) {
      _snack('Verify a pending customer first.');
      return;
    }

    try {
      final record = await LicenseService.instance.generateActivationToken(
        _plan,
        customerName: _name.text.trim(),
        phoneNumber: _phone.text.trim(),
      );
      final synced = await localLanService.syncTokensToRemote();
      await localLanService.removePending(_phone.text.trim());

      if (!mounted) return;
      setState(() {
        _last = record;
        _verified = null;
      });
      await _refresh();
      _snack(
        synced ? 'Token generated and synced.' : 'Token generated locally; PC sync can retry.',
      );
    } catch (_) {
      _snack('Could not generate token.');
    }
  }

  Future<void> _saveRemote() async {
    final link = _remote.text.trim();
    if (link.isEmpty) {
      _snack('Enter the Tailscale admin link.');
      return;
    }
    await localLanService.setRemoteAdminLink(link);
    final online = await localLanService.checkRemoteAdmin();
    if (!mounted) return;
    setState(() => _pcOnline = online);
    _snack(online ? 'PC admin connected.' : 'Link saved; PC is not reachable.');
  }

  String _time(DateTime? value) {
    if (value == null) return 'Lifetime';
    final d = value.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return dd + '/' + mm + '/' + d.year.toString() + ' ' + hh + ':' + min;
  }

  String _status(ActivationTokenRecord r) {
    if (r.isExpired) return 'Expired';
    return r.used ? 'Active' : 'Unused';
  }

  String _shareText(ActivationTokenRecord r) {
    return "LR's Sangeet_Duniya Activation\n\n" +
        'Hello ' + r.customerName + ',\n\n' +
        'Activation Token: ' + r.token + '\n' +
        'Mobile: ' + r.phoneNumber + '\n' +
        'Validity: ' + r.plan.label + '\n' +
        'Valid until: ' + _time(r.expiresAt) + '\n\n' +
        'Enter your name, phone number and this 6-digit token in the app.';
  }

  Future<void> _copy(ActivationTokenRecord r) async {
    await Clipboard.setData(ClipboardData(text: _shareText(r)));
    _snack('Activation message copied.');
  }

  Future<void> _share(ActivationTokenRecord r) async {
    await SharePlus.instance.share(
      ShareParams(subject: "LR's Sangeet_Duniya", text: _shareText(r)),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Owner Console'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _sync,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
          IconButton(
            onPressed: () async {
              await authProvider.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
          children: [
            _Hero(pcOnline: _pcOnline),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: Listenable.merge([localLanService, userRegistry]),
              builder: (_, __) => _Stats(
                pending: localLanService.pendingRequests.length,
                customers: userRegistry.totalCount,
                active: userRegistry.activeCount,
                expired: userRegistry.expiredCount,
              ),
            ),
            const SizedBox(height: 18),
            _Title('Access Requests', Icons.mark_email_unread_rounded, localLanService.pendingRequests.length),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: localLanService,
              builder: (_, __) {
                final requests = localLanService.pendingRequests;
                if (requests.isEmpty) {
                  return const _Empty(
                    icon: Icons.verified_user_rounded,
                    title: 'No pending requests',
                    subtitle: 'New customers will appear here after Request Access.',
                  );
                }
                return Column(
                  children: requests
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _Request(
                              data: r,
                              onVerify: () => _verify(r),
                              onReject: () => _reject(r),
                            ),
                          ))
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 12),
            _Title('Token Generator', Icons.key_rounded),
            const SizedBox(height: 8),
            _Generator(
              name: _name,
              phone: _phone,
              plan: _plan,
              verified: _verified != null,
              onPlanChanged: (v) => setState(() {
                if (v != null) _plan = v;
              }),
              onGenerate: _generate,
            ),
            if (_last != null) ...[
              const SizedBox(height: 12),
              _TokenCard(
                record: _last!,
                time: _time,
                onCopy: () => _copy(_last!),
                onShare: () => _share(_last!),
              ),
            ],
            const SizedBox(height: 18),
            _Title('Windows PC / Tailscale', Icons.desktop_windows_rounded),
            const SizedBox(height: 8),
            _Remote(
              controller: _remote,
              online: _pcOnline,
              onSave: _saveRemote,
              onSync: _sync,
            ),
            const SizedBox(height: 18),
            _Title('Tools', Icons.tune_rounded),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.qr_code_2_rounded, color: AppTheme.gold),
                    title: const Text('Share Application'),
                    subtitle: const Text('Android, iOS and QR distribution'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DistributionQrScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded),
                    title: const Text('Clear token preview'),
                    subtitle: const Text('Token history remains saved'),
                    onTap: () => setState(() => _last = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Title('Token History', Icons.history_rounded, _history.length),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const _Empty(
                icon: Icons.key_off_rounded,
                title: 'No activation tokens yet',
                subtitle: 'Verify a request to create the first customer token.',
              )
            else
              for (final r in _history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _History(record: r, status: _status(r), time: _time),
                ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pcOnline});
  final bool pcOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF241804), Color(0xFF090909), Color(0xFF151005)],
        ),
        border: Border.all(color: AppTheme.gold.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          ListenableBuilder(
            listenable: avatarProfileService,
            builder: (_, __) => RiveAvatarStage(
              outfit: avatarProfileService.outfit,
              pose: SangeetaPose.listening,
              size: 105,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LR's SANGEET_DUNIYA",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                const Text(
                  'OWNER / ADMIN',
                  style: TextStyle(
                    color: AppTheme.gold2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _Pill('LOCAL', true, Icons.wifi_rounded),
                    const SizedBox(width: 5),
                    _Pill(pcOnline ? 'PC ONLINE' : 'PC STANDBY', pcOnline, Icons.desktop_windows_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.active, this.icon);
  final String text;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? const Color(0x2639D38E) : const Color(0x22111111),
          border: Border.all(
            color: active
                ? const Color(0x665EE8AB)
                : Colors.white.withValues(alpha: .10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? const Color(0xFF76E6B1) : Colors.white38),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: active ? const Color(0xFFB5F6D6) : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.pending,
    required this.customers,
    required this.active,
    required this.expired,
  });
  final int pending;
  final int customers;
  final int active;
  final int expired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat('Pending', pending, Icons.pending_actions_rounded)),
        const SizedBox(width: 7),
        Expanded(child: _Stat('Users', customers, Icons.people_alt_rounded)),
        const SizedBox(width: 7),
        Expanded(child: _Stat('Active', active, Icons.verified_rounded)),
        const SizedBox(width: 7),
        Expanded(child: _Stat('Expired', expired, Icons.timer_off_rounded)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xCC101010),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.gold.withValues(alpha: .15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppTheme.gold2),
          const SizedBox(height: 5),
          Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: .52))),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.icon, [this.count]);
  final String title;
  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.gold2, size: 19),
        const SizedBox(width: 7),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.gold.withValues(alpha: .08),
              border: Border.all(color: AppTheme.gold.withValues(alpha: .26)),
            ),
            child: Text(count.toString(), style: const TextStyle(color: AppTheme.gold2, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
      ],
    );
  }
}

class _Request extends StatelessWidget {
  const _Request({required this.data, required this.onVerify, required this.onReject});
  final Map<String, dynamic> data;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final name = data['name']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final verified = data['status']?.toString() == 'verified';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF1A8), AppTheme.gold, Color(0xFF8B5200)],
                ),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(phone, style: TextStyle(color: Colors.white.withValues(alpha: .64))),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Reject',
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded),
            ),
            FilledButton(
              onPressed: verified ? null : onVerify,
              child: Text(verified ? 'Verified' : 'Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Generator extends StatelessWidget {
  const _Generator({
    required this.name,
    required this.phone,
    required this.plan,
    required this.verified,
    required this.onPlanChanged,
    required this.onGenerate,
  });
  final TextEditingController name;
  final TextEditingController phone;
  final LicensePlan plan;
  final bool verified;
  final ValueChanged<LicensePlan?> onPlanChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                Icon(verified ? Icons.lock_open_rounded : Icons.lock_rounded, color: verified ? const Color(0xFF76E6B1) : Colors.white38),
                const SizedBox(width: 8),
                Expanded(child: Text(verified ? 'Verified customer' : 'Verify request first', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                if (verified) const Text('READY', style: TextStyle(color: Color(0xFF76E6B1), fontWeight: FontWeight.w900, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              readOnly: true,
              enabled: verified,
              decoration: const InputDecoration(labelText: 'Customer name', prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: phone,
              readOnly: true,
              enabled: verified,
              decoration: const InputDecoration(labelText: 'Verified phone', prefixIcon: Icon(Icons.phone_rounded)),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<LicensePlan>(
              value: plan,
              decoration: const InputDecoration(labelText: 'Validity', prefixIcon: Icon(Icons.schedule_rounded)),
              items: LicensePlan.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(growable: false),
              onChanged: verified ? onPlanChanged : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: verified ? onGenerate : null,
                icon: const Icon(Icons.key_rounded),
                label: const Text('Generate Token'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  const _TokenCard({
    required this.record,
    required this.time,
    required this.onCopy,
    required this.onShare,
  });
  final ActivationTokenRecord record;
  final String Function(DateTime?) time;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0xFF2D1C05), Color(0xFF120D04)]),
        border: Border.all(color: AppTheme.gold.withValues(alpha: .30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF7CE9B8)),
              SizedBox(width: 7),
              Text('TOKEN READY', style: TextStyle(color: AppTheme.gold2, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SelectableText(
              record.token,
              style: const TextStyle(fontSize: 39, letterSpacing: 8, fontWeight: FontWeight.w900, color: AppTheme.gold2),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text(record.customerName + '  •  ' + record.phoneNumber, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          _Detail('Validity', record.plan.label),
          _Detail('Generated', time(record.issuedAt)),
          _Detail('Valid until', time(record.expiresAt)),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: onCopy, icon: const Icon(Icons.copy_rounded), label: const Text('Copy'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: onShare, icon: const Icon(Icons.share_rounded), label: const Text('Share'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Remote extends StatelessWidget {
  const _Remote({required this.controller, required this.online, required this.onSave, required this.onSync});
  final TextEditingController controller;
  final bool online;
  final VoidCallback onSave;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.desktop_windows_rounded, color: AppTheme.gold2),
                const SizedBox(width: 8),
                const Expanded(child: Text('PC admin connection', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                Text(online ? 'ONLINE' : 'STANDBY', style: TextStyle(color: online ? const Color(0xFF76E6B1) : Colors.white38, fontWeight: FontWeight.w900, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              'Use the existing Tailscale Serve/Funnel admin URL with its private ADMIN KEY. Keep that URL private.',
              style: TextStyle(color: Colors.white.withValues(alpha: .54), fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Tailscale PC admin link',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: onSave, icon: const Icon(Icons.save_rounded), label: const Text('Save & Test'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton.icon(onPressed: onSync, icon: const Icon(Icons.sync_rounded), label: const Text('Sync Now'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.record, required this.status, required this.time});
  final ActivationTokenRecord record;
  final String status;
  final String Function(DateTime?) time;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Expired' ? Colors.redAccent : status == 'Active' ? const Color(0xFF73E4AF) : AppTheme.gold2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(record.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 3),
            Text(record.phoneNumber),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: .24)),
                  ),
                  child: Text(record.token, style: const TextStyle(fontSize: 19, letterSpacing: 3, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 9),
                Text(record.plan.label, style: const TextStyle(color: AppTheme.gold2, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Generated ' + time(record.issuedAt) + '  •  Valid until ' + time(record.expiresAt),
              style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 82, child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .48), fontSize: 10))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10))),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppTheme.gold2),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .50), fontSize: 10, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
