import 'dart:math' as math;

/// Lightweight local viseme approximation for Sangeeta.
///
/// flutter_tts exposes word progress, not phoneme timings on every platform.
/// This mapper converts the currently spoken word into broad mouth shapes so
/// the avatar follows real TTS progress rather than animating blindly.
class SangeetaLipShape {
  const SangeetaLipShape({
    required this.open,
    required this.width,
    required this.roundness,
  });

  final double open;
  final double width;
  final double roundness;

  static const rest = SangeetaLipShape(open: 0.08, width: 0.82, roundness: 0);
  static const closed = SangeetaLipShape(open: 0.03, width: 0.76, roundness: 0);
  static const wide = SangeetaLipShape(open: 0.34, width: 1.12, roundness: 0);
  static const openVowel = SangeetaLipShape(open: 0.82, width: 0.95, roundness: .05);
  static const rounded = SangeetaLipShape(open: 0.52, width: 0.70, roundness: .88);
  static const soft = SangeetaLipShape(open: 0.30, width: 0.90, roundness: .18);
}

abstract final class SangeetaLipSync {
  static SangeetaLipShape fromWord(String rawWord) {
    final word = rawWord.trim().toLowerCase();
    if (word.isEmpty) return SangeetaLipShape.rest;

    // flutter_tts gives us word timing rather than phoneme timing. Let the
    // strongest visible vowel dominate the word shape; otherwise common words
    // containing m/b/p would incorrectly keep the lips closed for the entire
    // word.
    // Rounded O/U families.
    if (_containsAny(word, const <String>[
      'o', 'u', 'oo', 'ou',
      'ओ', 'औ', 'उ', 'ऊ', 'ो', 'ौ', 'ु', 'ू',
      'ଓ', 'ଔ', 'ଉ', 'ଊ', 'ୋ', 'ୌ', 'ୁ', 'ୂ',
    ])) {
      return SangeetaLipShape.rounded;
    }

    // Open A/AH families.
    if (_containsAny(word, const <String>[
      'a', 'aa', 'ah',
      'अ', 'आ', 'ा',
      'ଅ', 'ଆ', 'ା',
    ])) {
      return SangeetaLipShape.openVowel;
    }

    // Wide E/I families.
    if (_containsAny(word, const <String>[
      'e', 'i', 'ee', 'ai',
      'इ', 'ई', 'ए', 'ऐ', 'ि', 'ी', 'े', 'ै',
      'ଇ', 'ଈ', 'ଏ', 'ଐ', 'ି', 'ୀ', 'େ', 'ୈ',
    ])) {
      return SangeetaLipShape.wide;
    }

    // Closed-lip consonants across English/Hindi/Odia are the fallback when
    // the word has no stronger visible vowel cue.
    if (_containsAny(word, const <String>[
      'm', 'b', 'p',
      'म', 'ब', 'प', 'भ',
      'ମ', 'ବ', 'ପ', 'ଭ',
    ])) {
      return SangeetaLipShape.closed;
    }

    return SangeetaLipShape.soft;
  }

  static bool _containsAny(String text, List<String> tokens) =>
      tokens.any(text.contains);

  /// Adds a tiny natural pulse while a word is active without detaching the
  /// animation from the actual word-progress callback.
  static double pulsedOpen(
    SangeetaLipShape shape,
    double phase,
  ) {
    final pulse = .90 + .10 * math.sin(phase * math.pi * 2).abs();
    return (shape.open * pulse).clamp(0.0, 1.0);
  }
}
