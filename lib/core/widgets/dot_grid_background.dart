import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The faint dot-grid backdrop myschool.ng uses behind its chat list —
/// small, evenly spaced dots over the page background. Painted once behind
/// the whole app (see [EduvoraPrepApp]'s `MaterialApp.builder`) rather than
/// per screen, so every Scaffold shows the same texture through whatever
/// empty space it leaves, while cards and solid surfaces sit on top of it
/// unaffected.
class DotGridBackground extends StatelessWidget {
  const DotGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColours.background,
      child: CustomPaint(
        painter: _DotGridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _spacing = 18;
  static const double _radius = 1.1;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColours.borderStrong.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
