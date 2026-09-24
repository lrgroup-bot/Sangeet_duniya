enum AvatarOutfit {
  casual,
  party,
  romantic,
  traditionalOdia,
  gymChill,
  resortSwimwear,
  nightSatin,
}

extension AvatarOutfitLabel on AvatarOutfit {
  String get label => switch (this) {
        AvatarOutfit.casual => 'Casual modern',
        AvatarOutfit.party => 'Party',
        AvatarOutfit.romantic => 'Romantic',
        AvatarOutfit.traditionalOdia => 'Traditional Odia',
        AvatarOutfit.gymChill => 'Gym / Chill',
        AvatarOutfit.resortSwimwear => 'Resort swimwear',
        AvatarOutfit.nightSatin => 'Elegant satin nightwear',
      };
}
