import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;

class DiamondExchangePage extends StatefulWidget {
  const DiamondExchangePage({super.key});

  @override
  State<DiamondExchangePage> createState() => _DiamondExchangePageState();
}

class _DiamondExchangePageState extends State<DiamondExchangePage>
    with SingleTickerProviderStateMixin {
  int _hundredUnits = 1;
  late AnimationController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final themeId = user.currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final price = user.diamondMarketPrice;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('💎 Diamond Exchange'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMarketHeader(price),
                  const SizedBox(height: 24),
                  _buildPriceChart(config.vibrantColors[0]),
                  const SizedBox(height: 32),
                  _buildExchangeCard(user, price, config),
                  const SizedBox(height: 40),
                  _buildTradingRules(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketHeader(int price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Price',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '$price P / 100 💎',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (price >= 100 ? Colors.greenAccent : Colors.redAccent)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  price >= 100 ? Icons.trending_up : Icons.trending_down,
                  color: price >= 100 ? Colors.greenAccent : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  price >= 100 ? 'Bullish' : 'Bearish',
                  style: TextStyle(
                    color: price >= 100 ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChart(Color color) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: AnimatedBuilder(
        animation: _chartController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ChartPainter(color, _chartController.value),
          );
        },
      ),
    );
  }

  Widget _buildExchangeCard(UserProvider user, int price, ThemeConfig config) {
    int maxUnits = user.diamonds ~/ 100;
    int pointsToReceive = _hundredUnits * price;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: config.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: config.primary.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Sell your Diamonds',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildValueBox(
                'Diamonds',
                '${_hundredUnits * 100} 💎',
                Colors.cyanAccent,
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white54),
              _buildValueBox('Points', '$pointsToReceive P', config.primary),
            ],
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: config.primary,
              inactiveTrackColor: config.primary.withOpacity(0.1),
              thumbColor: config.primary,
              overlayColor: config.primary.withOpacity(0.2),
              valueIndicatorColor: config.primary,
            ),
            child: Slider(
              value: _hundredUnits.toDouble(),
              min: 1,
              max: math.max(1, maxUnits).toDouble(),
              divisions: math.max(1, maxUnits),
              label: '${_hundredUnits * 100} Diamonds',
              onChanged: maxUnits > 0
                  ? (val) => setState(() => _hundredUnits = val.round())
                  : null,
            ),
          ),
          Text(
            'Your Balance: ${user.diamonds} 💎',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: maxUnits > 0
                  ? () => _handleExchange(user, pointsToReceive)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: config.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'EXCHANGE NOW',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTradingRules() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: Colors.amberAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'Exchange Rules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Daily Fluctuations: Market price resets at midnight.',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          Text(
            '• Minimum Unit: 100 Diamonds per trade.',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
          Text(
            '• Range: Fixed between 90P and 110P per unit.',
            style: TextStyle(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  void _handleExchange(UserProvider user, int points) async {
    final success = await user.exchangeDiamondsToPoints(_hundredUnits);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exchanged for $points points!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _hundredUnits = 1);
    }
  }
}

class _ChartPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  _ChartPainter(this.color, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      double y =
          size.height * 0.5 +
          (math.sin(
                (i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi),
              ) *
              20);
      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);

    // Fill area under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
