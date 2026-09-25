import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sangeeta_likeness.dart';
import '../models/wardrobe_profile.dart';

class AvatarAccessoryOverlay extends StatelessWidget {
  const AvatarAccessoryOverlay({
    required this.category,
    required this.hairstyle,
    required this.earrings,
    required this.shoes,
    required this.accessory,
    required this.size,
    super.key,
  });

  final WardrobeCategory category;
  final Hairstyle hairstyle;
  final EarringStyle earrings;
  final ShoeStyle shoes;
  final AccessoryStyle accessory;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _WardrobePainter(
          category: category,
          hairstyle: hairstyle,
          earrings: earrings,
          shoes: shoes,
          accessory: accessory,
        ),
      ),
    );
  }
}

class _WardrobePainter extends CustomPainter {
  const _WardrobePainter({
    required this.category,
    required this.hairstyle,
    required this.earrings,
    required this.shoes,
    required this.accessory,
  });

  final WardrobeCategory category;
  final Hairstyle hairstyle;
  final EarringStyle earrings;
  final ShoeStyle shoes;
  final AccessoryStyle accessory;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    _paintEarrings(canvas, s);
    _paintShoes(canvas, s);
    _paintAccessory(canvas, s);
    _paintCategoryAccent(canvas, s);
  }

  void _paintEarrings(Canvas canvas, double s) {
    if (earrings == EarringStyle.none) return;

    final paint = Paint()
      ..color = SangeetaLikeness.gold
      ..style = earrings == EarringStyle.hoops
          ? PaintingStyle.stroke
          : PaintingStyle.fill
      ..strokeWidth = s * .007;

    final radius = switch (earrings) {
      EarringStyle.none => 0.0,
      EarringStyle.studs => s * .010,
      EarringStyle.hoops => s * .020,
      EarringStyle.jhumka => s * .015,
    };

    for (final x in <double>[.382, .618]) {
      canvas.drawCircle(Offset(s * x, s * .342), radius, paint);
      if (earrings == EarringStyle.jhumka) {
        canvas.drawLine(
          Offset(s * x, s * .350),
          Offset(s * x, s * .378),
          Paint()
            ..color = SangeetaLikeness.gold
            ..strokeWidth = s * .006,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(s * x, s * .387),
            width: s * .032,
            height: s * .022,
          ),
          Paint()..color = SangeetaLikeness.gold,
        );
      }
    }
  }

  void _paintShoes(Canvas canvas, double s) {
    final shoeColor = switch (shoes) {
      ShoeStyle.sneakers => const Color(0xFFF2F1EE),
      ShoeStyle.heels => const Color(0xFF6D263B),
      ShoeStyle.sandals => SangeetaLikeness.gold,
      ShoeStyle.boots => const Color(0xFF171515),
    };

    switch (shoes) {
      case ShoeStyle.sneakers:
        for (final x in <double>[.425, .575]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(s * x, s * .967),
                width: s * .125,
                height: s * .050,
              ),
              Radius.circular(s * .022),
            ),
            Paint()..color = shoeColor,
          );
          canvas.drawLine(
            Offset(s * (x - .035), s * .960),
            Offset(s * (x + .025), s * .960),
            Paint()
              ..color = const Color(0xFFB9B9B9)
              ..strokeWidth = s * .004,
          );
        }
        break;
      case ShoeStyle.heels:
        for (final x in <double>[.425, .575]) {
          canvas.drawPath(
            Path()
              ..moveTo(s * (x - .055), s * .967)
              ..quadraticBezierTo(
                s * x,
                s * .945,
                s * (x + .060),
                s * .966,
              )
              ..lineTo(s * (x + .045), s * .982)
              ..lineTo(s * (x - .045), s * .982)
              ..close(),
            Paint()..color = shoeColor,
          );
          canvas.drawLine(
            Offset(s * (x + .035), s * .978),
            Offset(s * (x + .045), s * .997),
            Paint()
              ..color = shoeColor
              ..strokeWidth = s * .006,
          );
        }
        break;
      case ShoeStyle.sandals:
        for (final x in <double>[.425, .575]) {
          canvas.drawLine(
            Offset(s * (x - .050), s * .972),
            Offset(s * (x + .050), s * .972),
            Paint()
              ..color = shoeColor
              ..strokeWidth = s * .010
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawLine(
            Offset(s * x, s * .950),
            Offset(s * (x + .030), s * .970),
            Paint()
              ..color = shoeColor
              ..strokeWidth = s * .005,
          );
        }
        break;
      case ShoeStyle.boots:
        for (final x in <double>[.425, .575]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(s * x, s * .938),
                width: s * .105,
                height: s * .115,
              ),
              Radius.circular(s * .020),
            ),
            Paint()..color = shoeColor,
          );
        }
        break;
    }
  }

  void _paintAccessory(Canvas canvas, double s) {
    switch (accessory) {
      case AccessoryStyle.none:
        break;
      case AccessoryStyle.necklace:
        canvas.drawArc(
          Rect.fromLTWH(s * .42, s * .365, s * .16, s * .14),
          0,
          math.pi,
          false,
          Paint()
            ..color = SangeetaLikeness.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .006,
        );
        canvas.drawCircle(
          Offset(s * .50, s * .475),
          s * .011,
          Paint()..color = SangeetaLikeness.gold,
        );
        break;
      case AccessoryStyle.scarf:
        canvas.drawPath(
          Path()
            ..moveTo(s * .37, s * .43)
            ..cubicTo(
              s * .45,
              s * .47,
              s * .58,
              s * .48,
              s * .66,
              s * .43,
            )
            ..cubicTo(
              s * .62,
              s * .57,
              s * .54,
              s * .63,
              s * .43,
              s * .66,
            ),
          Paint()
            ..color = const Color(0xCCDFD2BC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .025
            ..strokeCap = StrokeCap.round,
        );
        break;
      case AccessoryStyle.bangles:
        for (final point in <Offset>[
          Offset(s * .245, s * .575),
          Offset(s * .755, s * .575),
        ]) {
          for (var i = 0; i < 3; i++) {
            canvas.drawCircle(
              point.translate(0, s * i * .010),
              s * .022,
              Paint()
                ..color = SangeetaLikeness.gold
                ..style = PaintingStyle.stroke
                ..strokeWidth = s * .005,
            );
          }
        }
        break;
      case AccessoryStyle.stageHeadset:
        canvas.drawArc(
          Rect.fromLTWH(s * .325, s * .115, s * .35, s * .30),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF242424)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * .015,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * .318, s * .268, s * .055, s * .095),
            Radius.circular(s * .018),
          ),
          Paint()..color = SangeetaLikeness.gold,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(s * .627, s * .268, s * .055, s * .095),
            Radius.circular(s * .018),
          ),
          Paint()..color = SangeetaLikeness.gold,
        );
        canvas.drawLine(
          Offset(s * .650, s * .338),
          Offset(s * .700, s * .382),
          Paint()
            ..color = const Color(0xFF252525)
            ..strokeWidth = s * .007
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset(s * .703, s * .384),
          s * .009,
          Paint()..color = SangeetaLikeness.gold,
        );
        break;
    }
  }

  void _paintCategoryAccent(Canvas canvas, double s) {
    if (category != WardrobeCategory.party &&
        category != WardrobeCategory.djStage &&
        category != WardrobeCategory.festival) {
      return;
    }

    final paint = Paint()..color = SangeetaLikeness.gold.withValues(alpha: .55);
    for (final point in <Offset>[
      Offset(s * .20, s * .25),
      Offset(s * .80, s * .22),
      Offset(s * .76, s * .52),
    ]) {
      canvas.drawCircle(point, s * .006, paint);
      canvas.drawLine(
        point.translate(-s * .014, 0),
        point.translate(s * .014, 0),
        Paint()
          ..color = paint.color
          ..strokeWidth = s * .003,
      );
      canvas.drawLine(
        point.translate(0, -s * .014),
        point.translate(0, s * .014),
        Paint()
          ..color = paint.color
          ..strokeWidth = s * .003,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WardrobePainter oldDelegate) =>
      oldDelegate.category != category ||
      oldDelegate.hairstyle != hairstyle ||
      oldDelegate.earrings != earrings ||
      oldDelegate.shoes != shoes ||
      oldDelegate.accessory != accessory;
}
