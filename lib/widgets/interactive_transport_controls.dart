import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/avatar_profile_service.dart';
import 'rive_avatar_stage.dart';
import 'sangeeta_avatar.dart';

class InteractiveTransportControls extends StatefulWidget {
  const InteractiveTransportControls({super.key});

  @override
  State<InteractiveTransportControls> createState() =>
      _InteractiveTransportControlsState();
}

class _InteractiveTransportControlsState
    extends State<InteractiveTransportControls> {
  SangeetaPose _temporaryPose = SangeetaPose.idle;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _previous() async {
    setState(() => _temporaryPose = SangeetaPose.previous);
    _resetLater();
    await audioHandler.skipToPrevious();
  }

  Future<void> _next() async {
    setState(() => _temporaryPose = SangeetaPose.next);
    _resetLater();
    await audioHandler.skipToNext();
  }

  Future<void> _toggle(PlaybackState? state) async {
    if (state?.playing ?? false) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  void _resetLater() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) setState(() => _temporaryPose = SangeetaPose.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;
        final pose = _temporaryPose != SangeetaPose.idle
            ? _temporaryPose
            : playing
                ? SangeetaPose.dance
                : SangeetaPose.sit;

        return SizedBox(
          height: 152,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TransportButton(
                    icon: Icons.skip_previous_rounded,
                    onPressed: _previous,
                  ),
                  const SizedBox(width: 22),
                  _TransportButton(
                    icon: playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    large: true,
                    onPressed: () => _toggle(state),
                  ),
                  const SizedBox(width: 22),
                  _TransportButton(
                    icon: Icons.skip_next_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
              IgnorePointer(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  alignment: switch (pose) {
                    SangeetaPose.previous => const Alignment(-.69, .06),
                    SangeetaPose.next => const Alignment(.69, .06),
                    SangeetaPose.sit => const Alignment(0, .06),
                    _ => const Alignment(0, -.28),
                  },
                  child: ListenableBuilder(
                    listenable: avatarProfileService,
                    builder: (context, _) => RiveAvatarStage(
                      outfit: avatarProfileService.outfit,
                      pose: pose,
                      size: 96,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.onPressed,
    this.large = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final side = large ? 86.0 : 58.0;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEAA2),
            Color(0xFFFFC857),
            Color(0xFFB56C08),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x663F2A0A),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        iconSize: large ? 40 : 30,
        color: Colors.black,
        icon: Icon(icon),
        tooltip: icon == Icons.skip_next_rounded
            ? 'Next'
            : icon == Icons.skip_previous_rounded
                ? 'Previous'
                : 'Play / Pause',
      ),
    );
  }
}
