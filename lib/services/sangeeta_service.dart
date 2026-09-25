import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/demo_songs.dart';
import '../main.dart';
import '../models/sangeeta_personality.dart';
import '../models/song.dart';
import 'download_service.dart';
import 'library_store.dart';
import 'music_catalog_service.dart';
import 'permission_service.dart';
import 'sangeeta_command_parser.dart';
import 'sangeeta_lip_sync.dart';

enum SangeetaRoute { playlists, search }

typedef SangeetaRouteHandler = void Function(
  SangeetaRoute route,
  String argument,
);

class SangeetaService extends ChangeNotifier {
  static const _personalityKey = 'sangeeta_personality';
  static const _languageKey = 'sangeeta_language';

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final SangeetaCommandParser _parser = const SangeetaCommandParser();

  bool _initialized = false;
  bool _busySpeaking = false;
  SangeetaRouteHandler? _routeHandler;

  bool isListening = false;
  bool continuousWakeMode = true;
  bool get isSpeaking => _busySpeaking;

  SangeetaLipShape lipShape = SangeetaLipShape.rest;
  String speakingWord = '';
  double get speechMouthOpen => lipShape.open;
  double get speechMouthWidth => lipShape.width;
  double get speechMouthRoundness => lipShape.roundness;

  String transcript = '';
  String reply = 'ହାଇ… ମୁଁ Sangeeta। “Hey Sangeeta” କହି ଆରମ୍ଭ କର। 💛';

  List<LocaleName> locales = const <LocaleName>[];
  String languageCode = 'or-IN';
  SangeetaPersonality personality = SangeetaPersonality.sweetheart;

  void attachRouteHandler(SangeetaRouteHandler handler) {
    _routeHandler = handler;
  }

  void detachRouteHandler() {
    _routeHandler = null;
  }

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedPersonality = prefs.getString(_personalityKey);
    final savedLanguage = prefs.getString(_languageKey);

