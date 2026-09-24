import 'package:flutter_test/flutter_test.dart';

import 'package:lrs_sangeet_duniya/models/avatar_outfit.dart';

void main() {
  test('all Sangeeta wardrobe presets exist', () {
    expect(
      AvatarOutfit.values,
      containsAll(<AvatarOutfit>[
        AvatarOutfit.casual,
        AvatarOutfit.party,
        AvatarOutfit.romantic,
        AvatarOutfit.traditionalOdia,
        AvatarOutfit.gymChill,
        AvatarOutfit.resortSwimwear,
        AvatarOutfit.nightSatin,
      ]),
    );
  });
}
