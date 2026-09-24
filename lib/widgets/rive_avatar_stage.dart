import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/avatar_outfit.dart';
import '../services/live_avatar_service.dart';
import 'sangeeta_avatar.dart';
import 'sangeeta_reference_avatar.dart';

class RiveAvatarStage extends StatefulWidget {
  const RiveAvatarStage({required this.outfit, required this.pose, this.size = 180, super.key});
  final AvatarOutfit outfit;
  final SangeetaPose pose;
  final double size;

  @override
  State<RiveAvatarStage> createState() => _RiveAvatarStageState();
}

class _RiveAvatarStageState extends State<RiveAvatarStage> {
  VideoPlayerController? _video;
  String _url = '';

  @override
  void initState() {
    super.initState();
    liveAvatarService.addListener(_remoteChanged);
    unawaited(liveAvatarService.refresh());
  }

  void _remoteChanged() {
    if (!mounted) return;
    final url = liveAvatarService.available ? liveAvatarService.videoUrl : '';
    if (url.isEmpty || url == _url) {
      setState(() {});
      return;
    }
    _url = url;
    final old = _video;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = controller;
    unawaited(old?.dispose());
    controller.initialize().then((_) {
      if (!mounted || _video != controller) return;
      controller.setLooping(true);
      controller.play();
      setState(() {});
    }).catchError((_) {
      if (mounted && _video == controller) setState(() {});
    });
  }

  @override
  void dispose() {
    liveAvatarService.removeListener(_remoteChanged);
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (liveAvatarService.available && _video?.value.isInitialized == true) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size * .12),
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _video!.value.size.width,
              height: _video!.value.size.height,
              child: VideoPlayer(_video!),
            ),
          ),
        ),
      );
    }
    return SangeetaReferenceAvatar(
      outfit: widget.outfit,
      width: widget.size * .72,
      height: widget.size,
      speaking: widget.pose == SangeetaPose.speaking,
      dancing: widget.pose == SangeetaPose.dance,
      seated: widget.pose == SangeetaPose.sit,
    );
  }
}
