import 'dart:math' as math;
import 'package:flutter/material.dart';

class AquaFlowLogo extends StatelessWidget {
  final double size;
  final bool showBackground;
  final Color waveColor;
  final Color backgroundColor;

  const AquaFlowLogo({
    Key? key,
    this.size = 100,
    this.showBackground = true,
    this.waveColor = const Color(0xFF00B4D8),
    this.backgroundColor = const Color(0xFF101928),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget iconContent = CustomPaint(
      size: Size(size * 0.65, size * 0.65),
      painter: _AquaFlowWavePainter(waveColor: waveColor),
    );

    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: iconContent),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: waveColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: waveColor.withOpacity(0.15),
            blurRadius: size * 0.15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(child: iconContent),
    );
  }
}

class _AquaFlowWavePainter extends CustomPainter {
  final Color waveColor;

  _AquaFlowWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final paint = Paint()
      ..strokeWidth = height * 0.14
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double spacing = height / 4;
    final double amplitude = height * 0.08;

    for (int i = 1; i <= 3; i++) {
      final double y = i * spacing;
      final path = Path();
      
      bool first = true;
      for (double x = 0; x <= width; x += 1.0) {
        final double progress = x / width;
        final double waveY = y + math.sin(progress * 4 * math.pi) * amplitude;
        if (first) {
          path.moveTo(x, waveY);
          first = false;
        } else {
          path.lineTo(x, waveY);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AquaFlowWavePainter oldDelegate) {
    return oldDelegate.waveColor != waveColor;
  }
}
