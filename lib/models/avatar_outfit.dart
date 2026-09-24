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
        // Keep the stored enum name for backwards compatibility, but expose
        // the new user-facing name requested for this mood.
        AvatarOutfit.romantic => 'Bikini / resort',
        AvatarOutfit.traditionalOdia => 'Traditional Odia',
        AvatarOutfit.gymChill => 'Gym / Chill',
        AvatarOutfit.resortSwimwear => 'Resort swimwear',
        AvatarOutfit.nightSatin => 'Elegant satin nightwear',
      };
}
