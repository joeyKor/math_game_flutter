import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/services/user_provider.dart';

class StatisticsVisualizerPage extends StatefulWidget {
  const StatisticsVisualizerPage({super.key});

  @override
  State<StatisticsVisualizerPage> createState() =>
      _StatisticsVisualizerPageState();
}

class _StatisticsVisualizerPageState extends State<StatisticsVisualizerPage> {
  final List<int> _rolls = [];
  final Map<int, int> _frequencies = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
  final math.Random _random = math.Random();

  void _rollDice(int count) {
    setState(() {
      for (int i = 0; i < count; i++) {
        int roll = _random.nextInt(6) + 1;
        _rolls.add(roll);
        _frequencies[roll] = (_frequencies[roll] ?? 0) + 1;
      }
    });
  }

  void _reset() {
    setState(() {
      _rolls.clear();
      _frequencies.updateAll((key, value) => 0);
    });
  }

  double get _average {
    if (_rolls.isEmpty) return 0.0;
    return _rolls.reduce((a, b) => a + b) / _rolls.length;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildStatsSummary(config),
                        const SizedBox(height: 24),
                        _buildChart(config),
                        const SizedBox(height: 24),
                        _buildControls(config),
                        const SizedBox(height: 40),
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
            'Statistics Simulator',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(ThemeConfig config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: config.cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Rolls', '${_rolls.length}'),
          _buildStatItem('Average', _average.toStringAsFixed(2)),
          _buildStatItem('Expected', '3.50'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(ThemeConfig config) {
    final maxFreq = _frequencies.values.reduce(math.max);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: config.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Face Frequency Distribution',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [1, 2, 3, 4, 5, 6].map((face) {
                final freq = _frequencies[face] ?? 0;
                final ratio = _rolls.isEmpty ? 0.0 : freq / maxFreq;
                return _buildBar(face, freq, ratio, config);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(int face, int freq, double ratio, ThemeConfig config) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$freq',
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 180 * ratio,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                config.vibrantColors[face % config.vibrantColors.length],
                config.vibrantColors[face % config.vibrantColors.length]
                    .withOpacity(0.3),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: config.vibrantColors[face % config.vibrantColors.length]
                    .withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('$face', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildControls(ThemeConfig config) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Roll 1',
                icon: Icons.casino_outlined,
                color: config.primary,
                onPressed: () => _rollDice(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Roll 10',
                icon: Icons.filter_9_plus_outlined,
                color: config.secondary,
                onPressed: () => _rollDice(10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Roll 100',
                icon: Icons.auto_awesome_motion_rounded,
                color: config.accent,
                onPressed: () => _rollDice(100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'Clear Stats',
                icon: Icons.refresh_rounded,
                color: Colors.white24,
                onPressed: _reset,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color == Colors.white24 ? Colors.white : color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
