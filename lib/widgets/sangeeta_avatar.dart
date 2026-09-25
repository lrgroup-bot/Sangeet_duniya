import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';
import '../models/sangeeta_likeness.dart';
import '../models/wardrobe_profile.dart';

enum SangeetaPose {
  idle,
  dance,
  sit,
  next,
  previous,
  greeting,
  listening,
  speaking,
}

class SangeetaAvatar extends StatefulWidget {
  const SangeetaAvatar({
    required this.outfit,
    required this.pose,
    this.category,
    this.hairstyle = Hairstyle.longWave,
    this.speechMouthOpen,
    this.speechMouthWidth,
    this.speechMouthRoundness,
    this.size = 150,
    super.key,
  });

  final AvatarOutfit outfit;
  final WardrobeCategory? category;
  final Hairstyle hairstyle;
  final SangeetaPose pose;
  final double? speechMouthOpen;
  final double? speechMouthWidth;
  final double? speechMouthRoundness;
  final double size;

  @override
  State<SangeetaAvatar> createState() => _SangeetaAvatarState();
}

class _SangeetaAvatarState extends State<SangeetaAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1180),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final beat = math.sin(t * math.pi * 2);
        final breathe = math.sin(t * math.pi * 2) * .5 + .5;
        final isDance = widget.pose == SangeetaPose.dance;
        final lift = isDance ? math.max(0, beat) * 6.0 : breathe * 1.1;
        final sway = isDance ? beat * 4.8 : math.sin(t * math.pi * 2) * .85;

        return Transform.translate(
          offset: Offset(sway, -lift),
          child: Transform.rotate(
            angle: isDance ? beat * .015 : 0,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _SangeetaAvatarPainter(
                outfit: widget.outfit,
                category:
                    widget.category ?? _categoryForOutfit(widget.outfit),
                hairstyle: widget.hairstyle,
                pose: widget.pose,
                phase: t,
                speechMouthOpen: widget.speechMouthOpen,
                speechMouthWidth: widget.speechMouthWidth,
                speechMouthRoundness: widget.speechMouthRoundness,
              ),
            ),
          ),
        );
      },
    );
  }
}

WardrobeCategory _categoryForOutfit(AvatarOutfit value) => switch (value) {
      AvatarOutfit.casual => WardrobeCategory.casual,
      AvatarOutfit.party => WardrobeCategory.party,
      AvatarOutfit.romantic => WardrobeCategory.romantic,
      AvatarOutfit.traditionalOdia => WardrobeCategory.traditionalOdia,
      AvatarOutfit.gymChill => WardrobeCategory.gymWear,
      AvatarOutfit.resortSwimwear => WardrobeCategory.beachResort,
      AvatarOutfit.nightSatin => WardrobeCategory.nightWear,
    };

class _SangeetaAvatarPainter extends CustomPainter {
  const _SangeetaAvatarPainter({
    required this.outfit,
    required this.category,
    required this.hairstyle,
    required this.pose,
    required this.phase,
    required this.speechMouthOpen,
    required this.speechMouthWidth,
    required this.speechMouthRoundness,
  });

  final AvatarOutfit outfit;
  final WardrobeCategory category;
  final Hairstyle hairstyle;
  final SangeetaPose pose;
  final double phase;
  final double? speechMouthOpen;
  final double? speechMouthWidth;
  final double? speechMouthRoundness;

  Color get primary => switch (category) {
        WardrobeCategory.casual => const Color(0xFF67584E),
        WardrobeCategory.party => const Color(0xFFB38A18),
        WardrobeCategory.romantic => const Color(0xFF9C4562),
        WardrobeCategory.traditionalOdia => const Color(0xFFD7B56D),
        WardrobeCategory.djStage => const Color(0xFF2D2B38),
        WardrobeCategory.gymWear => const Color(0xFFB36B45),
        WardrobeCategory.beachResort => const Color(0xFF277D7D),
        WardrobeCategory.nightWear => const Color(0xFF56415F),
        WardrobeCategory.festival => const Color(0xFF9A2F35),
        WardrobeCategory.winter => const Color(0xFF6A574B),
      };

