import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';
import 'sangeeta_avatar.dart';
import 'sangeeta_reference_avatar.dart';

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
    final reference = SangeetaReferenceAvatar(
      outfit: outfit,
      width: size * .78,
      height: size,
      speaking: pose == SangeetaPose.speaking,
      dancing: pose == SangeetaPose.dance,
      seated: pose == SangeetaPose.sit,
    );

    return Center(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        scale: pose == SangeetaPose.speaking ? 1.02 : 1,
        child: reference,
      ),
    );
  }
}
