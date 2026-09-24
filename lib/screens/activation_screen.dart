import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_provider.dart';
import '../services/avatar_profile_service.dart';
import '../services/local_lan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _busy = false;
  String? _message;
  bool _success = false;

  bool get _validPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text.trim());

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final token = _tokenController.text.trim();

    if (!_validPhone) {
      _showMessage('Enter a valid 10-digit mobile number.', false);
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final ok = await authProvider.loginWithCredentials(
      name: name.isEmpty ? 'Owner' : name,
      phoneNumber: phone,
      tokenId: token,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      _showMessage(
        'Login failed. Check your name, phone number and 6-digit token.',
        false,
      );
    }
  }

  Future<void> _requestAccess() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      _showMessage('Enter your full name.', false);
      return;
    }
    if (!_validPhone) {
      _showMessage('Enter a valid 10-digit mobile number.', false);
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final ok = await localLanService.requestAccess(
      name: name,
      phoneNumber: phone,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      _showMessage(
        'Access request sent. Your name and phone are now waiting for admin verification.',
        true,
      );
    } else {
      _showMessage(
        'Could not reach the administrator. Same-Wi-Fi discovery or the configured Tailscale PC path is required.',
        false,
      );
    }
  }

  void _showMessage(String message, bool success) {
    setState(() {
      _message = message;
      _success = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050505),
              Color(0xFF171005),
              Color(0xFF050505),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Column(
                    children: [
                      _BrandHeader(),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: avatarProfileService,
                        builder: (context, _) => RiveAvatarStage(
                          outfit: avatarProfileService.outfit,
                          pose: SangeetaPose.listening,
                          size: 190,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ONE LOGIN • ADMIN + USER',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.gold2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your access is verified from the phone and token you enter.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .62),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Admin: phone + admin token. User: name + phone + generated token.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .58),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                hintText: 'Enter your name',
                                prefixIcon: Icon(Icons.person_rounded),
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
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Phone number',
                                hintText: '10-digit mobile number',
                                prefixIcon: const Icon(Icons.phone_rounded),
                                counterText: '',
                                errorText: _phoneController.text.isEmpty ||
                                        _validPhone
                                    ? null
                                    : 'Enter exactly 10 digits.',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _tokenController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Token ID',
                                hintText: '6-digit token',
                                prefixIcon: Icon(Icons.vpn_key_rounded),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _busy ? null : _login,
                                icon: _busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.login_rounded),
                                label: Text(_busy ? 'Checking…' : 'Continue'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _requestAccess,
                                icon: const Icon(
                                  Icons.mark_email_unread_rounded,
                                ),
                                label: const Text('Request Access'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        _MessageBanner(
                          message: _message!,
                          success: _success,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Admin verification keeps the customer name and phone bound to the generated token.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .45),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF1A8), AppTheme.gold, Color(0xFF8B5200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: .22),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.headphones_rounded,
            color: Colors.black,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LR's",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.gold2,
              ),
            ),
            Text(
              'SANGEET_DUNIYA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB8111111),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.gold.withValues(alpha: .20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .38),
            blurRadius: 36,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: .07),
            blurRadius: 26,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.success,
  });

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final icon = success ? Icons.check_circle_rounded : Icons.info_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: success
            ? const Color(0x3326C281)
            : const Color(0x33FFB03A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: success
              ? const Color(0x6649D39B)
              : AppTheme.gold.withValues(alpha: .35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: success ? const Color(0xFF77E4B8) : AppTheme.gold2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
