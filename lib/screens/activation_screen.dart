import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_provider.dart';
import '../services/local_lan_service.dart';
import '../theme/app_theme.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final nameController = TextEditingController(text: authProvider.userName);
  final phoneController =
      TextEditingController(text: authProvider.phoneNumber);
  final serverController =
      TextEditingController(text: localLanService.serverUrl);
  final codeController = TextEditingController();

  bool busy = false;
  String? error;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    serverController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> _submitActivation() async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });

    final ok = await authProvider.activateWithCode(
      codeController.text,
      phoneNumber: phoneController.text,
      name: nameController.text,
      serverUrl: serverController.text,
    );

    if (!mounted) return;
    setState(() {
      busy = false;
      if (!ok) {
        error =
            'Activation failed. Check the 6-digit code and the Windows PC admin server address, then make sure this phone can reach it by Wi-Fi or Tailscale.';
      }
    });
  }

  Future<void> _testServer() async {
    FocusScope.of(context).unfocus();
    final ok = await localLanService.checkHealth(serverController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Windows PC admin server is reachable.'
            : 'Could not reach the Windows PC admin server.'),
      ),
    );
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
                    "LR's Sangeet_Duniya v2.2",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Windows PC activation • Local first',
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
                            'Your name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Enter your name',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Mobile number',
                            style: TextStyle(
                              fontSize: 18,
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
                            'Windows PC admin server',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: serverController,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText:
                                  '192.168.1.10:40425 or 100.x.x.x:40425',
                              helperText:
                                  'Use same-Wi-Fi IP or the PC Tailscale IP.',
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: busy ? null : _testServer,
                            icon: const Icon(Icons.lan_rounded),
                            label: const Text('Test PC connection'),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '6-digit activation code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: const InputDecoration(
                              hintText: '000000',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : _submitActivation,
                              icon: const Icon(Icons.verified_user_rounded),
                              label: Text(
                                busy ? 'Activating…' : 'Activate this device',
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Validity options are 7 / 14 / 30 / 90 / 180 / 365 days or Lifetime. The PC is the source of truth; the phone caches a valid lease so music still works when the PC is temporarily offline.',
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
