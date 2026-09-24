import 'dart:convert';

import 'package:flutter/material.dart';

const String _sangeetaReferenceJpeg = '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';

class SangeetaReferenceAvatar extends StatefulWidget {
  const SangeetaReferenceAvatar({
    required this.outfit,
    this.width = 120,
    this.height = 190,
    this.speaking = false,
    this.dancing = false,
    this.seated = false,
    super.key,
  });

  final AvatarOutfit outfit;
  final double width;
  final double height;
  final bool speaking;
  final bool dancing;
  final bool seated;

  @override
  State<SangeetaReferenceAvatar> createState() => _SangeetaReferenceAvatarState();
}

class _SangeetaReferenceAvatarState extends State<SangeetaReferenceAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.dancing ? 650 : 1350),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SangeetaReferenceAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dancing != widget.dancing) {
      _controller.duration = Duration(
        milliseconds: widget.dancing ? 650 : 1350,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final sway = widget.dancing ? 0.025 * math.sin(t * math.pi * 2) : 0.006 * math.sin(t * math.pi * 2);
    final lift = widget.dancing ? -5 * math.max(0, math.sin(t * math.pi * 2)) : 0.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.translate(
        offset: Offset(
          widget.seated ? 0 : 18 * sway,
          widget.seated ? 10 : lift,
        ),
        child: Transform.rotate(
          angle: sway,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(widget.width * .18),
                child: Image.memory(
                  base64Decode(_sangeetaReferenceJpeg),
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ReferenceOutfitPainter(
                    outfit: widget.outfit,
                    phase: t,
                    speaking: widget.speaking,
                    seated: widget.seated,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceOutfitPainter extends CustomPainter {
  const _ReferenceOutfitPainter({
    required this.outfit,
    required this.phase,
    required this.speaking,
    required this.seated,
  });

  final AvatarOutfit outfit;
  final double phase;
  final bool speaking;
  final bool seated;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyTop = h * .34;
    final waist = h * .57;
    final bottom = h * .99;

    final paint = Paint()..style = PaintingStyle.fill;

    // Opaque clothing overlays keep the same reference identity while
    // letting the wardrobe change safely and visibly.
    switch (outfit) {
      case AvatarOutfit.romantic:
        paint.color = const Color(0xFFE7A1B8).withValues(alpha: .88);
        canvas.drawPath(
          Path()
            ..moveTo(w * .22, bodyTop)
            ..quadraticBezierTo(w * .50, h * .29, w * .78, bodyTop)
            ..lineTo(w * .92, bottom)
            ..lineTo(w * .08, bottom)
            ..close(),
          paint,
        );
        _goldTrim(canvas, w, h, const Color(0xFFFFD6E2));
        break;
      case AvatarOutfit.party:
        paint.color = const Color(0xFFC99522).withValues(alpha: .90);
        canvas.drawPath(
          Path()
            ..moveTo(w * .18, bodyTop)
            ..quadraticBezierTo(w * .50, h * .27, w * .82, bodyTop)
            ..lineTo(w * .88, bottom)
            ..lineTo(w * .12, bottom)
            ..close(),
          paint,
        );
        _goldTrim(canvas, w, h, const Color(0xFFFFE19A));
        break;
      case AvatarOutfit.formalSuit:
        paint.color = const Color(0xFF121212).withValues(alpha: .94);
        canvas.drawPath(
          Path()
            ..moveTo(w * .18, bodyTop)
            ..lineTo(w * .41, bodyTop)
            ..lineTo(w * .50, h * .47)
            ..lineTo(w * .59, bodyTop)
            ..lineTo(w * .82, bodyTop)
            ..lineTo(w * .76, bottom)
            ..lineTo(w * .24, bottom)
            ..close(),
          paint,
        );
        paint.color = Colors.white.withValues(alpha: .92);
        canvas.drawPath(
          Path()
            ..moveTo(w * .43, bodyTop)
            ..lineTo(w * .50, h * .46)
            ..lineTo(w * .57, bodyTop)
            ..close(),
          paint,
        );
        paint.color = const Color(0xFFFFC857);
        canvas.drawRect(Rect.fromLTWH(w * .48, h * .43, w * .04, h * .22), paint);
        break;
      case AvatarOutfit.traditionalOdia:
        paint.color = const Color(0xFFB33A2E).withValues(alpha: .90);
        canvas.drawPath(
          Path()
            ..moveTo(w * .16, bodyTop)
            ..lineTo(w * .84, bodyTop)
            ..lineTo(w * .92, bottom)
            ..lineTo(w * .08, bottom)
            ..close(),
          paint,
        );
        paint.color = const Color(0xFFF5D27E).withValues(alpha: .95);
        canvas.drawPath(
          Path()
            ..moveTo(w * .58, bodyTop)
            ..quadraticBezierTo(w * .42, waist, w * .28, bottom)
            ..lineTo(w * .47, bottom)
            ..quadraticBezierTo(w * .58, waist, w * .70, h * .44)
            ..close(),
          paint,
        );
        _goldTrim(canvas, w, h, const Color(0xFFFFD96A));
        break;
      case AvatarOutfit.gymChill:
        paint.color = const Color(0xFF263F66).withValues(alpha: .92);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .18, bodyTop, w * .64, h * .63),
            Radius.circular(w * .10),
          ),
          paint,
        );
        paint.color = const Color(0xFF80C7E8).withValues(alpha: .94);
        canvas.drawRect(Rect.fromLTWH(w * .18, h * .69, w * .64, h * .27), paint);
        break;
      case AvatarOutfit.resortSwimwear:
        paint.color = const Color(0xFF2D8D96).withValues(alpha: .88);
        canvas.drawPath(
          Path()
            ..moveTo(w * .22, bodyTop)
            ..quadraticBezierTo(w * .50, h * .28, w * .78, bodyTop)
            ..lineTo(w * .85, bottom)
            ..lineTo(w * .15, bottom)
            ..close(),
          paint,
        );
        paint.color = Colors.white.withValues(alpha: .22);
        canvas.drawPath(
          Path()
            ..moveTo(w * .12, h * .42)
            ..quadraticBezierTo(w * .50, h * .68, w * .88, h * .40)
            ..lineTo(w * .82, h * .95)
            ..lineTo(w * .18, h * .95)
            ..close(),
          paint,
        );
        break;
      case AvatarOutfit.nightSatin:
        paint.color = const Color(0xFF624A78).withValues(alpha: .92);
        canvas.drawPath(
          Path()
            ..moveTo(w * .18, bodyTop)
            ..quadraticBezierTo(w * .50, h * .28, w * .82, bodyTop)
            ..lineTo(w * .90, bottom)
            ..lineTo(w * .10, bottom)
            ..close(),
          paint,
        );
        _goldTrim(canvas, w, h, const Color(0xFFD7B6F0));
        break;
      case AvatarOutfit.casual:
        // The reference outfit itself remains visible for the everyday look.
        paint.color = const Color(0xFF0B0B0B).withValues(alpha: .05);
        canvas.drawRect(Rect.fromLTWH(0, bodyTop, w, h - bodyTop), paint);
        break;
    }

    if (speaking) {
      final pulse = .5 + .5 * math.sin(phase * math.pi * 12);
      canvas.drawCircle(
        Offset(w * .51, h * .31),
        w * (.028 + .006 * pulse),
        Paint()..color = const Color(0xFFFFC857).withValues(alpha: .28),
      );
    }

    if (seated) {
      paint.color = Colors.black.withValues(alpha: .18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .08, h * .76, w * .84, h * .22),
          Radius.circular(w * .10),
        ),
        paint,
      );
    }
  }

  void _goldTrim(Canvas canvas, double w, double h, Color color) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .018
      ..color = color.withValues(alpha: .9);
    canvas.drawLine(Offset(w * .10, h * .96), Offset(w * .90, h * .96), p);
  }

  @override
  bool shouldRepaint(covariant _ReferenceOutfitPainter oldDelegate) {
    return oldDelegate.outfit != outfit ||
        oldDelegate.phase != phase ||
        oldDelegate.speaking != speaking ||
        oldDelegate.seated != seated;
  }
}
