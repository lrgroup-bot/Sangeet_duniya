import 'package:flutter/material.dart';

import '../services/auth_provider.dart';
import 'activation_screen.dart';
import 'shell_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authProvider,
      builder: (context, _) {
        if (!authProvider.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Owner devices enter the real music app just like activated users.
        // The admin console remains available from Home -> Owner Console.
        return authProvider.isActivated
            ? const ShellScreen()
            : const ActivationScreen();
      },
    );
  }
}