    if (savedPersonality != null) {
      personality = SangeetaPersonality.values.firstWhere(
        (value) => value.name == savedPersonality,
        orElse: () => SangeetaPersonality.sweetheart,
      );
    }
    if (savedLanguage != null) languageCode = savedLanguage;

    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.02);
    await _tts.awaitSpeakCompletion(true);
    _tts.setProgressHandler(
      (String text, int startOffset, int endOffset, String word) {
        if (!_busySpeaking) return;
        speakingWord = word;
        lipShape = SangeetaLipSync.fromWord(word);
        notifyListeners();
      },
    );

    try {
      await _tts.setLanguage(languageCode);
    } catch (_) {
      languageCode = 'en-IN';
      try {
        await _tts.setLanguage(languageCode);
      } catch (_) {}
    }

    _initialized = await _speech.initialize(
      onStatus: _onStatus,
      onError: (_) {
        isListening = false;
        notifyListeners();
      },
    );

    if (_initialized) {
      locales = await _speech.locales();
      languageCode = _pickAvailableLocale(languageCode);
      try {
        await _tts.setLanguage(languageCode);
      } catch (_) {}
    }

    notifyListeners();
  }

  String _pickAvailableLocale(String requested) {
    final exact = locales.where((locale) => locale.localeId == requested);
    if (exact.isNotEmpty) return exact.first.localeId;

    final prefix = requested.toLowerCase().split('-').first;
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith(prefix)) {
        return locale.localeId;
      }
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('en')) {
        return locale.localeId;
      }
    }
    return locales.isEmpty ? requested : locales.first.localeId;
  }

  Future<void> startListening() async {
    await init();
    if (_speech.isListening || _busySpeaking) return;

    final micGranted = await PermissionService.instance.requestMicrophone();
    if (!micGranted || !_initialized) return;

    transcript = '';
    isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 30),
        localeId: languageCode,
        enableHapticFeedback: true,
      ),
    );
  }

  Future<void> stopListening() async {
    continuousWakeMode = false;
    await _speech.stop();
    isListening = false;
    notifyListeners();
  }

  Future<void> setWakeMode(bool enabled) async {
    continuousWakeMode = enabled;
    notifyListeners();
    if (enabled) {
      await startListening();
    } else {
      await _speech.stop();
      isListening = false;
      notifyListeners();
    }
  }

  Future<void> handleText(
    String text, {
    bool requireWakeWord = false,
  }) async {
    final command = text.trim();
    if (command.isEmpty) return;

    transcript = command;
    notifyListeners();

    final parsed = _parser.parse(
      command,
      requireWakeWord: requireWakeWord,
    );
    if (!parsed.accepted) return;

    switch (parsed.kind) {
      case SangeetaCommandKind.wakeOnly:
        await _speak(
          _localized(
            'ହଁ, କହ। ମୁଁ ଶୁଣୁଛି।',
            'हाँ, बोलिए। मैं सुन रही हूँ।',
            'Yes, I am listening.',
          ),
        );
        break;
      case SangeetaCommandKind.pause:
        await audioHandler.pause();
        await _speak(_localized('ଗୀତ ପାଉଜ୍ କରିଦେଲି।', 'संगीत रोक दिया।', 'Music paused.'));
        break;
      case SangeetaCommandKind.resume:
        await audioHandler.play();
        await _speak(_localized('ପୁଣି ଗୀତ ଚଳାଇଦେଲି।', 'संगीत फिर चला दिया।', 'Music resumed.'));
        break;
      case SangeetaCommandKind.next:
        await audioHandler.skipToNext();
        await _speak(_localized('ପରବର୍ତ୍ତୀ ଗୀତ ଚଳାଉଛି।', 'अगला गाना चला रही हूँ।', 'Playing the next song.'));
        break;
      case SangeetaCommandKind.previous:
        await audioHandler.skipToPrevious();
        await _speak(_localized('ପୂର୍ବ ଗୀତକୁ ଫେରିଲି।', 'पिछला गाना चला रही हूँ।', 'Playing the previous song.'));
        break;
      case SangeetaCommandKind.volumeUp:
        await audioHandler.adjustVolume(.10);
        await _speak(_localized('ଭଲ୍ୟୁମ୍ ବଢ଼ାଇଦେଲି।', 'वॉल्यूम बढ़ा दिया।', 'Volume increased.'));
        break;
      case SangeetaCommandKind.volumeDown:
        await audioHandler.adjustVolume(-.10);
        await _speak(_localized('ଭଲ୍ୟୁମ୍ କମାଇଦେଲି।', 'वॉल्यूम कम कर दिया।', 'Volume decreased.'));
        break;
      case SangeetaCommandKind.openPlaylist:
        _routeHandler?.call(SangeetaRoute.playlists, '');
        await _speak(_localized('ପ୍ଲେଲିଷ୍ଟ ଖୋଲୁଛି।', 'प्लेलिस्ट खोल रही हूँ।', 'Opening playlists.'));
        break;
      case SangeetaCommandKind.searchSong:
        _routeHandler?.call(SangeetaRoute.search, parsed.argument);
        await _speak(
          parsed.argument.isEmpty
              ? _localized('ସର୍ଚ୍ଚ ଖୋଲୁଛି।', 'सर्च खोल रही हूँ।', 'Opening search.')
              : _localized('ଗୀତ ଖୋଜୁଛି।', 'गाना खोज रही हूँ।', 'Searching for that song.'),
        );
        break;
      case SangeetaCommandKind.downloadSong:
        await _downloadCurrentSong();
        break;
      case SangeetaCommandKind.playSong:
        if (parsed.argument.isEmpty) {
          await audioHandler.play();
          await _speak(_localized('ଗୀତ ଚଳାଉଛି।', 'संगीत चला रही हूँ।', 'Playing music.'));
        } else {
          await _playQuery(parsed.argument);
        }
        break;
      case SangeetaCommandKind.dance:
        await _speak(_localized('Dance mode ready. 💃', 'Dance mode तैयार है। 💃', 'Dance mode is ready. 💃'));
        break;
      case SangeetaCommandKind.identity:
        await _speak(
          _localized(
            'ମୁଁ Sangeeta, ତୁମର music companion।',
            'मैं Sangeeta हूँ, आपकी music companion।',
            'I am Sangeeta, your music companion.',
          ),
        );
        break;
      case SangeetaCommandKind.unknown:
        await _speak(
          _localized(
            'Play, pause, next, previous, volume, playlist, download କିମ୍ବା search କହ।',
            'Play, pause, next, previous, volume, playlist, download या search बोलिए।',
            'Say play, pause, next, previous, volume, playlist, download, or search.',
          ),
        );
    }
  }

  Future<void> _playQuery(String query) async {
    final found = await _findSong(query);
    if (found == null) {
      await _speak(
        _localized(
          'ସେଇ ଗୀତଟା ମିଳିଲା ନାହିଁ।',
          'वह गाना नहीं मिला।',
          'I could not find that song.',
        ),
      );
      return;
    }

    final song = found.$1;
    await audioHandler.playSong(song, songs: found.$2);
    await _speak(
      _localized(
        '"' + song.title + '" ଚଳାଉଛି।',
        '"' + song.title + '" चला रही हूँ।',
        'Playing "' + song.title + '".',
      ),
    );
  }

  Future<void> _downloadCurrentSong() async {
    final item = audioHandler.mediaItem.value;
    if (item == null) {
      await _speak(_localized('ପ୍ରଥମେ ଗୀତ ଚଳାଅ।', 'पहले कोई गाना चलाइए।', 'Play a song first.'));
      return;
    }
    final song = libraryStore.songById(item.id);
    if (song == null || !song.isDownloadable) {
      await _speak(
        _localized(
          'ଏହି source download କୁ ଅନୁମତି ଦେଉନାହିଁ।',
          'यह source डाउनलोड की अनुमति नहीं देता।',
          'This source does not allow downloading this track.',
        ),
      );
      return;
    }
    try {
      await DownloadService.instance.download(song);
      await _speak(_localized('ଗୀତ offline save ହେଲା।', 'गाना offline save हो गया।', 'Song saved for offline playback.'));
    } catch (_) {
      await _speak(_localized('Download ହୋଇପାରିଲା ନାହିଁ।', 'डाउनलोड नहीं हो सका।', 'The download failed.'));
    }
  }

  Future<(Song, List<Song>)?> _findSong(String query) async {
    try {
      final online = await musicCatalogService.search(query, limit: 12);
      if (online.isNotEmpty) return (online.first, online);
    } catch (_) {}

    final normalized = query.toLowerCase();
    for (final song in demoSongs) {
      if (song.title.toLowerCase().contains(normalized) ||
          song.artist.toLowerCase().contains(normalized) ||
          song.category.toLowerCase().contains(normalized)) {
        return (song, demoSongs);
      }
    }
    return null;
  }

  String _localized(String odia, String hindi, String english) {
    final code = languageCode.toLowerCase();
    final base = code.startsWith('hi')
        ? hindi
        : code.startsWith('en')
            ? english
            : odia;
    return _replyFor(base);
  }

  String _replyFor(String text) {
    switch (personality) {
      case SangeetaPersonality.sweetheart:
        return text + ' 💛';
      case SangeetaPersonality.friendly:
        return text;
      case SangeetaPersonality.funny:
        return text + ' 😄';
      case SangeetaPersonality.musicExpert:
        return text;
    }
  }

  Future<void> _speak(String text) async {
    reply = text;
    _busySpeaking = true;
    speakingWord = '';
    lipShape = SangeetaLipShape.soft;
    notifyListeners();

    try {
      await _speech.stop();
      isListening = false;
      await _tts.stop();
      await _tts.setLanguage(languageCode);
      await _tts.speak(text);
    } catch (_) {
      // Keep text commands working even when the device has no matching TTS voice.
    } finally {
      _busySpeaking = false;
      speakingWord = '';
      lipShape = SangeetaLipShape.rest;
      notifyListeners();
    }

    if (continuousWakeMode) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!isListening) unawaited(startListening());
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    transcript = result.recognizedWords;
    notifyListeners();

    if (result.finalResult && transcript.trim().isNotEmpty) {
      unawaited(
        handleText(
          transcript,
          requireWakeWord: continuousWakeMode,
        ),
      );
    }
  }

  void _onStatus(String status) {
    isListening = status == 'listening';
    notifyListeners();

    if ((status == 'notListening' || status == 'done') &&
        continuousWakeMode &&
        !_busySpeaking) {
      unawaited(startListening());
    }
  }

  Future<void> setPersonality(SangeetaPersonality value) async {
    personality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalityKey, value.name);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    languageCode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
    try {
      await _tts.setLanguage(value);
    } catch (_) {}
    if (_initialized && locales.isNotEmpty) {
      languageCode = _pickAvailableLocale(value);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

final sangeetaService = SangeetaService();