  Color get accent => switch (category) {
        WardrobeCategory.casual => const Color(0xFF171717),
        WardrobeCategory.party => const Color(0xFFE9C85D),
        WardrobeCategory.romantic => const Color(0xFFE7A5B6),
        WardrobeCategory.traditionalOdia => const Color(0xFF343036),
        WardrobeCategory.djStage => const Color(0xFFFFC857),
        WardrobeCategory.gymWear => const Color(0xFF6B3F2E),
        WardrobeCategory.beachResort => const Color(0xFFB8E2D8),
        WardrobeCategory.nightWear => const Color(0xFFD5B8D9),
        WardrobeCategory.festival => const Color(0xFFF1C86A),
        WardrobeCategory.winter => const Color(0xFFC7B1A4),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = s / 2;
    final beat = math.sin(phase * math.pi * 2);
    final bodyShift = pose == SangeetaPose.dance ? beat * s * .007 : 0.0;

    _paintHalo(canvas, s, c);
    _paintBackHair(canvas, s, c, beat);
    _paintLegs(canvas, s, c, bodyShift);
    _paintTorsoAndOutfit(canvas, s, c, bodyShift);
    _paintArms(canvas, s, bodyShift);
    _paintNeck(canvas, s, c, bodyShift);
    _paintFace(canvas, s, c, bodyShift);
    _paintFrontHair(canvas, s, c, beat, bodyShift);
    _paintPoseEffects(canvas, s, c);
  }

