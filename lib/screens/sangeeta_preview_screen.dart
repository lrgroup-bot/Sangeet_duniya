import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';
import '../services/avatar_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';

class SangeetaPreviewScreen extends StatefulWidget {
  const SangeetaPreviewScreen({super.key});

  @override
  State<SangeetaPreviewScreen> createState() => _SangeetaPreviewScreenState();
}

class _SangeetaPreviewScreenState extends State<SangeetaPreviewScreen> {
  SangeetaPose _pose = SangeetaPose.idle;

  @override
  Widget build(BuildContext context) {
    final poses = <(String, SangeetaPose)>[
      ('Idle', SangeetaPose.idle),
      ('Greeting', SangeetaPose.greeting),
      ('Listening', SangeetaPose.listening),
      ('Speaking', SangeetaPose.speaking),
      ('Dance', SangeetaPose.dance),
      ('Pause', SangeetaPose.sit),
      ('Next', SangeetaPose.next),
      ('Previous', SangeetaPose.previous),
    ];

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
              builder: (context, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 390,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: avatarProfileService.outfit == AvatarOutfit.romantic
                        ? const [Color(0xFF3A0D1E), Color(0xFF090807)]
                        : const [Color(0xFF281908), Color(0xFF090807)],
                  ),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: .5),
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: RiveAvatarStage(
                  outfit: avatarProfileService.outfit,
                  pose: _pose,
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
              'Sangeeta keeps one original adult face, hairstyle, headphones and body proportions across outfits and poses. The wardrobe changes, while her identity stays consistent.',
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: avatarProfileService,
              builder: (context, _) => Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: AvatarOutfit.values
                    .map(
                      (outfit) => ChoiceChip(
                        label: Text(outfit.label),
                        selected: avatarProfileService.outfit == outfit,
                        onSelected: (_) =>
                            avatarProfileService.setOutfit(outfit),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Animation check',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: poses
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(entry.$1),
                      selected: _pose == entry.$2,
                      onSelected: (_) => setState(() => _pose = entry.$2),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
