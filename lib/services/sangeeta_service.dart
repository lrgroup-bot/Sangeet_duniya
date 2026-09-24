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
import 'permission_service.dart';
import 'music_catalog_service.dart';

class SangeetaService extends ChangeNotifier {
  static const _personalityKey = 'sangeeta_personality';
  static const _languageKey = 'sangeeta_language';

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _busySpeaking = false;

  bool isListening = false;
  bool continuousWakeMode = true;
  String transcript = '';
  String reply = 'ହାଇ ଜାନ୍… ମୁଁ Sangeeta। ଗୀତ ଶୁଣିବାକୁ ପ୍ରସ୍ତୁତ। 💛';

  List<LocaleName> locales = const <LocaleName>[];
  String languageCode = 'or-IN';
  SangeetaPersonality personality = SangeetaPersonality.sweetheart;

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

  Future<void> handleText(String text) async {
    final command = text.trim();
    if (command.isEmpty) return;

    transcript = command;
    notifyListeners();

    final cleaned = _stripWakePhrase(command.toLowerCase());

    if (_isAny(cleaned, const ['pause', 'pause music', 'music pause', 'stop music'])) {
      await audioHandler.pause();
      await _speak(_replyFor('ପାଉଜ୍ କରିଦେଲି।'));
      return;
    }

    if (_isAny(cleaned, const ['resume', 'resume music', 'play music', 'continue', 'play this'])) {
      await audioHandler.play();
      await _speak(_replyFor('ପୁଣି ଗୀତ ଚଳାଇଦେଲି।'));
      return;
    }

    if (_isAny(cleaned, const ['next', 'next song', 'skip', 'skip song'])) {
      await audioHandler.skipToNext();
      await _speak(_replyFor('ପରବର୍ତ୍ତୀ ଗୀତ ଚଳାଇଦେଲି।'));
      return;
    }

    if (_isAny(cleaned, const ['previous', 'previous song', 'back'])) {
      await audioHandler.skipToPrevious();
      await _speak(_replyFor('ପୂର୍ବ ଗୀତକୁ ଫେରାଇଦେଲି।'));
      return;
    }

    if (cleaned.contains('dance') || cleaned.contains('ନାଚ')) {
      await _speak(_replyFor('ଚଲ ତାହେଲେ Dance Mode ଖୋଲିଦେଉଛି। 💃'));
      return;
    }

    if (cleaned.contains('who are you') ||
        cleaned.contains('ତୁମେ କିଏ') ||
        cleaned.contains('କିଏ ତୁମେ')) {
      await _speak(_replyFor(
        'ମୁଁ Sangeeta… ତୁମର music companion। ଗୀତ ଖୋଜିବା ଓ play କରିବାରେ ମୁଁ ସାଥିରେ ଅଛି।',
      ));
      return;
    }

    final match = RegExp(
      r'^(?:play|ଚଳା|ବଜା|ଗୀତ)\s+(.+)$',
    ).firstMatch(cleaned);

    if (match != null) {
      final query = match.group(1)!.trim();
      final found = await _findSong(query);
      if (found != null) {
        final song = found.$1;
        await audioHandler.playSong(song, songs: found.$2);
        await _speak(_replyFor(
          'ହଁ ଜାନ୍… "' +
              song.title +
              '" ଚଳାଉଛି। Sangeeta Auto EQ ମଧ୍ୟ ଚୟନ କରିଦେଲି। 🎵',
        ));
      } else {
        await _speak(_replyFor(
          'ସେଇ ଗୀତଟା online source ରେ ମିଳିଲା ନାହିଁ। ଆଉ ଗୋଟେ ଗୀତର ନାମ କହ।',
        ));
      }
      return;
    }

    await _speak(_replyFor(
      'ମୁଁ ଶୁଣୁଛି। "play Golden Horizon", "next song" କିମ୍ବା "pause music" କହିପାର। 💛',
    ));
  }

  String _stripWakePhrase(String value) {
    const phrases = [
      'hey sangeeta',
      'hi sangeeta',
      'hello sangeeta',
      'hey sweetheart',
      'hi sweetheart',
      'hello sweetheart',
      'hey baby',
      'hi baby',
      'hello baby',
      'hey darling',
      'hi darling',
      'hello darling',
      'sangeeta',
      'sweetheart',
      'baby',
      'darling',
    ];

    var result = value.trim();
    for (final phrase in phrases) {
      if (result.startsWith(phrase)) {
        result = result.substring(phrase.length).trim();
        break;
      }
    }
    return result
        .replaceFirst(RegExp(r'^(hey|hi|hello)\s+'), '')
        .trim();
  }

  bool _isAny(String value, List<String> commands) {
    return commands.any((command) => value == command);
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

  String _replyFor(String odia) {
    switch (personality) {
      case SangeetaPersonality.sweetheart:
        return 'ହଁ ଜାନ୍… ' + odia + ' 💛';
      case SangeetaPersonality.friendly:
        return odia;
      case SangeetaPersonality.funny:
        return odia + ' ମଜା ହେବ! 😄';
      case SangeetaPersonality.musicExpert:
        return 'Playback updated: ' + odia;
    }
  }

  Future<void> _speak(String text) async {
    reply = text;
    notifyListeners();

    _busySpeaking = true;
    try {
      await _speech.stop();
      await _tts.stop();
      await _tts.setLanguage(languageCode);
      await _tts.speak(text);
    } catch (_) {
      // Keep text chat working even when the device has no matching TTS voice.
    } finally {
      _busySpeaking = false;
    }

    if (continuousWakeMode) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!isListening) unawaited(startListening());
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    transcript = result.recognizedWords;
    notifyListeners();

    if (result.finalResult && transcript.trim().isNotEmpty) {
      unawaited(handleText(transcript));
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
