import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/license_plan.dart';
import '../theme/app_theme.dart';

class LicenseAdminScreen extends StatefulWidget {
  const LicenseAdminScreen({super.key});

  @override
  State<LicenseAdminScreen> createState() => _LicenseAdminScreenState();
}

class _LicenseAdminScreenState extends State<LicenseAdminScreen> {
  final phoneController = TextEditingController();
  LicensePlan plan = LicensePlan.oneYear;
  String token = '';

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> generate() async {
    final value = await authProvider.generateToken(
      plan,
      phoneNumber: phoneController.text,
    );
    if (!mounted) return;
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner mode is required.')),
      );
      return;
    }
    setState(() => token = value);
  }

  Future<void> copy() async {
    if (token.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Manager')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate activation token',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add the recipient phone number, choose validity, then share the token.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Recipient phone number',
                      hintText: '+91XXXXXXXXXX',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<LicensePlan>(
                    initialValue: plan,
                    decoration: const InputDecoration(labelText: 'Validity'),
                    items: LicensePlan.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => plan = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '365 Days: ₹100 / year',
                    style: TextStyle(
                      color: AppTheme.gold2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: generate,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Generate token'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (token.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generated token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      token,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: copy,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy token'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          for (final item in LicensePlan.values)
            ListTile(
              leading: const Icon(
                Icons.verified_user_rounded,
                color: AppTheme.gold,
              ),
              title: Text(item.label),
              subtitle: Text(
                item == LicensePlan.oneYear
                    ? 'Private-use annual option • ₹100'
                    : 'Token validity: ' + item.label,
              ),
            ),
        ],
      ),
    );
  }
}
