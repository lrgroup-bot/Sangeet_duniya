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
        AvatarOutfit.party => 'Party glamour',
        AvatarOutfit.romantic => 'Romantic evening',
        AvatarOutfit.traditionalOdia => 'Traditional Odia',
        AvatarOutfit.gymChill => 'Gym / Chill',
        AvatarOutfit.resortSwimwear => 'Beach / resort swimwear',
        AvatarOutfit.nightSatin => 'Elegant satin nightwear',
      };
}
