import 'package:flutter/material.dart';

enum DayMarkerShape { circle, ring, square, diamond, triangle }

/// Tiny calendar marker. Shapes back up the colors so markers stay
/// distinguishable without color vision.
class DayMarker extends StatelessWidget {
  final Color color;
  final DayMarkerShape shape;
  final double size;

  const DayMarker({super.key, required this.color, this.shape = DayMarkerShape.circle, this.size = 7});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: switch (shape) {
        DayMarkerShape.circle => DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        DayMarkerShape.ring => DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
            ),
          ),
        DayMarkerShape.square => DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1.5)),
          ),
        DayMarkerShape.diamond => Transform.rotate(
            angle: 0.785398,
            child: Padding(
              padding: EdgeInsets.all(size * 0.15),
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        DayMarkerShape.triangle => CustomPaint(painter: _TrianglePainter(color)),
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => oldDelegate.color != color;
}
