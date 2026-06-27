import 'dart:math' as math;
import 'package:flutter/material.dart';

class MockMapWidget extends StatefulWidget {
  final bool showRoute;
  const MockMapWidget({Key? key, this.showRoute = true}) : super(key: key);

  @override
  State<MockMapWidget> createState() => _MockMapWidgetState();
}

class _MockMapWidgetState extends State<MockMapWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08101C), // Deep night blue map background
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: MapPainter(
              pulseValue: _pulseController.value,
            ),
          );
        },
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final double pulseValue;

  MapPainter({
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 30); // Center of grid slightly offset down

    // 1. Paint concentric radial grid circles (Teal glowing lines)
    final gridPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Concentric circles representing streets
    final List<double> radii = [40, 85, 130, 180, 230, 290, 360];
    for (int i = 0; i < radii.length; i++) {
      canvas.drawCircle(center, radii[i], i % 2 == 0 ? roadPaint : gridPaint);
    }

    // 2. Paint radial lines representing roads projecting outward from center
    final int lineCount = 16;
    for (int i = 0; i < lineCount; i++) {
      final angle = (i * 2 * math.pi) / lineCount;
      final start = Offset(
        center.dx + 20 * math.cos(angle),
        center.dy + 20 * math.sin(angle),
      );
      final end = Offset(
        center.dx + 400 * math.cos(angle),
        center.dy + 400 * math.sin(angle),
      );
      canvas.drawLine(start, end, i % 3 == 0 ? roadPaint : gridPaint);
    }

    // Draw some organic crossroad connects
    final connectPaint = Paint()
      ..color = const Color(0xFF00B4D8).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw secondary grid lines to look organic
    for (double r in [110, 205, 260]) {
      final Path arcPath = Path();
      arcPath.addArc(
        Rect.fromCircle(center: center, radius: r),
        math.pi / 6,
        math.pi / 2,
      );
      arcPath.addArc(
        Rect.fromCircle(center: center, radius: r),
        math.pi,
        math.pi / 3,
      );
      canvas.drawPath(arcPath, connectPaint);
    }

    // 3. Draw pulsing user location pin (blue glowing dot) in the center of the radial grid
    final glowPaint = Paint()
      ..color = const Color(0xFF3498DB).withOpacity(1.0 - pulseValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 22.0 * pulseValue, glowPaint);

    final innerGlowPaint = Paint()
      ..color = const Color(0xFF3498DB).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10.0, innerGlowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
