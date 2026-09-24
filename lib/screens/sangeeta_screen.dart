import 'package:flutter/material.dart';

import '../services/sangeeta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sangeeta_logo.dart';
import 'settings_screen.dart';

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
    sangeetaService.init().then((_) {
      if (mounted && sangeetaService.continuousWakeMode) {
        sangeetaService.startListening();
      }
    });
  }

  @override
  void dispose() {
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
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wake phrases',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hey Sangeeta • Hi Sangeeta • Hello Sangeeta\n'
                          'Hey Sweetheart • Hi Baby • Hello Darling',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              sangeetaService.isListening
                                  ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              color: sangeetaService.isListening
                                  ? AppTheme.gold
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sangeetaService.isListening
                                    ? 'Listening in foreground…'
                                    : 'Tap the microphone to listen.',
                                style: TextStyle(
                                  color: sangeetaService.isListening
                                      ? AppTheme.gold
                                      : Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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
                    onPressed: () {
                      sangeetaService.setWakeMode(
                        !sangeetaService.continuousWakeMode,
                      );
                    },
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
