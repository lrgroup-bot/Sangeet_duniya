import 'package:flutter/material.dart';

import '../models/sangeeta_likeness.dart';
import '../models/wardrobe_profile.dart';
import '../services/avatar_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rive_avatar_stage.dart';
import '../widgets/sangeeta_avatar.dart';

class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sangeeta Wardrobe')),
      body: AnimatedBuilder(
        animation: avatarProfileService,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Center(
                child: Container(
                  width: 300,
                  height: 330,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2B1909), Color(0xFF090807)],
                    ),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: .48),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 26,
                        spreadRadius: 2,
                        color: AppTheme.gold.withValues(alpha: .08),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: AppTheme.gold,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'REFERENCE LOOK LOCKED',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      RiveAvatarStage(
                        outfit: avatarProfileService.outfit,
                        pose: SangeetaPose.greeting,
                        size: 275,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sangeeta keeps the same face, long dark hair identity and body proportions across every outfit. The supplied reference photos are not bundled into the public APK.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                value: avatarProfileService.autoMood,
                onChanged: avatarProfileService.setAutoMood,
                title: const Text('Auto change dress by song mood'),
                subtitle: const Text(
                  'Sangeeta can switch wardrobe categories from song mood/category metadata.',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Wardrobe categories',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                itemCount: WardrobeCategory.values.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.25,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = WardrobeCategory.values[index];
                  final selected = avatarProfileService.category == item;
                  final favorite = avatarProfileService.favorites.contains(item);
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => avatarProfileService.setCategory(item),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: selected
                            ? AppTheme.gold.withValues(alpha: .16)
                            : const Color(0xFF17130F),
                        border: Border.all(
                          color: selected ? AppTheme.gold : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight:
                                    selected ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: favorite
                                ? 'Remove favorite'
                                : 'Save favorite',
                            onPressed: () =>
                                avatarProfileService.toggleFavorite(item),
                            icon: Icon(
                              favorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: favorite ? AppTheme.gold : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _Choice<Hairstyle>(
                label: 'Hairstyle',
                value: avatarProfileService.hairstyle,
                items: Hairstyle.values,
                title: (value) => value.label,
                onChanged: avatarProfileService.setHairstyle,
              ),
              const SizedBox(height: 12),
              _Choice<EarringStyle>(
                label: 'Earrings',
                value: avatarProfileService.earrings,
                items: EarringStyle.values,
                title: (value) => value.label,
                onChanged: avatarProfileService.setEarrings,
              ),
              const SizedBox(height: 12),
              _Choice<ShoeStyle>(
                label: 'Shoes',
                value: avatarProfileService.shoes,
                items: ShoeStyle.values,
                title: (value) => value.label,
                onChanged: avatarProfileService.setShoes,
              ),
              const SizedBox(height: 12),
              _Choice<AccessoryStyle>(
                label: 'Accessories',
                value: avatarProfileService.accessory,
                items: AccessoryStyle.values,
                title: (value) => value.label,
                onChanged: avatarProfileService.setAccessory,
              ),
              const SizedBox(height: 18),
              Text(
                'Visual identity: ${SangeetaLikeness.revision}. Default base look uses Gym Wear. Wardrobe state remains local on the device.',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.items,
    required this.title,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) title;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(title(item)),
            ),
          )
          .toList(growable: false),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
