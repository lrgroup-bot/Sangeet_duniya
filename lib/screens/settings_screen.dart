import 'package:flutter/material.dart';

import '../models/sangeeta_personality.dart';
import '../services/auth_provider.dart';
import '../services/avatar_profile_service.dart';
import '../services/sangeeta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import '../widgets/sangeeta_logo.dart';
import 'admin_dashboard_screen.dart';
import 'equalizer_screen.dart';
import 'sangeeta_preview_screen.dart';
import 'wardrobe_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          sangeetaService,
          avatarProfileService,
          authProvider,
        ]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Center(child: SangeetaLogo(size: 170, showTagline: false)),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "LR's Sangeet_Duniya v2.2",
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.verified_rounded,
                    color: AppTheme.gold,
                  ),
                  title: const Text('App access'),
                  subtitle: Text(authProvider.statusText),
                  trailing: IconButton(
                    tooltip: 'Sync with PC',
                    onPressed: authProvider.syncing
                        ? null
                        : authProvider.syncWithAdmin,
                    icon: authProvider.syncing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sangeeta personality',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<SangeetaPersonality>(
                initialValue: sangeetaService.personality,
                decoration:
                    const InputDecoration(labelText: 'Personality mode'),
                items: SangeetaPersonality.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    sangeetaService.setPersonality(value);
                  }
                },
              ),
              const SizedBox(height: 12),
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
              SwitchListTile(
                title: const Text('Foreground wake mode'),
                subtitle: const Text('Listen for “Hey Sangeeta”.'),
                value: sangeetaService.continuousWakeMode,
                onChanged: sangeetaService.setWakeMode,
              ),
              const Divider(height: 30),
              const Text(
                'Sangeeta live avatar',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0x221F1F1F),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: .35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: RiveAvatarStage(
                    outfit: avatarProfileService.outfit,
                    pose: SangeetaPose.dance,
                    size: 170,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.checkroom_rounded, color: AppTheme.gold),
                title: const Text('Wardrobe Studio'),
                subtitle: Text(
                  '${avatarProfileService.category.label} • hair, earrings, shoes & accessories',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WardrobeScreen(),
                  ),
                ),
              ),
              const Divider(height: 30),
              ListTile(
                leading:
                    const Icon(Icons.equalizer_rounded, color: AppTheme.gold),
                title: const Text('Sangeeta Equalizer'),
                subtitle: const Text(
                  'Auto EQ by default • Manual presets and 5-band controls',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EqualizerScreen(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: AppTheme.gold,
                ),
                title: const Text('Avatar Character Preview'),
                subtitle:
                    const Text('Check Sangeeta identity and animation states'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SangeetaPreviewScreen(),
                  ),
                ),
              ),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(
                  Icons.desktop_windows_rounded,
                  color: AppTheme.gold,
                ),
                title: const Text('Windows PC Admin Server'),
                subtitle: Text(
                  authProvider.serverUrl.isEmpty
                      ? 'Configure same-WiFi or Tailscale sync'
                      : authProvider.serverUrl,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Deactivate this phone'),
                subtitle: const Text(
                  'Removes the cached activation from this device only.',
                ),
                onTap: authProvider.signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}
