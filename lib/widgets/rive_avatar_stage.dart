import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../models/avatar_outfit.dart';
import 'sangeeta_avatar.dart';

class RiveAvatarStage extends StatelessWidget {
  const RiveAvatarStage({
    required this.outfit,
    required this.pose,
    this.size = 180,
    this.riveUrl = '',
    this.stateMachine = '',
    super.key,
  });

  final AvatarOutfit outfit;
  final SangeetaPose pose;
  final double size;
  final String riveUrl;
  final String stateMachine;

  @override
  Widget build(BuildContext context) {
    final url = riveUrl.trim();
    if (url.isEmpty) {
      return SangeetaAvatar(
        outfit: outfit,
        pose: pose,
        size: size,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: rive.RiveAnimation.network(
        url,
        fit: BoxFit.contain,
        stateMachines: stateMachine.trim().isEmpty
            ? const []
            : <String>[stateMachine.trim()],
      ),
    );
  }
}
