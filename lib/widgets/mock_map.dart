import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

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
    final appState = context.watch<AppState>();
    
    return Stack(
      children: [
        // Map background and streets
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: const Color(0xFF08101C), // Deep night blue map background
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: MapPainter(
                    showRoute: widget.showRoute,
                    progress: appState.simulationProgress,
                    pulseValue: _pulseController.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MapPainter extends CustomPainter {
  final bool showRoute;
  final double progress;
  final double pulseValue;

  MapPainter({
    required this.showRoute,
    required this.progress,
    required this.pulseValue,
  });

  // Polyline representing the simulated route
  final List<Offset> _routePoints = const [
    Offset(60, 420),   // Start: Driver Location / Warehouse
    Offset(60, 240),   // Turn 1
    Offset(180, 240),  // Turn 2
    Offset(180, 100),  // Turn 3
    Offset(320, 100),  // End: Customer Address
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 400.0;
    final scaleY = size.height / 500.0;

    // Apply scale to points to fit canvas size
    List<Offset> scaledPoints = _routePoints
        .map((p) => Offset(p.dx * scaleX, p.dy * scaleY))
        .toList();

    // 1. Paint mock backgrounds/blocks (dark structures)
    final blockPaint = Paint()
      ..color = const Color(0xFF0D1929) // Lighter navy blocks
      ..style = PaintingStyle.fill;
    
    // Draw some simulated buildings/green areas
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20 * scaleX, 20 * scaleY, 120 * scaleX, 80 * scaleY), const Radius.circular(8)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(220 * scaleX, 20 * scaleY, 150 * scaleX, 60 * scaleY), const Radius.circular(8)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20 * scaleX, 120 * scaleY, 120 * scaleX, 100 * scaleY), const Radius.circular(8)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(220 * scaleX, 120 * scaleY, 100 * scaleX, 140 * scaleY), const Radius.circular(8)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20 * scaleX, 260 * scaleY, 140 * scaleX, 140 * scaleY), const Radius.circular(8)), blockPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(200 * scaleX, 280 * scaleY, 170 * scaleX, 140 * scaleY), const Radius.circular(8)), blockPaint);

    // Cyan/Blue highlight zones instead of green (Futuristic night map)
    final glowZonePaint = Paint()
      ..color = const Color(0xFF0D253F)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(200 * scaleX, 20 * scaleY, 15 * scaleX, 60 * scaleY), const Radius.circular(4)), glowZonePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20 * scaleX, 420 * scaleY, 80 * scaleX, 60 * scaleY), const Radius.circular(4)), glowZonePaint);

    // 2. Paint grid/streets (glowy streets)
    final streetPaint = Paint()
      ..color = const Color(0xFF142436) // Dark greyish blue street paths
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 20.0 * math.min(scaleX, scaleY);
    
    // Custom paths for streets
    final Path streetPath = Path();
    // Street 1
    streetPath.moveTo(60 * scaleX, 0);
    streetPath.lineTo(60 * scaleX, 500 * scaleY);
    // Street 2
    streetPath.moveTo(180 * scaleX, 0);
    streetPath.lineTo(180 * scaleX, 500 * scaleY);
    // Street 3
    streetPath.moveTo(320 * scaleX, 0);
    streetPath.lineTo(320 * scaleX, 500 * scaleY);
    // Cross street 1
    streetPath.moveTo(0, 100 * scaleY);
    streetPath.lineTo(400 * scaleX, 100 * scaleY);
    // Cross street 2
    streetPath.moveTo(0, 240 * scaleY);
    streetPath.lineTo(400 * scaleX, 240 * scaleY);
    // Cross street 3
    streetPath.moveTo(0, 420 * scaleY);
    streetPath.lineTo(400 * scaleX, 420 * scaleY);

    canvas.drawPath(streetPath, streetPaint);

    // Dotted street lines
    final dashedStreetPaint = Paint()
      ..color = const Color(0xFF1B324D) // Blue dotted line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    // Draw dashed lines down the center of roads
    for (double y = 10; y < 500; y += 30) {
      canvas.drawLine(Offset(60 * scaleX, y * scaleY), Offset(60 * scaleX, (y + 15) * scaleY), dashedStreetPaint);
      canvas.drawLine(Offset(180 * scaleX, y * scaleY), Offset(180 * scaleX, (y + 15) * scaleY), dashedStreetPaint);
      canvas.drawLine(Offset(320 * scaleX, y * scaleY), Offset(320 * scaleX, (y + 15) * scaleY), dashedStreetPaint);
    }
    for (double x = 10; x < 400; x += 30) {
      canvas.drawLine(Offset(x * scaleX, 100 * scaleY), Offset((x + 15) * scaleX, 100 * scaleY), dashedStreetPaint);
      canvas.drawLine(Offset(x * scaleX, 240 * scaleY), Offset((x + 15) * scaleX, 240 * scaleY), dashedStreetPaint);
      canvas.drawLine(Offset(x * scaleX, 420 * scaleY), Offset((x + 15) * scaleX, 420 * scaleY), dashedStreetPaint);
    }

    if (showRoute) {
      // 3. Paint route line
      final routePaint = Paint()
        ..color = AppTheme.primaryBlue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.0 * math.min(scaleX, scaleY);

      final Path routePath = Path();
      routePath.moveTo(scaledPoints[0].dx, scaledPoints[0].dy);
      for (int i = 1; i < scaledPoints.length; i++) {
        routePath.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
      }
      canvas.drawPath(routePath, routePaint);

      // Inner thinner bright line
      final innerRoutePaint = Paint()
        ..color = AppTheme.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0 * math.min(scaleX, scaleY);
      canvas.drawPath(routePath, innerRoutePaint);

      // 4. Draw destination pulse indicator
      final Offset destination = scaledPoints.last;
      final pulsePaint = Paint()
        ..color = AppTheme.primaryBlue.withOpacity(1.0 - pulseValue)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(destination, 25.0 * pulseValue * scaleX, pulsePaint);

      // 5. Draw start & destination pins
      // Start pin (Driver's origin)
      final startPinPaint = Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scaledPoints.first, 8.0 * scaleX, startPinPaint);
      canvas.drawCircle(scaledPoints.first, 4.0 * scaleX, Paint()..color = Colors.white);

      // Destination pin (Client location)
      final destPinPaint = Paint()
        ..color = const Color(0xFFEF4444) // Vibrant red for target
        ..style = PaintingStyle.fill;
      
      // Draw pin needle shape
      final Path pinPath = Path();
      pinPath.moveTo(destination.dx, destination.dy);
      pinPath.lineTo(destination.dx - 8 * scaleX, destination.dy - 16 * scaleY);
      pinPath.quadraticBezierTo(destination.dx, destination.dy - 24 * scaleY, destination.dx + 8 * scaleX, destination.dy - 16 * scaleY);
      pinPath.close();
      canvas.drawPath(pinPath, destPinPaint);
      canvas.drawCircle(Offset(destination.dx, destination.dy - 16 * scaleY), 8 * scaleX, destPinPaint);
      canvas.drawCircle(Offset(destination.dx, destination.dy - 16 * scaleY), 3 * scaleX, Paint()..color = Colors.white);

      // 6. Draw moving vehicle along the path based on progress
      final Offset vehiclePos = _getPositionOnPath(scaledPoints, progress);
      
      final vehicleShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(vehiclePos + const Offset(0, 3), 10 * scaleX, vehicleShadowPaint);

      final vehiclePaint = Paint()
        ..color = AppTheme.primaryBlue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(vehiclePos, 9 * scaleX, vehiclePaint);
      canvas.drawCircle(vehiclePos, 4 * scaleX, Paint()..color = Colors.white);

      // Draw active status glow on the vehicle
      final glowPaint = Paint()
        ..color = const Color(0xFF00FF66).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(vehiclePos, (9 + 4 * math.sin(pulseValue * 2 * math.pi)) * scaleX, glowPaint);
    }
  }

  // Calculate coordinates along the polyline segments
  Offset _getPositionOnPath(List<Offset> points, double progress) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points[0];
    if (progress <= 0.0) return points[0];
    if (progress >= 1.0) return points.last;

    // Calculate total length of path
    List<double> segmentLengths = [];
    double totalLength = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      double len = (points[i+1] - points[i]).distance;
      segmentLengths.add(len);
      totalLength += len;
    }

    double targetDistance = progress * totalLength;
    double currentDistance = 0.0;

    for (int i = 0; i < segmentLengths.length; i++) {
      double nextDistance = currentDistance + segmentLengths[i];
      if (targetDistance <= nextDistance) {
        // Target lies on this segment
        double segmentProgress = (targetDistance - currentDistance) / segmentLengths[i];
        return Offset.lerp(points[i], points[i+1], segmentProgress)!;
      }
      currentDistance = nextDistance;
    }

    return points.last;
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.pulseValue != pulseValue || 
           oldDelegate.showRoute != showRoute;
  }
}
