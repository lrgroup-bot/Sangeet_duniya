import 'dart:async';

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Timer? _ownerTapTimer;
  int _ownerTapCount = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ownerTapTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  bool get _validPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text.trim());

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      setState(() => _error = 'Enter your full name.');
      return;
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = 'Enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _error = null;
      _busy = false;
    });

    final token = await _showTokenDialog();
    if (!mounted || token == null) return;

    setState(() => _busy = true);

    final record = await localLanService.activateToken(
      name: name,
      phoneNumber: phone,
      token: token,
    );

    if (!mounted) return;

    if (record == null) {
      setState(() {
        _busy = false;
        _error =
            'Activation failed. Check the 6-digit token and make sure the admin device or configured PC server is reachable.';
      });
      return;
    }

    final activated = await authProvider.activateFromRecord(
      record,
      phoneNumber: phone,
      name: name,
    );

    if (!mounted) return;

    setState(() => _busy = false);

    if (!activated) {
      setState(() => _error = 'Could not save the activation on this phone.');
      return;
    }

    await _showSuccessDialog(record);
  }

  Future<String?> _showTokenDialog() async {
    final controller = TextEditingController();
    String? error;
    bool submitting = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final value = controller.text.trim();
              if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                setDialogState(
                  () => error = 'Enter the 6-digit activation token.',
                );
                return;
              }

              setDialogState(() {
                submitting = true;
                error = null;
              });

              Navigator.of(dialogContext).pop(value);
            }

            return AlertDialog(
              title: const Text('Activation Token'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the 6-digit token shared with you.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 30,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w900,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Activation Token',
                      hintText: '000000',
                      errorText: error,
                    ),
                    onSubmitted: (_) {
                      if (!submitting) submit();
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Activate'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _showSuccessDialog(dynamic record) async {
    final expires = record.expiresAt as DateTime?;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppTheme.gold),
              SizedBox(width: 8),
              Text('Activation Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to LR's Sangeet_Duniya",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              _InfoRow('Validity', record.plan.label),
              _InfoRow('Activated', _formatDateTime(record.activatedAt)),
              _InfoRow(
                'Valid until',
                expires == null ? 'Lifetime' : _formatDateTime(expires),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Enter App'),
            ),
          ],
        );
      },
    );
  }

  void _handleHiddenOwnerTap() {
    _ownerTapCount += 1;
    _ownerTapTimer?.cancel();
    _ownerTapTimer = Timer(const Duration(seconds: 3), () {
      _ownerTapCount = 0;
    });

    if (_ownerTapCount >= 7) {
      _ownerTapCount = 0;
      _showOwnerDialog();
    }
  }

  Future<void> _showOwnerDialog() async {
    final controller = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> unlock() async {
              final ok = await authProvider.unlockOwnerMode(controller.text);
              if (!mounted) return;

              if (ok) {
                Navigator.of(dialogContext).pop();
              } else {
                setDialogState(() => error = 'Incorrect owner PIN.');
              }
            }

            return AlertDialog(
              title: const Text('Owner Access'),
              content: TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: 'Owner PIN',
                  errorText: error,
                ),
                onSubmitted: (_) => unlock(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: unlock,
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _handleHiddenOwnerTap,
                    onLongPress: _showOwnerDialog,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.gold.withValues(alpha: .08),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: .25),
                        ),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        size: 66,
                        color: AppTheme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "LR's Sangeet_Duniya",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your details to continue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .65),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Enter full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Mobile number',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: '10-digit mobile number',
                              prefixIcon: const Icon(Icons.phone_rounded),
                              counterText: '',
                              errorText: _phoneController.text.isEmpty ||
                                      _validPhone
                                  ? null
                                  : 'Enter exactly 10 digits.',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _continue,
                              icon: _busy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                _busy ? 'Activating…' : 'Continue',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'An activation token from the administrator is required.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .60),
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
