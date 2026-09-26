class SyncedLyricLine {
  const SyncedLyricLine({required this.time, required this.text});

  final Duration time;
  final String text;
}

class LyricsSync {
  const LyricsSync._();

  static List<SyncedLyricLine> parse(String raw) {
    final lines = <SyncedLyricLine>[];
    final pattern = RegExp(r'^\[(\d{1,2}):(\d{2})(?:[\.:](\d{1,3}))?\]\s*(.*)$');

    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final match = pattern.firstMatch(line.trim());
      if (match == null) continue;

      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
      final fractionText = match.group(3) ?? '';
      var milliseconds = 0;
      if (fractionText.isNotEmpty) {
        final padded = (fractionText + '000').substring(0, 3);
        milliseconds = int.tryParse(padded) ?? 0;
      }

      lines.add(
        SyncedLyricLine(
          time: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
          text: (match.group(4) ?? '').trim(),
        ),
      );
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  static SyncedLyricLine? lineAt(
    List<SyncedLyricLine> lines,
    Duration position,
  ) {
    SyncedLyricLine? active;
    for (final line in lines) {
      if (line.time > position) break;
      active = line;
    }
    return active;
  }
}
