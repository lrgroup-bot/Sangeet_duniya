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
    sangeetaService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sangeeta'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([sangeetaService, avatarProfileService]),
        builder: (context, _) {
          final pose = sangeetaService.isListening
              ? SangeetaPose.listening
              : sangeetaService.isSpeaking
                  ? SangeetaPose.speaking
                  : SangeetaPose.idle;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                const Text(
                  'SANGEETA • ODIA VOICE COMPANION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.gold,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sangeetaService.isListening
                      ? 'Listening…'
                      : sangeetaService.isSpeaking
                          ? 'Speaking…'
                          : 'Tap the microphone to talk',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 430,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF241806), Color(0xFF080807)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: .44),
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: RiveAvatarStage(
                    outfit: avatarProfileService.outfit,
                    pose: pose,
                    size: 365,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  sangeetaService.isListening
                      ? 'ମୁଁ ଶୁଣୁଛି…'
                      : sangeetaService.isSpeaking
                          ? 'ମୁଁ କହୁଛି…'
                          : 'ମାଇକ୍ ଦବାଇ କଥା କହନ୍ତୁ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gold2,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (sangeetaService.transcript.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        sangeetaService.transcript,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Center(
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: sangeetaService.isListening
                          ? AppTheme.gold2
                          : AppTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(24),
                    ),
                    onPressed: sangeetaService.isListening
                        ? sangeetaService.stopListening
                        : sangeetaService.startListening,
                    icon: Icon(
                      sangeetaService.isListening
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Center(
                  child: Text(
                    'Microphone is OFF until you press the button.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 17),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          'Try saying',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '“play a song” • “next song” • “previous song” • “pause music”',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
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
