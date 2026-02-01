import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/services/user_provider.dart';

class GeometryPage extends StatefulWidget {
  const GeometryPage({super.key});

  @override
  State<GeometryPage> createState() => _GeometryPageState();
}

class _GeometryPageState extends State<GeometryPage> {
  Offset p1 = const Offset(100, 300);
  Offset p2 = const Offset(300, 300);
  Offset p3 = const Offset(200, 100);

  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

    // Calculate area: 0.5 * |x1(y2-y3) + x2(y3-y1) + x3(y1-y2)|
    final areaRaw =
        (p1.dx * (p2.dy - p3.dy) +
                p2.dx * (p3.dy - p1.dy) +
                p3.dx * (p1.dy - p2.dy))
            .abs() /
        2;
    final area = areaRaw / 100; // Simplified scale

    final base = (p2.dx - p1.dx).abs();
    final height = (p3.dy - p1.dy).abs();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [config.gradientStart, config.gradientEnd],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, config),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildInteractiveArea(config),
                        const SizedBox(height: 24),
                        _buildInfoDisplay(
                          config,
                          base / 10,
                          height / 10,
                          area / 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeConfig config) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Geometry Shaper',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveArea(ThemeConfig config) {
    return Expanded(
      child: GestureDetector(
        onPanStart: (details) {
          final pos = details.localPosition;
          if ((pos - p1).distance < 30)
            _draggingIndex = 1;
          else if ((pos - p2).distance < 20)
            _draggingIndex = 2;
          else if ((pos - p3).distance < 20)
            _draggingIndex = 3;
        },
        onPanUpdate: (details) {
          if (_draggingIndex == null) return;
          setState(() {
            if (_draggingIndex == 1) p1 += details.delta;
            if (_draggingIndex == 2) p2 += details.delta;
            if (_draggingIndex == 3) p3 += details.delta;
          });
        },
        onPanEnd: (_) => _draggingIndex = null,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: config.cardBg.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: config.primary.withOpacity(0.3)),
          ),
          child: CustomPaint(
            painter: GeometryPainter(
              p1: p1,
              p2: p2,
              p3: p3,
              color: config.primary,
              accentColor: config.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoDisplay(ThemeConfig config, double b, double h, double a) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Area Formula: ½ × base × height',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Base', b.toStringAsFixed(1)),
              _buildMetric('Height', h.toStringAsFixed(1)),
              _buildMetric('Area', a.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Drag the vertices to see how the area changes!',
            style: TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class GeometryPainter extends CustomPainter {
  final Offset p1, p2, p3;
  final Color color;
  final Color accentColor;

  GeometryPainter({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(path, paint);

    paint.style = PaintingStyle.fill;
    paint.color = color.withOpacity(0.2);
    canvas.drawPath(path, paint);

    // Draggable point indicators
    paint.color = Colors.white;
    canvas.drawCircle(p1, 8, paint);
    canvas.drawCircle(p2, 8, paint);
    canvas.drawCircle(p3, 8, paint);

    paint.style = PaintingStyle.stroke;
    paint.color = color;
    paint.strokeWidth = 2;
    canvas.drawCircle(p1, 12, paint);
    canvas.drawCircle(p2, 12, paint);
    canvas.drawCircle(p3, 12, paint);
  }

  @override
  bool shouldRepaint(covariant GeometryPainter oldDelegate) => true;
}
