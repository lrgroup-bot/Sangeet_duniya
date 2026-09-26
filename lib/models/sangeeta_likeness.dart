import 'package:flutter/material.dart';

/// Canonical visual identity for Sangeeta v2.2.
///
/// The values in this profile were distilled from the project-owner supplied
/// reference photographs. The raw photographs are intentionally not bundled
/// in the public repository or APK. This keeps the production asset set small
/// and avoids redistributing source photographs while still giving every local
/// renderer one stable appearance target.
abstract final class SangeetaLikeness {
  static const revision = 'reference-v1-2026-09-26';
  static const rawReferencePhotosBundled = false;

  static const skin = Color(0xFFD89A82);
  static const skinLight = Color(0xFFF0B9A0);
  static const skinShadow = Color(0xFFB96F5F);
  static const hair = Color(0xFF17100F);
  static const hairLight = Color(0xFF3C2724);
  static const eye = Color(0xFF2B1B17);
  static const iris = Color(0xFF4B2C23);
  static const brow = Color(0xFF2A1916);
  static const lip = Color(0xFFB75B6E);
  static const lipHighlight = Color(0xFFE58A99);
  static const gold = Color(0xFFFFC857);

  /// High-level traits used by tests, documentation and future 3D authoring.
  static const referenceTraits = <String>[
    'adult feminine character',
    'long voluminous dark wavy hair',
    'soft oval face',
    'dark almond eyes',
    'full natural rose lips',
    'warm medium complexion',
    'slim curvy fashion silhouette',
    'confident friendly expression',
  ];

  /// Animation names expected from a future rigged GLB/VRM avatar. Keeping
  /// this contract in the app means a 3D model can replace the vector renderer
  /// without changing voice/player state handling.
  static const requiredMotionClips = <String>[
    'idle',
    'greeting',
    'listening',
    'speaking',
    'dance',
    'next',
    'previous',
    'sit',
  ];

  /// Viseme/expression names a future rigged model should expose.
  static const requiredFaceExpressions = <String>[
    'blink',
    'smile',
    'aa',
    'ee',
    'oh',
  ];
}