  void _paintHalo(Canvas canvas, double s, double c) {
    canvas.drawCircle(
      Offset(c, s * .51),
      s * .45,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: .16),
            primary.withValues(alpha: .04),
            Colors.transparent,
          ],
          stops: const [0, .7, 1],
        ).createShader(
          Rect.fromCircle(center: Offset(c, s * .51), radius: s * .45),
        ),
    );
    canvas.drawCircle(
      Offset(c, s * .51),
      s * .43,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .006
        ..color = SangeetaLikeness.gold.withValues(alpha: .24),
    );
  }

  void _paintBackHair(Canvas canvas, double s, double c, double beat) {
    final sway = beat * s * .010;
    final paint = Paint()..color = SangeetaLikeness.hair;
    final highlight = Paint()
      ..color = SangeetaLikeness.hairLight.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .014
      ..strokeCap = StrokeCap.round;

    switch (hairstyle) {
      case Hairstyle.longWave:
      case Hairstyle.stageWave:
        final width = hairstyle == Hairstyle.stageWave ? .43 : .39;
        final bottom = hairstyle == Hairstyle.stageWave ? .67 : .63;
        final left = Path()
          ..moveTo(c - s * .06, s * .10)
          ..cubicTo(
            c - s * .25,
            s * .12,
            c - s * .24 + sway,
            s * .40,
            c - s * .19 + sway,
            s * bottom,
          )
          ..cubicTo(
            c - s * .11,
            s * .55,
            c - s * .10,
            s * .24,
            c - s * .02,
            s * .13,
          )
          ..close();
        final right = Path()
          ..moveTo(c + s * .04, s * .10)
          ..cubicTo(
            c + s * width,
            s * .16,
            c + s * .24 + sway,
            s * .40,
            c + s * .18 + sway,
            s * bottom,
          )
          ..cubicTo(
            c + s * .10,
            s * .51,
            c + s * .10,
            s * .24,
            c + s * .01,
            s * .13,
          )
          ..close();
        canvas.drawPath(left, paint);
        canvas.drawPath(right, paint);

        for (final x in <double>[-.15, -.11, .11, .16]) {
          canvas.drawPath(
            Path()
              ..moveTo(c + s * x, s * .20)
              ..cubicTo(
                c + s * (x - .05),
                s * .31,
                c + s * (x + .05) + sway,
                s * .42,
                c + s * x + sway,
                s * .56,
              ),
            highlight,
          );
        }
        break;
      case Hairstyle.ponytail:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c, s * .18),
            width: s * .34,
            height: s * .28,
          ),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(c + s * .10, s * .18)
            ..cubicTo(
              c + s * .30,
              s * .25,
              c + s * .28 + sway,
              s * .46,
              c + s * .17 + sway,
              s * .60,
            ),
          Paint()
            ..color = SangeetaLikeness.hair
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .10
            ..strokeCap = StrokeCap.round,
        );
        break;
      case Hairstyle.braid:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c, s * .18),
            width: s * .34,
            height: s * .28,
          ),
          paint,
        );
        for (var i = 0; i < 7; i++) {
          final y = s * (.31 + i * .055);
          final x = c + s * (.14 + (i.isEven ? .012 : -.012));
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x + sway, y),
              width: s * .075,
              height: s * .058,
            ),
            paint,
          );
        }
        break;
      case Hairstyle.bun:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c, s * .18),
            width: s * .34,
            height: s * .28,
          ),
          paint,
        );
        canvas.drawCircle(
          Offset(c, s * .075),
          s * .085,
          paint,
        );
        break;
    }
  }

  void _paintLegs(Canvas canvas, double s, double c, double bodyShift) {
    final skinPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          SangeetaLikeness.skinLight,
          SangeetaLikeness.skin,
          SangeetaLikeness.skinShadow,
        ],
      ).createShader(Rect.fromLTWH(s * .35, s * .68, s * .30, s * .30));

    if (pose == SangeetaPose.sit) {
      final legPaint = Paint()
        ..color = SangeetaLikeness.skin
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .065
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(c - s * .06 + bodyShift, s * .74),
        Offset(c - s * .16, s * .91),
        legPaint,
      );
      canvas.drawLine(
        Offset(c + s * .06 + bodyShift, s * .74),
        Offset(c + s * .18, s * .91),
        legPaint,
      );
      return;
    }

    for (final x in <double>[c - s * .073, c + s * .073]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - s * .032 + bodyShift,
            s * .70,
            s * .064,
            s * .265,
          ),
          Radius.circular(s * .032),
        ),
        skinPaint,
      );
    }
  }

  void _paintTorsoAndOutfit(
    Canvas canvas,
    double s,
    double c,
    double bodyShift,
  ) {
    final torso = Path()
      ..moveTo(c - s * .14 + bodyShift, s * .43)
      ..cubicTo(
        c - s * .20 + bodyShift,
        s * .48,
        c - s * .18 + bodyShift,
        s * .60,
        c - s * .13 + bodyShift,
        s * .73,
      )
      ..quadraticBezierTo(
        c + bodyShift,
        s * .80,
        c + s * .13 + bodyShift,
        s * .73,
      )
      ..cubicTo(
        c + s * .18 + bodyShift,
        s * .60,
        c + s * .20 + bodyShift,
        s * .48,
        c + s * .14 + bodyShift,
        s * .43,
      )
      ..quadraticBezierTo(
        c + bodyShift,
        s * .39,
        c - s * .14 + bodyShift,
        s * .43,
      )
      ..close();

    final outfitPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, primary, primary.withValues(alpha: .86)],
      ).createShader(Rect.fromLTWH(s * .28, s * .41, s * .44, s * .40));
    canvas.drawPath(torso, outfitPaint);

    switch (category) {
      case WardrobeCategory.casual:
        _paintCropTop(
          canvas,
          s,
          c,
          bodyShift,
          const Color(0xFF857163),
          const Color(0xFF1B1B1B),
        );
        _paintGoldBelt(canvas, s, c, bodyShift);
        break;
      case WardrobeCategory.party:
        _paintDressSheen(canvas, s, c, bodyShift);
        break;
      case WardrobeCategory.romantic:
        _paintNeckline(canvas, s, c, bodyShift, accent);
        _paintDressSheen(canvas, s, c, bodyShift);
        break;
      case WardrobeCategory.traditionalOdia:
        _paintTraditional(canvas, s, c, bodyShift, false);
        break;
      case WardrobeCategory.djStage:
        _paintCropTop(
          canvas,
          s,
          c,
          bodyShift,
          const Color(0xFF24222D),
          const Color(0xFF14131A),
        );
        _paintGoldBelt(canvas, s, c, bodyShift);
        canvas.drawLine(
          Offset(c - s * .14 + bodyShift, s * .48),
          Offset(c + s * .14 + bodyShift, s * .48),
          Paint()
            ..color = SangeetaLikeness.gold
            ..strokeWidth = s * .010,
        );
        break;
      case WardrobeCategory.gymWear:
        _paintSportsSet(canvas, s, c, bodyShift);
        break;
      case WardrobeCategory.beachResort:
        _paintResortSet(canvas, s, c, bodyShift);
        break;
      case WardrobeCategory.nightWear:
        _paintNeckline(canvas, s, c, bodyShift, const Color(0xFFD6BDD9));
        _paintDressSheen(canvas, s, c, bodyShift);
        break;
      case WardrobeCategory.festival:
        _paintTraditional(canvas, s, c, bodyShift, true);
        break;
      case WardrobeCategory.winter:
        _paintWinter(canvas, s, c, bodyShift);
        break;
    }
  }

  void _paintCropTop(
    Canvas canvas,
    double s,
    double c,
    double bodyShift,
    Color top,
    Color bottom,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .14 + bodyShift,
          s * .44,
          s * .28,
          s * .125,
        ),
        Radius.circular(s * .03),
      ),
      Paint()..color = top,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .135 + bodyShift,
          s * .625,
          s * .27,
          s * .13,
        ),
        Radius.circular(s * .025),
      ),
      Paint()..color = bottom,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c + bodyShift, s * .595),
        width: s * .020,
        height: s * .012,
      ),
      Paint()..color = SangeetaLikeness.skinShadow.withValues(alpha: .65),
    );
  }

  void _paintGoldBelt(Canvas canvas, double s, double c, double bodyShift) {
    canvas.drawLine(
      Offset(c - s * .13 + bodyShift, s * .64),
      Offset(c + s * .13 + bodyShift, s * .64),
      Paint()
        ..color = SangeetaLikeness.gold
        ..strokeWidth = s * .012,
    );
    for (final x in <double>[-.09, -.045, 0, .045, .09]) {
      canvas.drawCircle(
        Offset(c + s * x + bodyShift, s * .64),
        s * .017,
        Paint()..color = const Color(0xFFD6A62D),
      );
    }
  }

  void _paintDressSheen(Canvas canvas, double s, double c, double bodyShift) {
    canvas.drawPath(
      Path()
        ..moveTo(c - s * .075 + bodyShift, s * .46)
        ..quadraticBezierTo(
          c - s * .015 + bodyShift,
          s * .58,
          c - s * .045 + bodyShift,
          s * .73,
        ),
      Paint()
        ..color = Colors.white.withValues(alpha: .17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .015
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintNeckline(
    Canvas canvas,
    double s,
    double c,
    double bodyShift,
    Color color,
  ) {
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c + bodyShift, s * .445),
        width: s * .17,
        height: s * .09,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .018,
    );
  }

  void _paintTraditional(
    Canvas canvas,
    double s,
    double c,
    double bodyShift,
    bool festival,
  ) {
    final drape = festival ? const Color(0xFFF0C75E) : const Color(0xFFE8D09B);
    canvas.drawPath(
      Path()
        ..moveTo(c - s * .14 + bodyShift, s * .46)
        ..cubicTo(
          c - s * .04 + bodyShift,
          s * .50,
          c + s * .03 + bodyShift,
          s * .60,
          c + s * .14 + bodyShift,
          s * .74,
        )
        ..lineTo(c + s * .08 + bodyShift, s * .78)
        ..cubicTo(
          c - s * .02 + bodyShift,
          s * .64,
          c - s * .10 + bodyShift,
          s * .57,
          c - s * .17 + bodyShift,
          s * .52,
        )
        ..close(),
      Paint()..color = drape.withValues(alpha: .92),
    );
    canvas.drawLine(
      Offset(c - s * .13 + bodyShift, s * .63),
      Offset(c + s * .13 + bodyShift, s * .63),
      Paint()
        ..color = SangeetaLikeness.gold
        ..strokeWidth = s * .012,
    );
  }

  void _paintSportsSet(Canvas canvas, double s, double c, double bodyShift) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .14 + bodyShift,
          s * .445,
          s * .28,
          s * .115,
        ),
        Radius.circular(s * .035),
      ),
      Paint()..color = const Color(0xFFC87850),
    );
    canvas.drawLine(
      Offset(c - s * .115 + bodyShift, s * .47),
      Offset(c + s * .115 + bodyShift, s * .47),
      Paint()
        ..color = const Color(0xFFF0B592)
        ..strokeWidth = s * .010,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .135 + bodyShift,
          s * .64,
          s * .27,
          s * .115,
        ),
        Radius.circular(s * .032),
      ),
      Paint()..color = const Color(0xFF5A3428),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c + bodyShift, s * .602),
        width: s * .020,
        height: s * .012,
      ),
      Paint()..color = SangeetaLikeness.skinShadow.withValues(alpha: .62),
    );
  }

  void _paintResortSet(Canvas canvas, double s, double c, double bodyShift) {
    final swim = Paint()..color = const Color(0xFF277D7D);
    canvas.drawPath(
      Path()
        ..moveTo(c - s * .13 + bodyShift, s * .47)
        ..quadraticBezierTo(
          c - s * .06 + bodyShift,
          s * .43,
          c + bodyShift,
          s * .51,
        )
        ..quadraticBezierTo(
          c + s * .06 + bodyShift,
          s * .43,
          c + s * .13 + bodyShift,
          s * .47,
        )
        ..lineTo(c + s * .09 + bodyShift, s * .56)
        ..quadraticBezierTo(
          c + bodyShift,
          s * .53,
          c - s * .09 + bodyShift,
          s * .56,
        )
        ..close(),
      swim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .125 + bodyShift,
          s * .665,
          s * .25,
          s * .085,
        ),
        Radius.circular(s * .028),
      ),
      swim,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c - s * .15 + bodyShift, s * .58)
        ..quadraticBezierTo(
          c + bodyShift,
          s * .69,
          c + s * .17 + bodyShift,
          s * .57,
        )
        ..lineTo(c + s * .14 + bodyShift, s * .77)
        ..quadraticBezierTo(
          c + bodyShift,
          s * .72,
          c - s * .13 + bodyShift,
          s * .77,
        )
        ..close(),
      Paint()..color = const Color(0x99D9EEE7),
    );
  }

  void _paintWinter(Canvas canvas, double s, double c, double bodyShift) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .16 + bodyShift,
          s * .43,
          s * .32,
          s * .26,
        ),
        Radius.circular(s * .045),
      ),
      Paint()..color = const Color(0xFF78675D),
    );
    for (var i = 0; i < 5; i++) {
      final y = s * (.46 + i * .045);
      canvas.drawLine(
        Offset(c - s * .135 + bodyShift, y),
        Offset(c + s * .135 + bodyShift, y),
        Paint()
          ..color = const Color(0xFFBDAA9D).withValues(alpha: .30)
          ..strokeWidth = s * .006,
      );
    }
  }

  void _paintArms(Canvas canvas, double s, double bodyShift) {
    final shoulderL = Offset(s * .37 + bodyShift, s * .48);
    final shoulderR = Offset(s * .63 + bodyShift, s * .48);

    final leftEnd = switch (pose) {
      SangeetaPose.dance => Offset(
          s * .16,
          s * (.35 + .045 * math.sin(phase * math.pi * 2)),
        ),
      SangeetaPose.next => Offset(s * .79, s * .34),
      SangeetaPose.previous => Offset(s * .20, s * .34),
      SangeetaPose.greeting => Offset(s * .24, s * .37),
      SangeetaPose.listening => Offset(s * .28, s * .43),
      SangeetaPose.speaking => Offset(s * .25, s * .50),
      SangeetaPose.sit => Offset(s * .34, s * .69),
      _ => Offset(s * .24, s * .64),
    };
    final rightEnd = switch (pose) {
      SangeetaPose.dance => Offset(
          s * .84,
          s * (.40 - .045 * math.sin(phase * math.pi * 2)),
        ),
      SangeetaPose.next => Offset(s * .85, s * .34),
      SangeetaPose.previous => Offset(s * .21, s * .34),
      SangeetaPose.greeting => Offset(
          s * .76,
          s * (.27 + .02 * math.sin(phase * math.pi * 4)),
        ),
      SangeetaPose.listening => Offset(s * .72, s * .43),
      SangeetaPose.speaking => Offset(s * .75, s * .50),
      SangeetaPose.sit => Offset(s * .66, s * .69),
      _ => Offset(s * .76, s * .64),
    };

    final arms = Paint()
      ..shader = const LinearGradient(
        colors: [
          SangeetaLikeness.skinLight,
          SangeetaLikeness.skin,
          SangeetaLikeness.skinShadow,
        ],
      ).createShader(Rect.fromLTWH(s * .15, s * .30, s * .70, s * .45))
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .057
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(shoulderL, leftEnd, arms);
    canvas.drawLine(shoulderR, rightEnd, arms);

    if (pose == SangeetaPose.greeting) {
      final finger = Paint()
        ..color = SangeetaLikeness.skin
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .010
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(rightEnd.dx, rightEnd.dy),
          Offset(
            rightEnd.dx + s * (.02 + i * .012),
            rightEnd.dy - s * (.035 - i * .005),
          ),
          finger,
        );
      }
    }
  }

  void _paintNeck(Canvas canvas, double s, double c, double bodyShift) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          c - s * .045 + bodyShift,
          s * .35,
          s * .09,
          s * .115,
        ),
        Radius.circular(s * .035),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            SangeetaLikeness.skinLight,
            SangeetaLikeness.skin,
            SangeetaLikeness.skinShadow,
          ],
        ).createShader(Rect.fromLTWH(c - s * .05, s * .35, s * .10, s * .13)),
    );
  }

  void _paintFace(Canvas canvas, double s, double c, double bodyShift) {
    final faceCenter = Offset(c + bodyShift, s * .265);

    canvas.drawOval(
      Rect.fromCenter(
        center: faceCenter,
        width: s * .285,
        height: s * .345,
      ),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.22, -.30),
          radius: .95,
          colors: [
            SangeetaLikeness.skinLight,
            SangeetaLikeness.skin,
            SangeetaLikeness.skinShadow,
          ],
          stops: [0, .67, 1],
        ).createShader(
          Rect.fromCenter(
            center: faceCenter,
            width: s * .30,
            height: s * .36,
          ),
        ),
    );

    final brow = Paint()
      ..color = SangeetaLikeness.brow
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .010
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(c - s * .105 + bodyShift, s * .205, s * .075, s * .040),
      math.pi,
      math.pi,
      false,
      brow,
    );
    canvas.drawArc(
      Rect.fromLTWH(c + s * .030 + bodyShift, s * .205, s * .075, s * .040),
      math.pi,
      math.pi,
      false,
      brow,
    );

    final blink = math.sin(phase * math.pi * 2) > .965;
    final eyeY = s * .267;
    final leftEye = Offset(c - s * .060 + bodyShift, eyeY);
    final rightEye = Offset(c + s * .060 + bodyShift, eyeY);

    if (blink) {
      final line = Paint()
        ..color = SangeetaLikeness.eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .008
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(leftEye.dx - s * .029, leftEye.dy),
        Offset(leftEye.dx + s * .029, leftEye.dy),
        line,
      );
      canvas.drawLine(
        Offset(rightEye.dx - s * .029, rightEye.dy),
        Offset(rightEye.dx + s * .029, rightEye.dy),
        line,
      );
    } else {
      for (final eyeCenter in <Offset>[leftEye, rightEye]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: s * .062,
            height: s * .033,
          ),
          Paint()..color = const Color(0xFFF7F1EE),
        );
        canvas.drawCircle(
          eyeCenter,
          s * .0145,
          Paint()..color = SangeetaLikeness.iris,
        );
        canvas.drawCircle(
          eyeCenter,
          s * .0085,
          Paint()..color = SangeetaLikeness.eye,
        );
        canvas.drawCircle(
          Offset(eyeCenter.dx - s * .004, eyeCenter.dy - s * .005),
          s * .0035,
          Paint()..color = Colors.white.withValues(alpha: .85),
        );
      }
    }

    final nose = Paint()
      ..color = SangeetaLikeness.skinShadow.withValues(alpha: .70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .006
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(c + bodyShift, s * .282)
        ..cubicTo(
          c - s * .006 + bodyShift,
          s * .305,
          c - s * .010 + bodyShift,
          s * .323,
          c + s * .003 + bodyShift,
          s * .334,
        ),
      nose,
    );

    _paintMouth(canvas, s, c, bodyShift);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c - s * .105 + bodyShift, s * .318),
        width: s * .052,
        height: s * .020,
      ),
      Paint()..color = const Color(0xFFD97B79).withValues(alpha: .13),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c + s * .105 + bodyShift, s * .318),
        width: s * .052,
        height: s * .020,
      ),
      Paint()..color = const Color(0xFFD97B79).withValues(alpha: .13),
    );
  }

  void _paintMouth(Canvas canvas, double s, double c, double bodyShift) {
    final mouthCenter = Offset(c + bodyShift, s * .372);
    if (pose == SangeetaPose.speaking) {
      final drivenOpen = speechMouthOpen;
      final pulse = .92 + .08 * math.sin(phase * math.pi * 6).abs();
      final open = drivenOpen == null
          ? (.38 + .34 * math.sin(phase * math.pi * 8).abs())
          : (drivenOpen * pulse).clamp(0.0, 1.0);
      final widthScale = (speechMouthWidth ?? 1.0).clamp(.55, 1.25);
      final roundness = (speechMouthRoundness ?? .15).clamp(0.0, 1.0);
      final width = s * .074 * widthScale * (1 - roundness * .10);
      final height = s * (.010 + .048 * open) * (1 + roundness * .18);

      canvas.drawOval(
        Rect.fromCenter(center: mouthCenter, width: width, height: height),
        Paint()..color = const Color(0xFF7B3041),
      );
      if (open > .18) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(mouthCenter.dx, mouthCenter.dy + height * .06),
            width: width * .82,
            height: height * .60,
          ),
          0,
          math.pi,
          false,
          Paint()
            ..color = SangeetaLikeness.lipHighlight
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .006,
        );
      }
      return;
    }

    final smiling = pose == SangeetaPose.greeting || pose == SangeetaPose.dance;
    canvas.drawPath(
      Path()
        ..moveTo(c - s * .040 + bodyShift, s * .366)
        ..quadraticBezierTo(
          c + bodyShift,
          s * (smiling ? .391 : .382),
          c + s * .043 + bodyShift,
          s * .365,
        )
        ..quadraticBezierTo(
          c + bodyShift,
          s * .374,
          c - s * .040 + bodyShift,
          s * .366,
        )
        ..close(),
      Paint()..color = SangeetaLikeness.lip,
    );
    canvas.drawLine(
      Offset(c - s * .022 + bodyShift, s * .368),
      Offset(c + s * .025 + bodyShift, s * .368),
      Paint()
        ..color = SangeetaLikeness.lipHighlight.withValues(alpha: .7)
        ..strokeWidth = s * .004
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintFrontHair(
    Canvas canvas,
    double s,
    double c,
    double beat,
    double bodyShift,
  ) {
    final strand = Paint()
      ..color = SangeetaLikeness.hair
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .030
      ..strokeCap = StrokeCap.round;
    final shine = Paint()
      ..color = SangeetaLikeness.hairLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .008
      ..strokeCap = StrokeCap.round;

    if (hairstyle == Hairstyle.bun || hairstyle == Hairstyle.ponytail) {
      canvas.drawArc(
        Rect.fromLTWH(c - s * .145 + bodyShift, s * .105, s * .29, s * .19),
        math.pi,
        math.pi,
        false,
        strand,
      );
      return;
    }

    final drift = beat * s * .008;
    canvas.drawPath(
      Path()
        ..moveTo(c - s * .11 + bodyShift, s * .145)
        ..cubicTo(
          c - s * .155 + bodyShift,
          s * .22,
          c - s * .145 + bodyShift + drift,
          s * .35,
          c - s * .11 + bodyShift + drift,
          s * .46,
        ),
      strand,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c + s * .075 + bodyShift, s * .135)
        ..cubicTo(
          c + s * .145 + bodyShift,
          s * .22,
          c + s * .155 + bodyShift + drift,
          s * .36,
          c + s * .13 + bodyShift + drift,
          s * .49,
        ),
      strand,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c + s * .06 + bodyShift, s * .15)
        ..cubicTo(
          c + s * .10 + bodyShift,
          s * .23,
          c + s * .10 + bodyShift,
          s * .31,
          c + s * .09 + bodyShift,
          s * .40,
        ),
      shine,
    );
  }

  void _paintPoseEffects(Canvas canvas, double s, double c) {
    if (pose == SangeetaPose.listening) {
      for (var i = 0; i < 2; i++) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c, s * .27),
            width: s * (.36 + i * .06),
            height: s * (.42 + i * .07),
          ),
          math.pi * 1.12,
          math.pi * .76,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .007
            ..color = SangeetaLikeness.gold.withValues(
              alpha: i == 0 ? .62 : .28,
            ),
        );
      }
    }

    if (pose == SangeetaPose.speaking) {
      for (var i = 0; i < 3; i++) {
        final pulse = .5 + .5 * math.sin(phase * math.pi * 6 + i);
        canvas.drawCircle(
          Offset(s * (.69 + i * .045), s * (.20 - i * .018)),
          s * (.006 + pulse * .006),
          Paint()..color = SangeetaLikeness.gold.withValues(alpha: .60),
        );
      }
    }

    if (pose == SangeetaPose.dance) {
      for (var i = 0; i < 3; i++) {
        final y = s * (.18 + i * .07);
        canvas.drawCircle(
          Offset(s * (.18 + .03 * math.sin(phase * math.pi * 2 + i)), y),
          s * .008,
          Paint()..color = SangeetaLikeness.gold.withValues(alpha: .46),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SangeetaAvatarPainter oldDelegate) =>
      oldDelegate.outfit != outfit ||
      oldDelegate.category != category ||
      oldDelegate.hairstyle != hairstyle ||
      oldDelegate.pose != pose ||
      oldDelegate.phase != phase ||
      oldDelegate.speechMouthOpen != speechMouthOpen ||
      oldDelegate.speechMouthWidth != speechMouthWidth ||
      oldDelegate.speechMouthRoundness != speechMouthRoundness;
}
