import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';
import '../models/wardrobe_profile.dart';
import '../services/avatar_profile_service.dart';
import 'avatar_accessory_overlay.dart';
import 'sangeeta_avatar.dart';

/// Local-first Sangeeta avatar stage.
///
/// The production renderer keeps one canonical face/body identity and layers
/// wardrobe/accessory state on top. A future rigged GLB/VRM renderer can sit
/// behind this same widget without changing the player or voice surfaces.
class RiveAvatarStage extends StatelessWidget {
  const RiveAvatarStage({
    required this.outfit,
    required this.pose,
    this.speechMouthOpen,
    this.speechMouthWidth,
    this.speechMouthRoundness,
    this.size = 180,
    super.key,
  });

  final AvatarOutfit outfit;
  final SangeetaPose pose;
  final double? speechMouthOpen;
  final double? speechMouthWidth;
  final double? speechMouthRoundness;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: avatarProfileService,
      builder: (context, _) => Semantics(
        label:
            'Sangeeta avatar, ${avatarProfileService.category.label}, ${pose.name}',
        image: true,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SangeetaAvatar(
                outfit: outfit,
                category: avatarProfileService.category,
                hairstyle: avatarProfileService.hairstyle,
                pose: pose,
                speechMouthOpen: speechMouthOpen,
                speechMouthWidth: speechMouthWidth,
                speechMouthRoundness: speechMouthRoundness,
                size: size,
              ),
              AvatarAccessoryOverlay(
                category: avatarProfileService.category,
                hairstyle: avatarProfileService.hairstyle,
                earrings: avatarProfileService.earrings,
                shoes: avatarProfileService.shoes,
                accessory: avatarProfileService.accessory,
                size: size,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
