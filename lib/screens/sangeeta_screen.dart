import 'package:flutter/material.dart';

import '../models/sangeeta_personality.dart';
import '../services/avatar_profile_service.dart';
import '../services/sangeeta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import '../widgets/sangeeta_logo.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'wardrobe_screen.dart';

class SangeetaScreen extends StatefulWidget {
  const SangeetaScreen({super.key});

  @override
  State<SangeetaScreen> createState() => _SangeetaScreenState();
}

class _SangeetaScreenState extends State<SangeetaScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    sangeetaService.attachRouteHandler(_handleRoute);
    sangeetaService.init().then((_) {
      if (mounted && sangeetaService.continuousWakeMode) {
        sangeetaService.startListening();
      }
    });
  }

  void _handleRoute(SangeetaRoute route, String argument) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (route) {
        case SangeetaRoute.playlists:
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LibraryScreen(initialSection: 3),
            ),
          );
          break;
        case SangeetaRoute.search:
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SearchScreen(initialQuery: argument),
            ),
          );
      }
    });
  }

  @override
  void dispose() {
    sangeetaService.detachRouteHandler();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    _controller.clear();
    await sangeetaService.handleText(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sangeeta'),
        actions: [
          IconButton(
            tooltip: 'Wardrobe',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WardrobeScreen(),
              ),
            ),
            icon: const Icon(Icons.checkroom_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
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
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                const Center(
                  child: SangeetaLogo(size: 185, showTagline: false),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    sangeetaService.personality.label + ' Mode',
                    style: const TextStyle(
                      color: AppTheme.gold2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListenableBuilder(
                  listenable: avatarProfileService,
                  builder: (context, _) {
                    final pose = sangeetaService.isSpeaking
                        ? SangeetaPose.speaking
                        : sangeetaService.isListening
                            ? SangeetaPose.listening
                            : SangeetaPose.greeting;
                    return Container(
                      height: 255,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF241507), Color(0xFF090807)],
                        ),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: .45),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          RiveAvatarStage(
                            outfit: avatarProfileService.outfit,
                            pose: pose,
                            speechMouthOpen: sangeetaService.isSpeaking
                                ? sangeetaService.speechMouthOpen
                                : null,
                            speechMouthWidth: sangeetaService.isSpeaking
                                ? sangeetaService.speechMouthWidth
                                : null,
                            speechMouthRoundness: sangeetaService.isSpeaking
                                ? sangeetaService.speechMouthRoundness
                                : null,
                            size: 230,
                          ),
                          Positioned(
                            left: 18,
                            bottom: 14,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .55),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                child: Text(
                                  sangeetaService.isSpeaking
                                      ? (sangeetaService.speakingWord.isEmpty
                                          ? 'Sangeeta is speaking…'
                                          : 'Speaking • ${sangeetaService.speakingWord}')
                                      : sangeetaService.isListening
                                          ? 'Waiting for “Hey Sangeeta”…'
                                          : 'Sangeeta • Ready',
                                  style: const TextStyle(
                                    color: AppTheme.gold2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wake word',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Say “Hey Sangeeta” before a voice command. Typed commands do not require the wake word.',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Play • Pause • Resume • Next • Previous • Volume Up/Down • Open Playlist • Download Song • Search Song',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (sangeetaService.transcript.isNotEmpty)
                  _Bubble(title: 'You', text: sangeetaService.transcript),
                const SizedBox(height: 10),
                _Bubble(title: 'Sangeeta', text: sangeetaService.reply),
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask Sangeeta to play a song…',
                    suffixIcon: IconButton(
                      tooltip: 'Send',
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(20),
                    ),
                    onPressed: () => sangeetaService.setWakeMode(
                      !sangeetaService.continuousWakeMode,
                    ),
                    icon: Icon(
                      sangeetaService.isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    sangeetaService.continuousWakeMode
                        ? 'Wake mode ON'
                        : 'Wake mode OFF',
                    style: TextStyle(
                      color: sangeetaService.continuousWakeMode
                          ? AppTheme.gold
                          : Colors.white54,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151515),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(text),
          ],
        ),
      ),
    );
  }
}
