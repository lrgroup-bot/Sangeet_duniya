enum AvatarOutfit {
  casual,
  party,
  romantic,
  traditionalOdia,
  gymChill,
  resortSwimwear,
  nightSatin,
  formalSuit,
}

extension AvatarOutfitLabel on AvatarOutfit {
  String get label => switch (this) {
        AvatarOutfit.casual => 'Casual black & gold',
        AvatarOutfit.party => 'Party glamour',
        AvatarOutfit.romantic => 'Elegant romantic',
        AvatarOutfit.traditionalOdia => 'Traditional Odia',
        AvatarOutfit.gymChill => 'Sport / dance',
        AvatarOutfit.resortSwimwear => 'Resort casual',
        AvatarOutfit.nightSatin => 'Elegant satin',
        AvatarOutfit.formalSuit => 'Black formal suit',
      };
}
