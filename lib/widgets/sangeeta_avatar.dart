import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/avatar_outfit.dart';

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
    this.size = 150,
    super.key,
  });

  final AvatarOutfit outfit;
  final SangeetaPose pose;
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
      duration: const Duration(milliseconds: 1150),
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
        final lift = isDance ? math.max(0, beat) * 7 : breathe * 1.5;
        final sway = isDance ? beat * 5 : math.sin(t * math.pi * 2) * 1.25;

        return Transform.translate(
          offset: Offset(sway, -lift),
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _SangeetaAvatarPainter(
              outfit: widget.outfit,
              pose: widget.pose,
              phase: t,
            ),
          ),
        );
      },
    );
  }
}

class _SangeetaAvatarPainter extends CustomPainter {
  const _SangeetaAvatarPainter({
    required this.outfit,
    required this.pose,
    required this.phase,
  });

  final AvatarOutfit outfit;
  final SangeetaPose pose;
  final double phase;

  static const skin = Color(0xFFE4A58D);
  static const skinShadow = Color(0xFFC97F67);
  static const hair = Color(0xFF1C1010);
  static const hairHighlight = Color(0xFF3A2020);
  static const eye = Color(0xFF35201B);
  static const lip = Color(0xFF9B4057);
  static const gold = Color(0xFFFFC857);

  Color get primary => switch (outfit) {
        AvatarOutfit.casual => const Color(0xFF2B6E63),
        AvatarOutfit.party => const Color(0xFF6F2F8E),
        AvatarOutfit.romantic => const Color(0xFFE05A79),
        AvatarOutfit.traditionalOdia => const Color(0xFFD39A28),
        AvatarOutfit.gymChill => const Color(0xFF2B6FA7),
        AvatarOutfit.resortSwimwear => const Color(0xFF238B97),
        AvatarOutfit.nightSatin => const Color(0xFF5A416F),
      };

