import 'package:flutter/material.dart';

import '../main.dart';
import '../services/library_store.dart';
import '../models/equalizer_profile.dart';
import '../services/equalizer_profile_service.dart';
import '../theme/app_theme.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sangeeta Equalizer')),
      body: AnimatedBuilder(
        animation: equalizerProfileService,
        builder: (context, _) {
          final item = audioHandler.mediaItem.value;
          final song = item == null ? null : libraryStore.songById(item.id);
          final recommended = song == null ? EqualizerPreset.balanced : EqualizerProfile.recommendFor(song);
          final profile = song == null ? EqualizerProfile.balanced : equalizerProfileService.profileFor(song);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Sangeeta Auto EQ', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(song == null ? 'The next song will use Auto EQ.' : 'Recommended for this song: ' + recommended.label),
                    const SizedBox(height: 14),
                    SegmentedButton<EqualizerMode>(
                      segments: const [
                        ButtonSegment(value: EqualizerMode.automatic, label: Text('Auto'), icon: Icon(Icons.auto_awesome_rounded)),
                        ButtonSegment(value: EqualizerMode.manual, label: Text('Manual'), icon: Icon(Icons.tune_rounded)),
                      ],
                      selected: <EqualizerMode>{equalizerProfileService.mode},
                      onSelectionChanged: (values) async {
                        await equalizerProfileService.setMode(values.first);
                        if (song != null) await audioHandler.applyEqualizer(equalizerProfileService.profileFor(song));
                      },
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Manual control', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<EqualizerPreset>(
                      initialValue: equalizerProfileService.preset,
                      decoration: const InputDecoration(labelText: 'Preset'),
                      items: EqualizerPreset.values.map((preset) => DropdownMenuItem(value: preset, child: Text(preset.label))).toList(),
                      onChanged: (preset) async {
                        if (preset == null) return;
                        await equalizerProfileService.setPreset(preset);
                        final current = audioHandler.mediaItem.value;
                        final currentSong = current == null ? null : libraryStore.songById(current.id);
                        if (currentSong != null) await audioHandler.applyEqualizer(equalizerProfileService.profileFor(currentSong));
                      },
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < EqualizerProfile.frequenciesHz.length; i++)
                      _BandSlider(
                        frequencyHz: EqualizerProfile.frequenciesHz[i],
                        value: equalizerProfileService.manualGainsDb[i],
                        onChanged: (value) => equalizerProfileService.setManualGain(i, value),
                      ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: song == null ? null : () => audioHandler.applyEqualizer(profile),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Apply current EQ'),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Auto EQ is a local recommendation engine. Android can apply live EQ through just_audio audio effects; Clean Audio can create a processed local file for offline use on supported platforms.',
                    style: TextStyle(color: AppTheme.gold2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({required this.frequencyHz, required this.value, required this.onChanged});
  final double frequencyHz; final double value; final ValueChanged<double> onChanged;
  String _label(double hz) => hz >= 1000 ? (hz / 1000).toStringAsFixed(1) + ' kHz' : hz.round().toString() + ' Hz';
  @override Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 64, child: Text(_label(frequencyHz), style: const TextStyle(fontWeight: FontWeight.w700))),
      Expanded(child: Slider(min: -10, max: 10, divisions: 40, value: value, onChanged: onChanged)),
      SizedBox(width: 48, child: Text(value.toStringAsFixed(1) + ' dB', textAlign: TextAlign.end, style: const TextStyle(fontSize: 11))),
    ],
  );
}