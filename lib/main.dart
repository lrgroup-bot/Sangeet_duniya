import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/audio_handler.dart';
import 'services/avatar_profile_service.dart';
import 'services/auth_provider.dart';
import 'services/library_store.dart';
import 'services/equalizer_profile_service.dart';
import 'services/local_lan_service.dart';
import 'services/distribution_service.dart';
import 'services/user_registry_service.dart';
import 'theme/app_theme.dart';

late final MusicAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (_) {}

  try {
    audioHandler = await AudioService.init(
      builder: MusicAudioHandler.new,
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.lrs.sangeet_duniya.audio',
        androidNotificationChannelName: "LR's Sangeet_Duniya",
        androidNotificationChannelDescription: 'Music playback controls',
        androidNotificationIcon: 'drawable/ic_stat_sangeet',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
        androidResumeOnClick: true,
        androidNotificationClickStartsActivity: true,
        notificationColor: AppTheme.gold,
        preloadArtwork: true,
        artDownscaleWidth: 256,
        artDownscaleHeight: 256,
      ),
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'audio_service startup',
      ),
    );
    audioHandler = MusicAudioHandler();
  }

  await libraryStore.load();
  await equalizerProfileService.load();
  await avatarProfileService.load();
  await userRegistry.load();
  await distributionService.load();
  await localLanService.load();
  await authProvider.initialize();

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