  Color get accent => switch (outfit) {
        AvatarOutfit.casual => const Color(0xFFB8D8D0),
        AvatarOutfit.party => const Color(0xFFE2B5FF),
        AvatarOutfit.romantic => const Color(0xFFFFB4C8),
        AvatarOutfit.traditionalOdia => const Color(0xFFF2DA9A),
        AvatarOutfit.gymChill => const Color(0xFFAED2F0),
        AvatarOutfit.resortSwimwear => const Color(0xFF9EE4E7),
        AvatarOutfit.nightSatin => const Color(0xFFDCC9EB),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = s / 2;
    final poseFactor = switch (pose) {
      SangeetaPose.listening => .96,
      SangeetaPose.speaking => 1.02,
      _ => 1.0,
    };

    // Soft stage halo keeps the character readable on the black/gold UI.
    canvas.drawCircle(
      Offset(c, s * .52),
      s * .44,
      Paint()..color = primary.withValues(alpha: .13),
    );
    canvas.drawCircle(
      Offset(c, s * .52),
      s * .40,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .012
        ..color = gold.withValues(alpha: .25),
    );

    final bodyScale = poseFactor;
    final shoulderY = s * .47;
    final waistY = s * .67;
    final hipY = s * .76;

    final skinPaint = Paint()..color = skin;
    final shadowPaint = Paint()..color = skinShadow;

    // Long, consistent adult proportions: large head, narrow waist and
    // balanced hips/legs. The same geometry is reused for every pose/outfit.
    final leftLegX = c - s * .075;
    final rightLegX = c + s * .075;
    final legBottom = pose == SangeetaPose.sit ? s * .91 : s * .985;
    final legTop = pose == SangeetaPose.sit ? hipY : s * .70;

    for (final x in [leftLegX, rightLegX]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - s * .028,
            legTop,
            s * .056,
            (legBottom - legTop).clamp(s * .08, s * .30).toDouble(),
          ),
          Radius.circular(s * .028),
        ),
        skinPaint,
      );
    }

    final shoePaint = Paint()..color = const Color(0xFF12100E);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(leftLegX - (pose == SangeetaPose.previous ? s * .04 : 0), s * .985),
        width: s * .16,
        height: s * .055,
      ),
      shoePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rightLegX + (pose == SangeetaPose.next ? s * .04 : 0), s * .985),
        width: s * .16,
        height: s * .055,
      ),
      shoePaint,
    );

    // Torso / outfit silhouette.
    final shoulderLeft = s * (.36 / bodyScale);
    final shoulderRight = s * (.64 * bodyScale);
    final torsoPath = Path()
      ..moveTo(shoulderLeft, shoulderY)
      ..quadraticBezierTo(c, s * .42, shoulderRight, shoulderY)
      ..quadraticBezierTo(s * .69, s * .58, s * .62, hipY)
      ..quadraticBezierTo(c, s * .82, s * .38, hipY)
      ..quadraticBezierTo(s * .31, s * .58, shoulderLeft, shoulderY)
      ..close();

    canvas.drawPath(
      torsoPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, primary],
        ).createShader(Rect.fromLTWH(s * .28, shoulderY, s * .44, s * .37)),
    );

    // Outfit-specific detailing.
    if (outfit == AvatarOutfit.romantic ||
        outfit == AvatarOutfit.resortSwimwear) {
      final bikini = Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .035
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(s * .39, s * .50),
        Offset(c, s * .58),
        bikini,
      );
      canvas.drawLine(
        Offset(c, s * .58),
        Offset(s * .61, s * .50),
        bikini,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s * .39, s * .69, s * .22, s * .075),
          Radius.circular(s * .025),
        ),
        Paint()..color = primary.darken(),
      );

      // A lightweight resort wrap keeps the look glamorous and clearly
      // presented as swimwear rather than intimate clothing.
      canvas.drawPath(
        Path()
          ..moveTo(s * .30, s * .56)
          ..quadraticBezierTo(c, s * .69, s * .70, s * .56)
          ..lineTo(s * .64, s * .76)
          ..quadraticBezierTo(c, s * .70, s * .36, s * .76)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: .16),
      );
    }

    if (outfit == AvatarOutfit.traditionalOdia) {
      final drape = Paint()..color = const Color(0xFFF1DFA5);
      canvas.drawPath(
        Path()
          ..moveTo(s * .34, s * .50)
          ..quadraticBezierTo(s * .52, s * .59, s * .68, s * .75)
          ..lineTo(s * .58, s * .80)
          ..quadraticBezierTo(s * .46, s * .65, s * .28, s * .57)
          ..close(),
        drape,
      );
      canvas.drawLine(
        Offset(s * .35, waistY),
        Offset(s * .65, waistY),
        Paint()
          ..color = gold
          ..strokeWidth = s * .014,
      );
    }

    if (outfit == AvatarOutfit.party) {
      canvas.drawLine(
        Offset(s * .38, s * .74),
        Offset(s * .62, s * .74),
        Paint()
          ..color = gold
          ..strokeWidth = s * .016,
      );
    }

    // Arms are pose-driven. Previous/next point toward the matching control.
    final shoulderL = Offset(s * .37, s * .50);
    final shoulderR = Offset(s * .63, s * .50);
    final leftEnd = switch (pose) {
      SangeetaPose.dance => Offset(s * .15, s * (.36 + .05 * math.sin(phase * math.pi * 2))),
      SangeetaPose.next => Offset(s * .82, s * .32),
      SangeetaPose.previous => Offset(s * .19, s * .32),
      SangeetaPose.greeting => Offset(s * .76, s * .24),
      SangeetaPose.listening => Offset(s * .29, s * .43),
      SangeetaPose.speaking => Offset(s * .25, s * .47),
      _ => Offset(s * .23, s * .63),
    };
    final rightEnd = switch (pose) {
      SangeetaPose.dance => Offset(s * .86, s * (.43 - .05 * math.sin(phase * math.pi * 2))),
      SangeetaPose.next => Offset(s * .86, s * .36),
      SangeetaPose.previous => Offset(s * .18, s * .36),
      SangeetaPose.greeting => Offset(s * .79, s * .29),
      SangeetaPose.listening => Offset(s * .71, s * .43),
      SangeetaPose.speaking => Offset(s * .75, s * .47),
      _ => Offset(s * .77, s * .63),
    };

    final arms = Paint()
      ..color = skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .068
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulderL, leftEnd, arms);
    canvas.drawLine(shoulderR, rightEnd, arms);

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .455, s * .36, s * .09, s * .14),
        Radius.circular(s * .03),
      ),
      skinPaint,
    );

    // Hair mass with subtle highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c, s * .22),
        width: s * .40,
        height: s * .44,
      ),
      Paint()..color = hair,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c, s * .22),
        width: s * .37,
        height: s * .40,
      ),
      math.pi * .95,
      math.pi * 1.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .026
        ..color = hairHighlight,
    );

    // Face: fixed facial landmarks keep Sangeeta's identity consistent.
    final faceCenter = Offset(c, s * .285);
    final face = Paint()..color = skin;
    canvas.drawOval(
      Rect.fromCenter(
        center: faceCenter,
        width: s * .31,
        height: s * .38,
      ),
      face,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c, s * .45),
        width: s * .18,
        height: s * .09,
      ),
      Paint()..color = skinShadow.withValues(alpha: .16),
    );

    // Brows, almond eyes, pupils.
    final features = Paint()
      ..color = eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .010
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(s * .405, s * .245, s * .075, s * .035), math.pi, math.pi, false, features);
    canvas.drawArc(Rect.fromLTWH(s * .520, s * .245, s * .075, s * .035), math.pi, math.pi, false, features);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * .45, s * .30), width: s * .065, height: s * .034),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * .55, s * .30), width: s * .065, height: s * .034),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(Offset(s * .45, s * .30), s * .014, Paint()..color = eye);
    canvas.drawCircle(Offset(s * .55, s * .30), s * .014, Paint()..color = eye);

    // Nose and soft smile / speaking mouth.
    canvas.drawLine(Offset(c, s * .31), Offset(c - s * .008, s * .355), features);
    if (pose == SangeetaPose.speaking) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c, s * .385), width: s * .075, height: s * .042),
        Paint()..color = lip,
      );
    } else {
      canvas.drawArc(
        Rect.fromLTWH(s * .462, s * .358, s * .076, s * .060),
        0,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .012
          ..strokeCap = StrokeCap.round
          ..color = lip,
      );
    }

    // Headphones and earrings.
    final headphoneStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .022
      ..color = const Color(0xFF0B0A09);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c, s * .28),
        width: s * .40,
        height: s * .43,
      ),
      math.pi,
      math.pi,
      false,
      headphoneStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .305, s * .28, s * .070, s * .115),
        Radius.circular(s * .025),
      ),
      Paint()..color = gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .625, s * .28, s * .070, s * .115),
        Radius.circular(s * .025),
      ),
      Paint()..color = gold,
    );

    canvas.drawCircle(Offset(s * .405, s * .36), s * .015, Paint()..color = gold);
    canvas.drawCircle(Offset(s * .595, s * .36), s * .015, Paint()..color = gold);

    // Listening/speaking indicators.
    if (pose == SangeetaPose.listening) {
      canvas.drawArc(
        Rect.fromCenter(
          center: faceCenter,
          width: s * .43,
          height: s * .50,
        ),
        math.pi * 1.1,
        math.pi * .8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .013
          ..color = gold.withValues(alpha: .7),
      );
    }
    if (pose == SangeetaPose.speaking) {
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(s * (.66 + i * .045), s * (.19 - (i % 2) * .03)),
          s * .012,
          Paint()..color = gold.withValues(alpha: .72 - i * .16),
        );
      }
    }

    if (pose == SangeetaPose.sit) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c, s * .79),
          width: s * .48,
          height: s * .15,
        ),
        0,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .018
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SangeetaAvatarPainter oldDelegate) =>
      oldDelegate.outfit != outfit ||
      oldDelegate.pose != pose ||
      oldDelegate.phase != phase;
}

extension on Color {
  Color darken([double amount = .18]) {
    final factor = (1 - amount).clamp(0.0, 1.0);
    return Color.fromARGB(
      alpha,
      (red * factor).round(),
      (green * factor).round(),
      (blue * factor).round(),
    );
  }
}
