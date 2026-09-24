import 'package:flutter/material.dart';

import '../models/sangeeta_personality.dart';
import '../services/sangeeta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sangeeta_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: sangeetaService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Center(child: SangeetaLogo(size: 170, showTagline: false)),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "LR's Sangeet_Duniya",
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Sangeeta personality',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<SangeetaPersonality>(
                initialValue: sangeetaService.personality,
                decoration: const InputDecoration(
                  labelText: 'Personality mode',
                ),
                items: SangeetaPersonality.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) sangeetaService.setPersonality(value);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Sangeeta language',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: sangeetaService.languageCode,
                decoration: const InputDecoration(labelText: 'Voice language'),
                items: const [
                  DropdownMenuItem(value: 'or-IN', child: Text('Odia')),
                  DropdownMenuItem(value: 'hi-IN', child: Text('Hindi')),
                  DropdownMenuItem(value: 'en-IN', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) sangeetaService.setLanguage(value);
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Foreground wake mode'),
                subtitle: const Text(
                  'Listen on the Sangeeta screen for Hey Sangeeta, Sweetheart, Baby or Darling.',
                ),
                value: sangeetaService.continuousWakeMode,
                onChanged: sangeetaService.setWakeMode,
              ),
              const Divider(height: 30),
              const Text(
                'Avatar style presets',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Party and Romantic modes use different performance presets. The avatar layer is modular for later wardrobe packs.',
              ),
              const SizedBox(height: 10),
              const ListTile(
                leading: Icon(Icons.favorite_rounded),
                title: Text('Sweetheart'),
                subtitle: Text('Default personality'),
              ),
              const ListTile(
                leading: Icon(Icons.nightlife_rounded),
                title: Text('Party'),
                subtitle: Text('Performance preset'),
              ),
              const ListTile(
                leading: Icon(Icons.auto_awesome_rounded),
                title: Text('Romantic'),
                subtitle: Text('Warm performance preset'),
              ),
            ],
          );
        },
      ),
    );
  }
}
