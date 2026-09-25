enum SangeetaCommandKind {
  wakeOnly,
  pause,
  resume,
  next,
  previous,
  volumeUp,
  volumeDown,
  openPlaylist,
  downloadSong,
  searchSong,
  playSong,
  dance,
  identity,
  unknown,
}

class SangeetaCommand {
  const SangeetaCommand({
    required this.accepted,
    required this.kind,
    required this.cleaned,
    this.argument = '',
  });

  final bool accepted;
  final SangeetaCommandKind kind;
  final String cleaned;
  final String argument;
}

class SangeetaCommandParser {
  const SangeetaCommandParser();

  static const wakePhrases = <String>[
    'hey sangeeta',
    'hi sangeeta',
    'hello sangeeta',
  ];

  bool hasWakePhrase(String text) {
    final value = text.trim().toLowerCase();
    return wakePhrases.any(
      (phrase) => value == phrase || value.startsWith(phrase + ' '),
    );
  }

  SangeetaCommand parse(String input, {bool requireWakeWord = false}) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const SangeetaCommand(
        accepted: false,
        kind: SangeetaCommandKind.unknown,
        cleaned: '',
      );
    }

    final wake = wakePhrases.where(
      (phrase) => normalized == phrase || normalized.startsWith(phrase + ' '),
    );

    if (requireWakeWord && wake.isEmpty) {
      return SangeetaCommand(
        accepted: false,
        kind: SangeetaCommandKind.unknown,
        cleaned: normalized,
      );
    }

    var cleaned = normalized;
    if (wake.isNotEmpty) {
      final phrase = wake.first;
      cleaned = normalized.substring(phrase.length).trim();
    }

    if (cleaned.isEmpty) {
      return const SangeetaCommand(
        accepted: true,
        kind: SangeetaCommandKind.wakeOnly,
        cleaned: '',
      );
    }

    if (_equalsAny(cleaned, const ['pause', 'pause music', 'music pause', 'stop music'])) {
      return _command(SangeetaCommandKind.pause, cleaned);
    }
    if (_equalsAny(cleaned, const ['resume', 'resume music', 'continue', 'play music'])) {
      return _command(SangeetaCommandKind.resume, cleaned);
    }
    if (_equalsAny(cleaned, const ['next', 'next song', 'skip', 'skip song'])) {
      return _command(SangeetaCommandKind.next, cleaned);
    }
    if (_equalsAny(cleaned, const ['previous', 'previous song', 'back'])) {
      return _command(SangeetaCommandKind.previous, cleaned);
    }
    if (_equalsAny(cleaned, const ['volume up', 'increase volume', 'louder'])) {
      return _command(SangeetaCommandKind.volumeUp, cleaned);
    }
    if (_equalsAny(cleaned, const ['volume down', 'decrease volume', 'softer'])) {
      return _command(SangeetaCommandKind.volumeDown, cleaned);
    }
    if (cleaned == 'open playlist' ||
        cleaned == 'open playlists' ||
        cleaned == 'playlist') {
      return _command(SangeetaCommandKind.openPlaylist, cleaned);
    }
    if (cleaned == 'download song' ||
        cleaned == 'download this song' ||
        cleaned == 'download') {
      return _command(SangeetaCommandKind.downloadSong, cleaned);
    }
    if (cleaned == 'dance' || cleaned.contains('dance mode') || cleaned.contains('ନାଚ')) {
      return _command(SangeetaCommandKind.dance, cleaned);
    }
    if (cleaned.contains('who are you') ||
        cleaned.contains('ତୁମେ କିଏ') ||
        cleaned.contains('କିଏ ତୁମେ')) {
      return _command(SangeetaCommandKind.identity, cleaned);
    }

    final search = RegExp(r'^(?:search(?: song)?|find(?: song)?)\s*(.*)$')
        .firstMatch(cleaned);
    if (search != null) {
      return SangeetaCommand(
        accepted: true,
        kind: SangeetaCommandKind.searchSong,
        cleaned: cleaned,
        argument: (search.group(1) ?? '').trim(),
      );
    }

    final play = RegExp(r'^(?:play(?: song)?|ଚଳା|ବଜା|ଗୀତ)\s*(.*)$')
        .firstMatch(cleaned);
    if (play != null) {
      return SangeetaCommand(
        accepted: true,
        kind: SangeetaCommandKind.playSong,
        cleaned: cleaned,
        argument: (play.group(1) ?? '').trim(),
      );
    }

    return SangeetaCommand(
      accepted: true,
      kind: SangeetaCommandKind.unknown,
      cleaned: cleaned,
    );
  }

  static bool _equalsAny(String value, List<String> commands) =>
      commands.any((command) => value == command);

  static SangeetaCommand _command(
    SangeetaCommandKind kind,
    String cleaned,
  ) =>
      SangeetaCommand(
        accepted: true,
        kind: kind,
        cleaned: cleaned,
      );
}
