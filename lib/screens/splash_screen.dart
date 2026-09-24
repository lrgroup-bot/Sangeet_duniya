import 'dart:async';

import 'package:flutter/material.dart';

import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sangeeta_logo.dart';
import 'shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    PermissionService.instance.requestNotifications();
    _timer = Timer(const Duration(milliseconds: 1800), _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ShellScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: .9,
            colors: [Color(0xFF2B1A05), AppTheme.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SangeetaLogo(size: 300, showTagline: false),
              const SizedBox(height: 10),
              Text(
                "LR's Sangeet_Duniya",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.gold2,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your music. Your world. Powered by Sangeeta.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: .65),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
