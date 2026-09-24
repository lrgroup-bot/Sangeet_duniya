import 'dart:math' as math;

import 'package:flutter/material.dart';

class SangeetaLogo extends StatelessWidget {
  const SangeetaLogo({
    this.size = 260,
    this.showTagline = true,
    super.key,
  });

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SangeetaLogoPainter(showTagline: showTagline),
      ),
    );
  }
}

class _SangeetaLogoPainter extends CustomPainter {
  const _SangeetaLogoPainter({required this.showTagline});

  final bool showTagline;

  static const gold = Color(0xFFFFC857);
  static const goldLight = Color(0xFFFFEAA2);
  static const goldDark = Color(0xFF9B5E00);
  static const pink = Color(0xFFE83D62);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s * 0.10;

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF020202), Color(0xFF211406), Color(0xFF050505)],
      ).createShader(Offset.zero & size);

    final shadow = Paint()
      ..color = const Color(0xAA000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    );

    canvas.drawRRect(rect.shift(const Offset(0, 7)), shadow);
    canvas.drawRRect(rect, bg);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..shader = const LinearGradient(
        colors: [goldLight, gold, goldDark, goldLight],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      rect.deflate(s * 0.025),
      border,
    );

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.004
      ..color = gold.withValues(alpha: 0.35);
    canvas.drawRRect(
      rect.deflate(s * 0.055),
      inner,
    );

    final cx = s * 0.50;
    final headY = s * 0.37;

    // Golden music wave background.
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.008
      ..color = gold.withValues(alpha: 0.65);
    final path = Path()
      ..moveTo(s * 0.08, s * 0.43)
      ..cubicTo(
        s * 0.28, s * 0.28,
        s * 0.42, s * 0.49,
        s * 0.60, s * 0.41,
      )
      ..cubicTo(
        s * 0.76, s * 0.34,
        s * 0.87, s * 0.25,
        s * 0.93, s * 0.18,
      );
    canvas.drawPath(path, wave);

    // Shoulders / dancing body.
    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4A3518), Color(0xFF090807)],
      ).createShader(
        Rect.fromLTWH(s * 0.20, s * 0.58, s * 0.60, s * 0.27),
      );
    final bodyPath = Path()
      ..moveTo(s * 0.25, s * 0.84)
      ..cubicTo(
        s * 0.27,
        s * 0.67,
        s * 0.38,
        s * 0.59,
        s * 0.50,
        s * 0.59,
      )
      ..cubicTo(
        s * 0.63,
        s * 0.59,
        s * 0.74,
        s * 0.67,
        s * 0.77,
        s * 0.84,
      )
      ..close();
    canvas.drawPath(bodyPath, body);

    // Dancing raised arm.
    final skin = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.4),
        radius: 1.2,
        colors: [Color(0xFFFFD9C3), Color(0xFFD68E74), Color(0xFFA75C49)],
      ).createShader(Offset.zero & size);
    final arm = Path()
      ..moveTo(s * 0.64, s * 0.65)
      ..cubicTo(s * 0.72, s * 0.56, s * 0.78, s * 0.45, s * 0.79, s * 0.33)
      ..cubicTo(s * 0.79, s * 0.27, s * 0.82, s * 0.24, s * 0.85, s * 0.27)
      ..cubicTo(s * 0.89, s * 0.33, s * 0.84, s * 0.51, s * 0.76, s * 0.72)
      ..close();
    canvas.drawPath(arm, skin);

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.44, s * 0.48, s * 0.12, s * 0.16),
        Radius.circular(s * 0.03),
      ),
      skin,
    );

    // Face.
    final face = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.20, -0.35),
        radius: 1.0,
        colors: [Color(0xFFFFDCC8), Color(0xFFE4A488), Color(0xFFB96C56)],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, headY), radius: s * 0.18),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, headY),
        width: s * 0.31,
        height: s * 0.37,
      ),
      face,
    );

    // Hair silhouette.
    final hair = Paint()..color = const Color(0xFF1B100D);
    final hairPath = Path()
      ..moveTo(s * 0.34, s * 0.38)
      ..cubicTo(
        s * 0.27,
        s * 0.22,
        s * 0.36,
        s * 0.10,
        s * 0.51,
        s * 0.10,
      )
      ..cubicTo(
        s * 0.68,
        s * 0.10,
        s * 0.73,
        s * 0.24,
        s * 0.67,
        s * 0.41,
      )
      ..cubicTo(
        s * 0.61,
        s * 0.29,
        s * 0.51,
        s * 0.22,
        s * 0.40,
        s * 0.25,
      )
      ..close();
    canvas.drawPath(hairPath, hair);

    // Headphones.
    final phones = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF080808);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, headY),
        width: s * 0.34,
        height: s * 0.34,
      ),
      math.pi,
      math.pi,
      false,
      phones,
    );
    final phoneGold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.007
      ..color = gold;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, headY),
        width: s * 0.36,
        height: s * 0.36,
      ),
      math.pi,
      math.pi,
      false,
      phoneGold,
    );

    final cup = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [goldLight, gold, goldDark],
      ).createShader(
        Rect.fromLTWH(s * 0.28, s * 0.32, s * 0.09, s * 0.12),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.285, s * 0.32, s * 0.075, s * 0.12),
        Radius.circular(s * 0.025),
      ),
      cup,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.64, s * 0.32, s * 0.075, s * 0.12),
        Radius.circular(s * 0.025),
      ),
      cup,
    );

    // Face details.
    final detail = Paint()
      ..color = const Color(0xFF422018)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.012
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(s * 0.42, s * 0.38),
      Offset(s * 0.46, s * 0.38),
      detail,
    );
    canvas.drawLine(
      Offset(s * 0.54, s * 0.38),
      Offset(s * 0.58, s * 0.38),
      detail,
    );
    canvas.drawCircle(Offset(s * 0.44, s * 0.40), s * 0.007, detail);
    canvas.drawCircle(Offset(s * 0.56, s * 0.40), s * 0.007, detail);
    canvas.drawArc(
      Rect.fromLTWH(s * 0.46, s * 0.43, s * 0.08, s * 0.05),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFA73535)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.009,
    );
    canvas.drawCircle(Offset(s * 0.50, s * 0.33), s * 0.008, Paint()..color = Colors.red);

    // Gold jewelry.
    canvas.drawCircle(
      Offset(s * 0.50, s * 0.56),
      s * 0.024,
      Paint()..shader = const LinearGradient(colors: [goldLight, goldDark]).createShader(
        Rect.fromCircle(center: Offset(s * 0.50, s * 0.56), radius: s * 0.03),
      ),
    );

    // 3D logo lettering.
    _draw3dText(
      canvas,
      text: "LR's",
      center: Offset(s * 0.50, s * 0.78),
      fontSize: s * 0.12,
      mainColor: gold,
      shadowColor: goldDark,
    );
    _draw3dText(
      canvas,
      text: 'Sangeet Dunia',
      center: Offset(s * 0.50, showTagline ? s * 0.88 : s * 0.86),
      fontSize: s * 0.065,
      mainColor: const Color(0xFFFFF2CF),
      shadowColor: goldDark,
    );

    // Pink heart accent.
    final heart = Path()
      ..moveTo(s * 0.50, s * 0.95)
      ..cubicTo(
        s * 0.43, s * 0.90,
        s * 0.42, s * 0.94,
        s * 0.50, s * 0.99,
      )
      ..cubicTo(
        s * 0.58, s * 0.94,
        s * 0.57, s * 0.90,
        s * 0.50, s * 0.95,
      )
      ..close();
    canvas.drawPath(
      heart,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF718A), pink, Color(0xFF8D1737)],
        ).createShader(Offset.zero & size),
    );
  }

  void _draw3dText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    required Color mainColor,
    required Color shadowColor,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: -fontSize * 0.02,
      color: mainColor,
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = center - Offset(tp.width / 2, tp.height / 2);
    final shadowTp = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: shadowColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    for (var i = 7; i >= 1; i--) {
      shadowTp.paint(
        canvas,
        offset + Offset(i.toDouble(), i.toDouble()),
      );
    }

    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SangeetaLogoPainter oldDelegate) {
    return oldDelegate.showTagline != showTagline;
  }
}
