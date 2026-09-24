import 'package:flutter/material.dart';
import '../services/auth_provider.dart';

import '../models/avatar_outfit.dart';
import '../models/sangeeta_personality.dart';
import '../services/avatar_profile_service.dart';
import '../services/sangeeta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';
import '../widgets/sangeeta_logo.dart';
import 'admin_dashboard_screen.dart';
import 'license_admin_screen.dart';
import 'equalizer_screen.dart';

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
                  "LR's Sangeet_Duniya",
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
              const SizedBox(height: 12),
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
                'Sangeeta live avatar',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose an original wardrobe preset. The live Sangeeta avatar is bundled inside the app and works without a cloud avatar service.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AvatarOutfit>(
                initialValue: avatarProfileService.outfit,
                decoration: const InputDecoration(labelText: 'Wardrobe'),
                items: AvatarOutfit.values
                    .map(
                      (outfit) => DropdownMenuItem(
                        value: outfit,
                        child: Text(outfit.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) avatarProfileService.setOutfit(value);
                },
              ),
              const SizedBox(height: 14),
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
              const Divider(height: 30),
              ListTile(
                leading: const Icon(
                  Icons.equalizer_rounded,
                  color: AppTheme.gold,
                ),
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
              const Divider(height: 30),
              const Text(
                'Access & token tools',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              if (authProvider.isOwner)
                ListTile(
                  leading: const Icon(
                    Icons.dashboard_rounded,
                    color: AppTheme.gold,
                  ),
                  title: const Text('Admin Dashboard'),
                  subtitle: const Text(
                    'Users, active tokens, expiry days and free distribution QR',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  ),
                ),
              if (authProvider.isOwner)
                ListTile(
                  leading: const Icon(Icons.key_rounded, color: AppTheme.gold),
                  title: const Text('License Manager'),
                  subtitle: const Text('Generate 7-day, 30-day, 365-day or lifetime tokens'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LicenseAdminScreen(),
                    ),
                  ),
                ),
              ListTile(
                leading: Icon(
                  authProvider.isOwner
                      ? Icons.admin_panel_settings_rounded
                      : Icons.lock_open_rounded,
                ),
                title: Text(
                  authProvider.isOwner
                      ? 'Owner device'
                      : 'Activation status',
                ),
                subtitle: Text(
                  authProvider.isOwner
                      ? 'This phone can generate access tokens.'
                      : authProvider.statusText,
                ),
                trailing: authProvider.isOwner
                    ? IconButton(
                        tooltip: 'Leave owner mode',
                        onPressed: authProvider.signOut,
                        icon: const Icon(Icons.logout_rounded),
                      )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
