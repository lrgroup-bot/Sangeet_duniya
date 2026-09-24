import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/audio_handler.dart';
import 'theme/app_theme.dart';

late final MusicAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  audioHandler = await AudioService.init(
    builder: MusicAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lrs.sangeet_duniya.audio',
      androidNotificationChannelName: "LR's Sangeet_Duniya",
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );

  runApp(const SangeetDuniyaApp());
}

class SangeetDuniyaApp extends StatelessWidget {
  const SangeetDuniyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LR's Sangeet_Duniya",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
