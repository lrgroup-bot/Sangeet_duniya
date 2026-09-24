import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/license_plan.dart';
import '../services/auth_provider.dart';
import '../services/license_service.dart';
import '../services/local_lan_service.dart';
import '../services/user_registry_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  LicensePlan _plan = LicensePlan.thirtyDays;
  ActivationTokenRecord? _lastRecord;
  List<ActivationTokenRecord> _records = <ActivationTokenRecord>[];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    localLanService.start();
    _reloadRecords();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _reloadRecords(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _reloadRecords() async {
    final values = await LicenseService.instance.issuedTokenRecords();
    if (!mounted) return;
    setState(() {
      _records = values.reversed.toList(growable: false);
    });
  }

  bool get _validPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text.trim());

  String _formatTime(DateTime? value) {
    if (value == null) return 'Lifetime';
    final local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _status(ActivationTokenRecord record) {
    if (record.isExpired) return 'Expired';
    if (record.used) return 'Active';
    return 'Unused';
  }

  Color _statusColor(ActivationTokenRecord record) {
    if (record.isExpired) return Colors.redAccent;
    if (record.used) return const Color(0xFF66BB6A);
    return AppTheme.gold2;
  }

  Future<void> _generate() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _snack('Enter customer name.');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _snack('Enter exactly 10 digits for the mobile number.');
      return;
    }
    if (!authProvider.isOwner) {
      _snack('Owner access is required.');
      return;
    }

    try {
      final record = await LicenseService.instance.generateActivationToken(
        _plan,
        customerName: name,
        phoneNumber: phone,
      );
      await localLanService.syncTokensToRemote();

      if (!mounted) return;
      setState(() {
        _lastRecord = record;
        _records = <ActivationTokenRecord>[
          record,
          ..._records.where((item) => item.token != record.token),
        ];
      });
    } catch (error) {
      _snack(
        error is ArgumentError
            ? error.message.toString()
            : 'Could not generate token.',
      );
    }
  }

  Future<void> _copyMessage(ActivationTokenRecord record) async {
    await Clipboard.setData(ClipboardData(text: _shareText(record)));
    if (!mounted) return;
    _snack('Token message copied.');
  }

  Future<void> _share(ActivationTokenRecord record) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: "LR's Sangeet_Duniya Activation",
        text: _shareText(record),
      ),
    );
  }

  String _shareText(ActivationTokenRecord record) {
    final until =
        record.expiresAt == null ? 'Lifetime' : _formatTime(record.expiresAt);
    return "LR's Sangeet_Duniya Activation\n"
        'Hello ${record.customerName},\n\n'
        'Your Activation Token is: ${record.token}\n'
        'Mobile: ${record.phoneNumber}\n'
        'Validity: ${record.plan.label}\n'
        'Valid until: $until\n\n'
        'Open LR\'s Sangeet_Duniya and enter your name, 10-digit mobile number and this 6-digit token.';
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
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            tooltip: 'Sync with PC',
            onPressed: () async {
              final ok = await localLanService.syncTokensToRemote();
              await _reloadRecords();
              if (!mounted) return;
              _snack(ok ? 'PC sync completed.' : 'PC sync not available.');
            },
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadRecords,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Create Activation Token',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the customer name and 10-digit mobile number, '
                      'choose validity, then generate a 6-digit token.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Customer name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mobile number',
                        hintText: '10 digits',
                        prefixIcon: const Icon(Icons.phone_rounded),
                        counterText: '',
                        errorText: _phoneController.text.isEmpty ||
                                _validPhone
                            ? null
                            : 'Enter exactly 10 digits.',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<LicensePlan>(
                      initialValue: _plan,
                      decoration: const InputDecoration(
                        labelText: 'Validity',
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                      items: LicensePlan.values
                          .map(
                            (item) => DropdownMenuItem<LicensePlan>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) setState(() => _plan = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Generate Token'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_lastRecord != null) ...[
              const SizedBox(height: 14),
              _GeneratedTokenCard(
                record: _lastRecord!,
                formatTime: _formatTime,
                onCopy: () => _copyMessage(_lastRecord!),
                onShare: () => _share(_lastRecord!),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Customers',
                    value: userRegistry.totalCount.toString(),
                    icon: Icons.people_alt_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Active',
                    value: userRegistry.activeCount.toString(),
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Token History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (_records.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No activation tokens generated yet.'),
                ),
              )
            else
              for (final record in _records)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                record.customerName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              _status(record),
                              style: TextStyle(
                                color: _statusColor(record),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(record.phoneNumber),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.gold.withValues(alpha: .35),
                                ),
                              ),
                              child: Text(
                                record.token,
                                style: const TextStyle(
                                  fontSize: 24,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                record.plan.label,
                                style: const TextStyle(
                                  color: AppTheme.gold2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Generated: ${_formatTime(record.issuedAt)}\n'
                          'Valid until: ${_formatTime(record.expiresAt)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .62),
                            fontSize: 12,
                          ),
                        ),
                        if (record.activatedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Activated: ${_formatTime(record.activatedAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .62),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _GeneratedTokenCard extends StatelessWidget {
  const _GeneratedTokenCard({
    required this.record,
    required this.formatTime,
    required this.onCopy,
    required this.onShare,
  });

  final ActivationTokenRecord record;
  final String Function(DateTime?) formatTime;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generated Token',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                record.token,
                style: const TextStyle(
                  fontSize: 38,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.gold2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${record.customerName} • ${record.phoneNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .70),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Detail('Validity', record.plan.label),
            _Detail('Generated', formatTime(record.issuedAt)),
            _Detail('Valid until', formatTime(record.expiresAt)),
            _Detail('Status', record.used ? 'Active' : 'Unused'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .58),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.gold, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
