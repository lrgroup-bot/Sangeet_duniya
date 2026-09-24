import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'sangeeta_logo.dart';

class DancingSangeeta extends StatefulWidget {
  const DancingSangeeta({
    required this.category,
    this.compact = false,
    super.key,
  });

  final String category;
  final bool compact;

  @override
  State<DancingSangeeta> createState() => _DancingSangeetaState();
}

class _DancingSangeetaState extends State<DancingSangeeta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _colors() {
    switch (widget.category.toLowerCase()) {
      case 'romantic':
        return const [Color(0xFF761A45), Color(0xFF220912)];
      case 'party':
        return const [Color(0xFF4D2768), Color(0xFF0F0618)];
      case 'devotional':
        return const [Color(0xFF8B5A14), Color(0xFF211606)];
      default:
        return const [Color(0xFF4A3518), Color(0xFF090807)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final beat = math.sin(_controller.value * math.pi);
        final scale = 1 + beat * (widget.compact ? .025 : .055);
        final rotation = (beat - .5) * (widget.compact ? .025 : .06);

        return Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: EdgeInsets.all(widget.compact ? 5 : 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(colors: colors),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SangeetaLogo(
                    size: widget.compact ? 94 : 260,
                    showTagline: false,
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.category + ' • Dance Mode',
                      style: const TextStyle(
                        color: AppTheme.gold2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
