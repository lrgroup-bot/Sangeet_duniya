import 'package:flutter/material.dart';

import '../services/avatar_profile_service.dart';
import '../services/sangeeta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import 'settings_screen.dart';

class SangeetaScreen extends StatefulWidget {
  const SangeetaScreen({super.key});

  @override
  State<SangeetaScreen> createState() => _SangeetaScreenState();
}

class _SangeetaScreenState extends State<SangeetaScreen> {
  @override
  void initState() {
    super.initState();
    sangeetaService.init().then((_) {
      if (!mounted || !sangeetaService.continuousWakeMode) return;
      sangeetaService.startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sangeeta'),
        actions: [
          IconButton(
            tooltip: 'Avatar & voice settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: sangeetaService,
        builder: (context, _) {
          final pose = sangeetaService.isListening
              ? SangeetaPose.listening
              : sangeetaService.isSpeaking
                  ? SangeetaPose.speaking
                  : SangeetaPose.greeting;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                const Text(
                  'SANGEETA • VOICE COMPANION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.gold,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No chat box. Just speak naturally.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: avatarProfileService,
                  builder: (context, _) => Container(
                    height: 430,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF261A08), Color(0xFF080807)],
                      ),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: .55),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: .12),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.bottomCenter,
                    child: RiveAvatarStage(
                      outfit: avatarProfileService.outfit,
                      pose: pose,
                      size: 360,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  sangeetaService.isListening
                      ? 'I am listening…'
                      : sangeetaService.isSpeaking
                          ? 'I am speaking…'
                          : 'Say “Hey Sangeeta”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gold2,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Wake phrases',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hey Sangeeta  •  Hi Sangeeta  •  Hey Dhana\n'
                          'Sweetheart  •  Hey Sweetheart',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: sangeetaService.isListening
                          ? AppTheme.gold2
                          : AppTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(22),
                    ),
                    onPressed: () => sangeetaService.setWakeMode(
                      !sangeetaService.continuousWakeMode,
                    ),
                    icon: Icon(
                      sangeetaService.isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    sangeetaService.continuousWakeMode
                        ? 'Voice wake mode ON'
                        : 'Voice wake mode OFF',
                    style: TextStyle(
                      color: sangeetaService.continuousWakeMode
                          ? AppTheme.gold
                          : Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
