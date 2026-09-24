import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';
import 'sangeeta_avatar.dart';

/// Local-only avatar stage. No remote avatar file, cloud runtime,
/// or network animation source is used.
class RiveAvatarStage extends StatelessWidget {
  const RiveAvatarStage({
    required this.outfit,
    required this.pose,
    this.size = 180,
    super.key,
  });

  final AvatarOutfit outfit;
  final SangeetaPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SangeetaAvatar(
      outfit: outfit,
      pose: pose,
      size: size,
    );
  }
}
