import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/models/sangeeta_personality.dart';

void main() {
  test('Sweetheart is the default personality enum', () {
    expect(SangeetaPersonality.values.first, SangeetaPersonality.sweetheart);
    expect(SangeetaPersonality.sweetheart.label, 'Sweetheart');
  });

  test('all requested personality modes exist', () {
    expect(
      SangeetaPersonality.values,
      containsAll(<SangeetaPersonality>[
        SangeetaPersonality.sweetheart,
        SangeetaPersonality.friendly,
        SangeetaPersonality.funny,
        SangeetaPersonality.musicExpert,
      ]),
    );
  });
}
