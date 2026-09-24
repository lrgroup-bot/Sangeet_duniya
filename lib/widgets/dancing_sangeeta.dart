import 'package:flutter/material.dart';

import '../services/avatar_profile_service.dart';
import '../theme/app_theme.dart';
import 'rive_avatar_stage.dart';
import 'sangeeta_avatar.dart';

class DancingSangeeta extends StatelessWidget {
  const DancingSangeeta({
    required this.category,
    this.compact = false,
    super.key,
  });

  final String category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: category.toLowerCase() == 'romantic'
              ? const [Color(0xFF761A45), Color(0xFF220912)]
              : category.toLowerCase() == 'party'
                  ? const [Color(0xFF4D2768), Color(0xFF0F0618)]
                  : const [Color(0xFF4A3518), Color(0xFF090807)],
        ),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: .65),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: .18),
            blurRadius: 24,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: avatarProfileService,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RiveAvatarStage(
              outfit: avatarProfileService.outfit,
              pose: SangeetaPose.dance,
              size: compact ? 150 : 260,
              riveUrl: avatarProfileService.riveUrl,
              stateMachine: avatarProfileService.riveStateMachine,
            ),
            if (!compact) ...[
              const SizedBox(height: 10),
              Text(
                category + ' • Dance Mode',
                style: const TextStyle(
                  color: AppTheme.gold2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
