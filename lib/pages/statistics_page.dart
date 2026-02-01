import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/models/point_transaction.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final history = context.watch<UserProvider>().history;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('📊 Progress Analytics'),
        centerTitle: true,
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryGrid(history),
                const SizedBox(height: 24),
                _buildActivityChart(context, history, config.vibrantColors[0]),
                const SizedBox(height: 24),
                _buildGameBreakdown(context, history, config.vibrantColors[1]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(List<PointTransaction> history) {
    final last7Days = DateTime.now().subtract(const Duration(days: 7));
    final recentHistory = history
        .where((t) => t.date.isAfter(last7Days))
        .toList();

    int totalGames = recentHistory
        .where(
          (t) =>
              !t.gameName.contains('Unlocked') &&
              !t.gameName.contains('Purchased') &&
              !t.gameName.contains('Streak'),
        )
        .length;
    int pointsEarned = recentHistory
        .where((t) => t.points > 0)
        .fold(0, (sum, t) => sum + t.points);

    return Row(
      children: [
        _buildStatCard(
          'Last 7 Days',
          '$totalGames',
          'Games Played',
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Points Gain',
          '+$pointsEarned',
          'Last 7 Days',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(
    BuildContext context,
    List<PointTransaction> history,
    Color color,
  ) {
    final now = DateTime.now();
    final Map<String, int> dailyPoints = {};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MM/dd').format(date);
      dailyPoints[dateStr] = 0;
    }

    for (var t in history) {
      if (t.points > 0) {
        final dateStr = DateFormat('MM/dd').format(t.date);
        if (dailyPoints.containsKey(dateStr)) {
          dailyPoints[dateStr] = (dailyPoints[dateStr] ?? 0) + t.points;
        }
      }
    }

    final data = dailyPoints.entries.toList().reversed.toList();
    final maxVal = data
        .map((e) => e.value)
        .fold(10, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points Earned (Last 7 Days)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((e) {
                final ratio = e.value / maxVal;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 100 * ratio,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBreakdown(
    BuildContext context,
    List<PointTransaction> history,
    Color color,
  ) {
    final Map<String, int> gameCounts = {};
    for (var t in history) {
      if (!t.gameName.contains('Unlocked') &&
          !t.gameName.contains('Purchased') &&
          !t.gameName.contains('Streak')) {
        gameCounts[t.gameName] = (gameCounts[t.gameName] ?? 0) + 1;
      }
    }

    final sortedGames = gameCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGames = sortedGames.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Games (Lifetime)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...topGames.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(e.key, style: const TextStyle(fontSize: 14)),
                  ),
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: e.value / (topGames.first.value),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
