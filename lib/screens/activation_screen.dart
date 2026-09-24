import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/app_theme.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final tokenController = TextEditingController();
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    tokenController.dispose();
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> activate() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });

    final ok = await authProvider.activateWithToken(
      tokenController.text,
      phoneNumber: phoneController.text,
    );

    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) {
      setState(() => error = 'Invalid token, phone number, or expiry.');
    }
  }

  Future<void> owner() async {
    FocusScope.of(context).unfocus();
    final ok = await authProvider.unlockOwnerMode(pinController.text);
    if (!mounted) return;
    if (!ok) setState(() => error = 'Owner PIN is incorrect.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Icon(
                    Icons.headphones_rounded,
                    size: 72,
                    color: AppTheme.gold,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "LR's Sangeet_Duniya",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Private activation',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phone number',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '+91XXXXXXXXXX',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Activation token',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: tokenController,
                            minLines: 3,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'LRS1....',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : activate,
                              icon: const Icon(Icons.verified_rounded),
                              label: Text(
                                busy ? 'Checking…' : 'Activate app',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppTheme.gold.withValues(alpha: .10),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: .35),
                              ),
                            ),
                            child: const Text(
                              'Annual plan: ₹100 / year • Ultimate: Lifetime',
                              style: TextStyle(
                                color: AppTheme.gold2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ExpansionTile(
                      title: const Text('Owner / Token generator'),
                      subtitle: const Text(
                        'Use on your administrator phone only',
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      children: [
                        TextField(
                          controller: pinController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Owner PIN',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: owner,
                            icon: const Icon(
                              Icons.admin_panel_settings_rounded,
                            ),
                            label: const Text('Unlock owner mode'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Tokens carry their own validity: 7 days, 30 days, 365 days, or Ultimate.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Personal-use licensing only. This offline gate is not tamper-proof commercial DRM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
