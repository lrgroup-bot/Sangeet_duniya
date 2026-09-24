enum SangeetaPersonality {
  sweetheart,
  friendly,
  funny,
  musicExpert,
}

extension SangeetaPersonalityLabel on SangeetaPersonality {
  String get label => switch (this) {
        SangeetaPersonality.sweetheart => 'Sweetheart',
        SangeetaPersonality.friendly => 'Friendly',
        SangeetaPersonality.funny => 'Funny',
        SangeetaPersonality.musicExpert => 'Music Expert',
      };
}
