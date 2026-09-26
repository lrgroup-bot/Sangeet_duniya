import 'package:flutter_test/flutter_test.dart';

import 'package:lrs_sangeet_duniya/models/sangeeta_likeness.dart';

void main() {
  test('Sangeeta reference identity is explicit and local-safe', () {
    expect(SangeetaLikeness.revision, 'reference-v1-2026-09-26');
    expect(SangeetaLikeness.rawReferencePhotosBundled, isFalse);
    expect(
      SangeetaLikeness.referenceTraits,
      contains('long voluminous dark wavy hair'),
    );
    expect(
      SangeetaLikeness.referenceTraits,
      contains('confident friendly expression'),
    );
  });

  test('future rigged avatar contract covers current companion states', () {
    expect(
      SangeetaLikeness.requiredMotionClips,
      containsAll(<String>[
        'idle',
        'greeting',
        'listening',
        'speaking',
        'dance',
        'next',
        'previous',
        'sit',
      ]),
    );
    expect(
      SangeetaLikeness.requiredFaceExpressions,
      containsAll(<String>['blink', 'smile', 'aa', 'ee', 'oh']),
    );
  });
}
