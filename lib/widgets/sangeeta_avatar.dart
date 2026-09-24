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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
        final beat = math.sin(_controller.value * math.pi);
        return Transform.translate(
          offset: widget.pose == SangeetaPose.dance
              ? Offset(math.sin(_controller.value * math.pi * 2) * 3, -beat * 5)
              : Offset.zero,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _SangeetaAvatarPainter(
              outfit: widget.outfit,
              pose: widget.pose,
              beat: beat,
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
    required this.beat,
  });

  final AvatarOutfit outfit;
  final SangeetaPose pose;
  final double beat;

  Color get primary => switch (outfit) {
        AvatarOutfit.casual => const Color(0xFF2E7D67),
        AvatarOutfit.party => const Color(0xFF6C2B88),
        AvatarOutfit.romantic => const Color(0xFF9A2D5D),
        AvatarOutfit.traditionalOdia => const Color(0xFFD79A22),
        AvatarOutfit.gymChill => const Color(0xFF2A6FB0),
        AvatarOutfit.resortSwimwear => const Color(0xFF24879A),
        AvatarOutfit.nightSatin => const Color(0xFF53406D),
      };

  Color get accent => switch (outfit) {
        AvatarOutfit.casual => const Color(0xFFB9DED2),
        AvatarOutfit.party => const Color(0xFFE2ABFF),
        AvatarOutfit.romantic => const Color(0xFFFFB8D4),
        AvatarOutfit.traditionalOdia => const Color(0xFFF0DA9B),
        AvatarOutfit.gymChill => const Color(0xFFAAD2FA),
        AvatarOutfit.resortSwimwear => const Color(0xFF9DE1EA),
        AvatarOutfit.nightSatin => const Color(0xFFD7C5EB),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = s / 2;
    const skinColor = Color(0xFFE2A286);
    final skin = Paint()..color = skinColor;
    final hair = Paint()..color = const Color(0xFF241311);
    final gold = Paint()..color = const Color(0xFFFFC857);

    canvas.drawCircle(
      Offset(c, s * .49),
      s * .39,
      Paint()..color = primary.withValues(alpha: .12),
    );

    final legY = pose == SangeetaPose.sit ? .84 : .80;
    final spread = pose == SangeetaPose.dance ? .04 : .0;

    for (final dx in <double>[-.08 + spread, .08 + spread]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c + s * dx, s * legY),
            width: s * .075,
            height: s * .30,
          ),
          Radius.circular(s * .03),
        ),
        skin,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c + s * dx, s * .96),
          width: s * .15,
          height: s * .055,
        ),
        Paint()..color = const Color(0xFF14100D),
      );
    }

    final outfitPath = Path()
      ..moveTo(s * .36, s * .48)
      ..quadraticBezierTo(c, s * .40, s * .64, s * .48)
      ..lineTo(s * .74, s * .75)
      ..quadraticBezierTo(c, s * .84, s * .26, s * .75)
      ..close();
    canvas.drawPath(
      outfitPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, primary],
        ).createShader(Rect.fromLTWH(s * .25, s * .40, s * .50, s * .38)),
    );

    if (outfit == AvatarOutfit.traditionalOdia) {
      final drape = Paint()..color = const Color(0xFFF2E0A8);
      canvas.drawPath(
        Path()
          ..moveTo(s * .33, s * .50)
          ..quadraticBezierTo(s * .52, s * .58, s * .68, s * .74)
          ..lineTo(s * .60, s * .77)
          ..quadraticBezierTo(s * .44, s * .61, s * .28, s * .57)
          ..close(),
        drape,
      );
    }

    final leftEnd = switch (pose) {
      SangeetaPose.dance => Offset(s * .14, s * .34 - beat * s * .05),
      SangeetaPose.next => Offset(s * .80, s * .34),
      SangeetaPose.previous => Offset(s * .20, s * .34),
      SangeetaPose.greeting => Offset(s * .76, s * .24),
      _ => Offset(s * .22, s * .62),
    };
    final rightEnd = switch (pose) {
      SangeetaPose.dance => Offset(s * .86, s * .45 + beat * s * .05),
      SangeetaPose.next => Offset(s * .84, s * .36),
      SangeetaPose.previous => Offset(s * .18, s * .36),
      SangeetaPose.greeting => Offset(s * .78, s * .28),
      _ => Offset(s * .78, s * .62),
    };
    final arms = Paint()
      ..color = skinColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .36, s * .52), leftEnd, arms);
    canvas.drawLine(Offset(s * .64, s * .52), rightEnd, arms);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .45, s * .35, s * .10, s * .12),
        Radius.circular(s * .025),
      ),
      skin,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c, s * .26),
        width: s * .30,
        height: s * .35,
      ),
      skin,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c, s * .18),
        width: s * .33,
        height: s * .25,
      ),
      hair,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * .37, s * .23)
        ..quadraticBezierTo(s * .28, s * .39, s * .40, s * .44)
        ..quadraticBezierTo(s * .33, s * .34, s * .35, s * .23)
        ..close(),
      hair,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * .63, s * .23)
        ..quadraticBezierTo(s * .72, s * .39, s * .60, s * .44)
        ..quadraticBezierTo(s * .67, s * .34, s * .65, s * .23)
        ..close(),
      hair,
    );

    final headphones = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .025
      ..color = const Color(0xFF0A0A0A);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c, s * .27),
        width: s * .35,
        height: s * .37,
      ),
      math.pi,
      math.pi,
      false,
      headphones,
    );
    final goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .010
      ..color = const Color(0xFFFFC857);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c, s * .27),
        width: s * .37,
        height: s * .39,
      ),
      math.pi,
      math.pi,
      false,
      goldStroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .31, s * .27, s * .065, s * .11),
        Radius.circular(s * .024),
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * .625, s * .27, s * .065, s * .11),
        Radius.circular(s * .024),
      ),
      gold,
    );

    final face = Paint()
      ..color = const Color(0xFF4A271F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .010
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .43, s * .27), Offset(s * .47, s * .27), face);
    canvas.drawLine(Offset(s * .53, s * .27), Offset(s * .57, s * .27), face);
    canvas.drawArc(
      Rect.fromLTWH(s * .455, s * .29, s * .09, s * .065),
      0,
      math.pi,
      false,
      face,
    );

    if (pose == SangeetaPose.sit) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c, s * .79),
          width: s * .44,
          height: s * .12,
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
      oldDelegate.beat != beat;
}
