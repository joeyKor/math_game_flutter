import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/services/user_provider.dart';

class UnitCirclePage extends StatefulWidget {
  const UnitCirclePage({super.key});

  @override
  State<UnitCirclePage> createState() => _UnitCirclePageState();
}

class _UnitCirclePageState extends State<UnitCirclePage> {
  double _angleValue = 0.0; // In degrees

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

    final radians = _angleValue * math.pi / 180;
    final sinVal = math.sin(radians);
    final cosVal = math.cos(radians);
    final tanVal = (cosVal.abs() < 0.001) ? double.nan : math.tan(radians);

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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildCircleArea(config, radians),
                        const SizedBox(height: 24),
                        _buildValuesDisplay(config, sinVal, cosVal, tanVal),
                        const SizedBox(height: 24),
                        _buildAngleSlider(config),
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
            'Unit Circle Visualizer',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleArea(ThemeConfig config, double angleInRadians) {
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
          painter: UnitCirclePainter(
            angle: angleInRadians,
            primaryColor: config.primary,
            accentColor: config.secondary,
            textColor: config.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildValuesDisplay(
    ThemeConfig config,
    double sin,
    double cos,
    double tan,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildValueRow('Sine (sin θ)', sin, config.vibrantColors[1]),
          const SizedBox(height: 12),
          _buildValueRow('Cosine (cos θ)', cos, config.vibrantColors[2]),
          const SizedBox(height: 12),
          _buildValueRow('Tangent (tan θ)', tan, config.vibrantColors[3]),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, double value, Color color) {
    String valStr = value.isNaN ? 'Undefined' : value.toStringAsFixed(3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Text(
          valStr,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildAngleSlider(ThemeConfig config) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Angle θ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_angleValue.toStringAsFixed(0)}°',
              style: TextStyle(
                color: config.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: config.primary,
            inactiveTrackColor: config.primary.withOpacity(0.2),
            thumbColor: config.primary,
            overlayColor: config.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: _angleValue,
            min: 0,
            max: 360,
            onChanged: (val) {
              setState(() {
                _angleValue = val;
              });
            },
          ),
        ),
      ],
    );
  }
}

class UnitCirclePainter extends CustomPainter {
  final double angle;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  UnitCirclePainter({
    required this.angle,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw grid and axes
    paint.color = textColor.withOpacity(0.2);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );

    // Draw unit circle
    paint.color = textColor.withOpacity(0.1);
    canvas.drawCircle(center, radius, paint);

    // Current point on circle
    final x = math.cos(angle) * radius;
    final y = -math.sin(angle) * radius; // Negative because Y axis is down
    final point = center + Offset(x, y);

    // Cosine line (X projection)
    paint.color = Colors.lightBlueAccent;
    paint.strokeWidth = 3;
    canvas.drawLine(center, Offset(center.dx + x, center.dy), paint);

    // Sine line (Y projection)
    paint.color = Colors.pinkAccent;
    canvas.drawLine(Offset(center.dx + x, center.dy), point, paint);

    // Hypotenuse (Radius)
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    canvas.drawLine(center, point, paint);

    // Angle Arc
    final rect = Rect.fromCircle(center: center, radius: radius * 0.2);
    paint.color = primaryColor.withOpacity(0.3);
    paint.style = PaintingStyle.fill;
    canvas.drawArc(rect, 0, -angle, true, paint);

    // Point on circle
    paint.color = primaryColor;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(point, 6, paint);
  }

  @override
  bool shouldRepaint(covariant UnitCirclePainter oldDelegate) =>
      oldDelegate.angle != angle;
}
