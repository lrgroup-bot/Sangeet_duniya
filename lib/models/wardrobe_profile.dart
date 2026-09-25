import 'avatar_outfit.dart';

enum WardrobeCategory {
  casual,
  party,
  romantic,
  traditionalOdia,
  djStage,
  gymWear,
  beachResort,
  nightWear,
  festival,
  winter,
}

extension WardrobeCategoryInfo on WardrobeCategory {
  String get label => switch (this) {
        WardrobeCategory.casual => 'Casual',
        WardrobeCategory.party => 'Party',
        WardrobeCategory.romantic => 'Romantic',
        WardrobeCategory.traditionalOdia => 'Traditional Odia',
        WardrobeCategory.djStage => 'DJ Stage Outfit',
        WardrobeCategory.gymWear => 'Gym Wear',
        WardrobeCategory.beachResort => 'Beach / Resort Wear',
        WardrobeCategory.nightWear => 'Night Wear',
        WardrobeCategory.festival => 'Festival Collection',
        WardrobeCategory.winter => 'Winter Collection',
      };

  AvatarOutfit get rendererOutfit => switch (this) {
        WardrobeCategory.casual => AvatarOutfit.casual,
        WardrobeCategory.party => AvatarOutfit.party,
        WardrobeCategory.romantic => AvatarOutfit.romantic,
        WardrobeCategory.traditionalOdia => AvatarOutfit.traditionalOdia,
        WardrobeCategory.djStage => AvatarOutfit.party,
        WardrobeCategory.gymWear => AvatarOutfit.gymChill,
        WardrobeCategory.beachResort => AvatarOutfit.resortSwimwear,
        WardrobeCategory.nightWear => AvatarOutfit.nightSatin,
        WardrobeCategory.festival => AvatarOutfit.traditionalOdia,
        WardrobeCategory.winter => AvatarOutfit.casual,
      };
}

enum Hairstyle { longWave, ponytail, braid, bun, stageWave }

extension HairstyleInfo on Hairstyle {
  String get label => switch (this) {
        Hairstyle.longWave => 'Long wave',
        Hairstyle.ponytail => 'Ponytail',
        Hairstyle.braid => 'Braid',
        Hairstyle.bun => 'Bun',
        Hairstyle.stageWave => 'Stage wave',
      };
}

enum EarringStyle { none, studs, hoops, jhumka }

extension EarringStyleInfo on EarringStyle {
  String get label => switch (this) {
        EarringStyle.none => 'None',
        EarringStyle.studs => 'Studs',
        EarringStyle.hoops => 'Hoops',
        EarringStyle.jhumka => 'Jhumka',
      };
}

enum ShoeStyle { sneakers, heels, sandals, boots }

extension ShoeStyleInfo on ShoeStyle {
  String get label => switch (this) {
        ShoeStyle.sneakers => 'Sneakers',
        ShoeStyle.heels => 'Heels',
        ShoeStyle.sandals => 'Sandals',
        ShoeStyle.boots => 'Boots',
      };
}

enum AccessoryStyle { none, necklace, scarf, bangles, stageHeadset }

extension AccessoryStyleInfo on AccessoryStyle {
  String get label => switch (this) {
        AccessoryStyle.none => 'None',
        AccessoryStyle.necklace => 'Necklace',
        AccessoryStyle.scarf => 'Scarf',
        AccessoryStyle.bangles => 'Bangles',
        AccessoryStyle.stageHeadset => 'Stage headset',
      };
}
