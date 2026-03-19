import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';

const double _kCartoonPlayIconDefaultSize = 24.0;

/// Rounded play triangle with theme gradient fill and bold outline.
class CartoonPlayIcon extends StatelessWidget {
  const CartoonPlayIcon({super.key, this.size = _kCartoonPlayIconDefaultSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CartoonPlayIconPainter(iconSize: size)),
    );
  }
}

class _CartoonPlayIconPainter extends CustomPainter {
  _CartoonPlayIconPainter({required this.iconSize});

  final double iconSize;

  static Offset _dir(Offset from, Offset to) {
    final Offset d = to - from;
    final double len = d.distance;
    if (len < 1e-9) {
      return Offset.zero;
    }
    return d / len;
  }

  /// Three corners, clockwise: left-top, left-bottom, right tip.
  static Path _roundedPlayTrianglePath(
    List<Offset> v,
    List<double> cornerRadius,
  ) {
    final Offset v0 = v[0];
    final Offset v1 = v[1];
    final Offset v2 = v[2];
    final double r0 = cornerRadius[0];
    final double r1 = cornerRadius[1];
    final double r2 = cornerRadius[2];
    final Path path = Path();
    path.moveTo(v0.dx + _dir(v0, v1).dx * r0, v0.dy + _dir(v0, v1).dy * r0);
    path.lineTo(v1.dx - _dir(v0, v1).dx * r1, v1.dy - _dir(v0, v1).dy * r1);
    path.quadraticBezierTo(
      v1.dx,
      v1.dy,
      v1.dx + _dir(v1, v2).dx * r1,
      v1.dy + _dir(v1, v2).dy * r1,
    );
    path.lineTo(v2.dx - _dir(v1, v2).dx * r2, v2.dy - _dir(v1, v2).dy * r2);
    path.quadraticBezierTo(
      v2.dx,
      v2.dy,
      v2.dx + _dir(v2, v0).dx * r2,
      v2.dy + _dir(v2, v0).dy * r2,
    );
    path.lineTo(v0.dx - _dir(v2, v0).dx * r0, v0.dy - _dir(v2, v0).dy * r0);
    path.quadraticBezierTo(
      v0.dx,
      v0.dy,
      v0.dx + _dir(v0, v1).dx * r0,
      v0.dy + _dir(v0, v1).dy * r0,
    );
    path.close();
    return path;
  }

  static List<double> _cornerRadii(List<Offset> v, double globalR) {
    final int n = v.length;
    final List<double> out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final Offset prev = v[(i - 1 + n) % n];
      final Offset curr = v[i];
      final Offset next = v[(i + 1) % n];
      final double lenIn = (curr - prev).distance;
      final double lenOut = (next - curr).distance;
      final double maxR = math.min(lenIn, lenOut) * 0.33;
      out[i] = math.min(globalR, maxR);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final List<Offset> v = <Offset>[
      Offset(w * 0.24, h * 0.16),
      Offset(w * 0.24, h * 0.84),
      Offset(w * 0.90, h * 0.50),
    ];
    final double globalR = math.min(w, h) * 0.14;
    final List<double> radii = _cornerRadii(v, globalR);
    final Path path = _roundedPlayTrianglePath(v, radii);
    final Rect bounds = Offset.zero & size;
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          GameThemeConstants.primaryLight,
          GameThemeConstants.primaryDark,
        ],
      ).createShader(bounds);
    final Paint strokePaint = Paint()
      ..color = GameThemeConstants.outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameThemeConstants.outlineThickness
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CartoonPlayIconPainter oldDelegate) {
    return oldDelegate.iconSize != iconSize;
  }
}
