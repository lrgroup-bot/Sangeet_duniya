import 'package:flutter_test/flutter_test.dart';

import 'package:lrs_sangeet_duniya/services/sangeeta_lip_sync.dart';

void main() {
  test('English vowels map to broad mouth shapes', () {
    expect(SangeetaLipSync.fromWord('hello').roundness, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('music').roundness, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('baby').open, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('mmm').open, lessThan(.1));
  });

  test('Hindi vowels and closed consonants map locally', () {
    expect(SangeetaLipSync.fromWord('आप').open, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('सुनो').roundness, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('म').open, lessThan(.1));
  });

  test('Odia vowels and closed consonants map locally', () {
    expect(SangeetaLipSync.fromWord('ଆସ').open, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('ଶୁଣ').roundness, greaterThan(.5));
    expect(SangeetaLipSync.fromWord('ମ').open, lessThan(.1));
  });

  test('empty speech rests the mouth', () {
    final shape = SangeetaLipSync.fromWord('');
    expect(shape.open, lessThan(.1));
    expect(shape.width, greaterThan(.7));
  });
}
