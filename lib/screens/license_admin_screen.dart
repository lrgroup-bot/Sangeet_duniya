import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/auth_provider.dart';
import '../models/license_plan.dart';
import '../theme/app_theme.dart';
import '../services/license_service.dart';
import 'distribution_qr_screen.dart';

class LicenseAdminScreen extends StatefulWidget {
  const LicenseAdminScreen({super.key});

  @override
  State<LicenseAdminScreen> createState() => _LicenseAdminScreenState();
}

class _LicenseAdminScreenState extends State<LicenseAdminScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  LicensePlan plan = LicensePlan.oneYear;
  String token = '';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> generate() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter recipient name and phone number.')),
      );
      return;
    }

    final value = await authProvider.generateToken(
      plan,
      phoneNumber: phone,
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
      appBar: AppBar(title: const Text('Token Generator')),
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
                    'Create free access token',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Validity controls access duration only. No payment or billing is collected.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Recipient name',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    decoration: const InputDecoration(
                      labelText: 'Access validity',
                    ),
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: generate,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Generate token'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DistributionQrScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Open download QR'),
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
          const Text(
            'Access periods',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in LicensePlan.values)
            ListTile(
              leading: const Icon(
                Icons.verified_user_rounded,
                color: AppTheme.gold,
              ),
              title: Text(item.label),
              subtitle: const Text('Free private access period'),
            ),
        ],
      ),
    );
  }
}
