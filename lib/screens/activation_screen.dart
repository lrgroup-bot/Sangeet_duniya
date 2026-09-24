import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_provider.dart';
import '../services/local_lan_service.dart';
import '../theme/app_theme.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final nameController = TextEditingController();
  final tokenController = TextEditingController();
  final phoneController = TextEditingController(
    text: authProvider.phoneNumber,
  );
  final adminLinkController = TextEditingController(
    text: localLanService.savedAdminLink,
  );
  final pinController = TextEditingController();

  bool busy = false;
  String? error;

  @override
  void dispose() {
    nameController.dispose();
    tokenController.dispose();
    phoneController.dispose();
    adminLinkController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> activate() async {
    FocusScope.of(context).unfocus();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final token = tokenController.text.trim();
    final adminLink = adminLinkController.text.trim();

    if (name.isEmpty || phone.length < 7 || token.isEmpty) {
      setState(() => error = 'Enter your name, phone number and token.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });

    var registered = false;
    if (adminLink.isNotEmpty) {
      registered = await localLanService.registerUser(
        adminLink: adminLink,
        name: name,
        phoneNumber: phone,
        token: token,
      );
    }

    final ok = await authProvider.activateWithToken(
      token,
      phoneNumber: phone,
      name: name,
    );

    if (!mounted) return;

    setState(() => busy = false);

    if (!ok) {
      setState(() {
        error = adminLink.isEmpty
            ? 'Token validation failed or the token has expired.'
            : registered
                ? 'Token validation failed or the token has expired.'
                : 'Could not contact the admin phone. You can still use this token when the admin has manually added you.';
      });
    }
  }

  Future<void> owner() async {
    FocusScope.of(context).unfocus();
    final ok = await authProvider.unlockOwnerMode(pinController.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => error = 'Owner PIN is incorrect.');
    }
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Private Wi-Fi signup',
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
                              fontSize: 19,
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
                            'Admin Wi-Fi link',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: adminLinkController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              hintText:
                                  'http://192.168.x.x:40425/connect?key=...',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Optional: same Wi-Fi lets this signup appear automatically on the admin dashboard. If you are not on Wi-Fi, the admin can add you manually against the token.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .60),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Token ID',
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
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: busy ? null : activate,
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: Text(
                                busy ? 'Signing up…' : 'Sign up & enter app',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No cloud, no payment, no subscription. Signup is sent directly from this phone to the administrator phone over the same Wi-Fi.',
                            style: TextStyle(
                              color: AppTheme.gold2,
                              fontWeight: FontWeight.w800,
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
                        'Use on the administrator phone only',
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(18, 0, 18, 18),
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
                    'Access validity comes from the token: 7 days, 30 days, 365 days, or Ultimate Lifetime.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When the token expires, the app automatically returns to this signup page.',
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
