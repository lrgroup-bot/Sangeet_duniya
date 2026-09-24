import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';
import '../services/avatar_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';

class SangeetaPreviewScreen extends StatelessWidget {
  const SangeetaPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sangeeta Avatar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'SANGEETA • CHARACTER PREVIEW',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.gold,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: avatarProfileService,
              builder: (context, _) => Container(
                height: 390,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF281908), Color(0xFF090807)],
                  ),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: .5)),
                ),
                alignment: Alignment.bottomCenter,
                child: RiveAvatarStage(
                  outfit: avatarProfileService.outfit,
                  pose: SangeetaPose.idle,
                  size: 350,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Identity lock',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sangeeta uses one fixed original adult face, hairstyle, headphones and body proportions across every outfit and animation. Only the wardrobe and pose change.',
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: AvatarOutfit.values
                  .map(
                    (outfit) => ChoiceChip(
                      label: Text(outfit.label),
                      selected: avatarProfileService.outfit == outfit,
                      onSelected: (_) => avatarProfileService.setOutfit(outfit),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Animation check',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Idle')),
                Chip(label: Text('Greeting')),
                Chip(label: Text('Listening')),
                Chip(label: Text('Speaking')),
                Chip(label: Text('Dance')),
                Chip(label: Text('Sit on Pause')),
                Chip(label: Text('Point Next')),
                Chip(label: Text('Point Previous')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
