import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/models/avatar_outfit.dart';
import 'package:lrs_sangeet_duniya/models/wardrobe_profile.dart';

void main() {
  test('v2.2 exposes all ten wardrobe categories', () {
    expect(WardrobeCategory.values.length, 10);
    expect(
      WardrobeCategory.values.map((item) => item.label),
      containsAll(<String>[
        'Casual',
        'Party',
        'Romantic',
        'Traditional Odia',
        'DJ Stage Outfit',
        'Gym Wear',
        'Beach / Resort Wear',
        'Night Wear',
        'Festival Collection',
        'Winter Collection',
      ]),
    );
  });

  test('every category maps to a local renderer outfit', () {
    for (final category in WardrobeCategory.values) {
      expect(category.rendererOutfit, isA<AvatarOutfit>());
    }
  });
}
