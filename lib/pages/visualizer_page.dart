import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:math/theme/app_theme.dart';
import 'package:math/services/user_provider.dart';

class VisualizerPage extends StatefulWidget {
  const VisualizerPage({super.key});

  @override
  State<VisualizerPage> createState() => _VisualizerPageState();
}

class _VisualizerPageState extends State<VisualizerPage> {
  double _a = 1.0;
  double _b = 0.0;
  double _c = 0.0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildGraphArea(config),
                        const SizedBox(height: 24),
                        _buildFormulaDisplay(config),
                        const SizedBox(height: 24),
                        Expanded(child: _buildControls(config)),
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
            'Interactive Visualizer',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphArea(ThemeConfig config) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: config.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: config.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: FunctionPainter(
            a: _a,
            b: _b,
            c: _c,
            lineColor: config.vibrantColors[1],
            axisColor: config.textColor.withOpacity(0.3),
            gridColor: config.textColor.withOpacity(0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaDisplay(ThemeConfig config) {
    String aStr = _a.toStringAsFixed(1);
    String bStr = _b >= 0
        ? "+ ${_b.toStringAsFixed(1)}"
        : "- ${(-_b).toStringAsFixed(1)}";
    String cStr = _c >= 0
        ? "+ ${_c.toStringAsFixed(1)}"
        : "- ${(-_c).toStringAsFixed(1)}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: config.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'y = ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: config.textColor,
            ),
          ),
          Text(
            '${aStr}x²',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: config.vibrantColors[1],
            ),
          ),
          Text(
            ' $bStr',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: config.vibrantColors[2],
            ),
          ),
          Text(
            'x ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: config.textColor,
            ),
          ),
          Text(
            ' $cStr',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: config.vibrantColors[3],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeConfig config) {
    return ListView(
      children: [
        _buildSliderRow('Parameter a', _a, -5.0, 5.0, config.vibrantColors[1], (
          val,
        ) {
          setState(() => _a = val);
        }),
        const SizedBox(height: 16),
        _buildSliderRow(
          'Parameter b',
          _b,
          -10.0,
          10.0,
          config.vibrantColors[2],
          (val) {
            setState(() => _b = val);
          },
        ),
        const SizedBox(height: 16),
        _buildSliderRow(
          'Parameter c',
          _c,
          -20.0,
          20.0,
          config.vibrantColors[3],
          (val) {
            setState(() => _c = val);
          },
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class FunctionPainter extends CustomPainter {
  final double a;
  final double b;
  final double c;
  final Color lineColor;
  final Color axisColor;
  final Color gridColor;

  FunctionPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.lineColor,
    required this.axisColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double scale = 20.0; // Scale factor: pixels per unit

    // Draw Grid
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += scale) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += scale) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw Axes
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );

    // Draw Function Path
    final pathPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    bool first = true;

    for (double px = 0; px <= size.width; px += 1) {
      double x = (px - center.dx) / scale;
      double y = a * x * x + b * x + c;
      double py = center.dy - (y * scale);

      if (py >= -100 && py <= size.height + 100) {
        if (first) {
          path.moveTo(px, py);
          first = false;
        } else {
          path.lineTo(px, py);
        }
      }
    }

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant FunctionPainter oldDelegate) {
    return oldDelegate.a != a || oldDelegate.b != b || oldDelegate.c != c;
  }
}
