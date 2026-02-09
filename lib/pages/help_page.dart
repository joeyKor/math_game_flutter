import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Game Guide'),
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
                _buildHelpCard(
                  context,
                  title: 'Square',
                  icon: Icons.exposure_rounded,
                  color: config.vibrantColors[0],
                  description: 'Calculate the square of a given number.',
                  entry: '-1',
                  correct: '3 / 8 (by Level)',
                  incorrect: '2 / 4 (by Level)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Math Archery',
                  icon: Icons.gps_fixed_rounded,
                  color: config.vibrantColors[2],
                  description:
                      'Build math formulas using 4 numbers to hit the target values.',
                  entry: '-1',
                  correct: '1 ~ 50',
                  incorrect: '-1',
                  bonus:
                      '+50 (Clear), +100 (Flawless), Combo: 5(+10), 10(+30), 15(+70)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Prime Detector',
                  icon: Icons.search_rounded,
                  color: config.vibrantColors[3],
                  description:
                      'Find all 4 prime numbers among the 16 numbers on the board.',
                  entry: '-1',
                  correct: '3 / 8 (by Level)',
                  incorrect: '2 / 4 (by Level)',
                  bonus: '+30 (All Found)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Flash Mental',
                  icon: Icons.flash_on_rounded,
                  color: config.vibrantColors[4],
                  description:
                      'Numbers flash briefly on the screen. Sum them up and enter the result.',
                  entry: '-1',
                  correct: '3 / 6 / 9 (by Level)',
                  incorrect: '1 / 2 / 3 (by Level)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Sum Comparison',
                  icon: Icons.compare_arrows_rounded,
                  color: config.vibrantColors[5],
                  description:
                      'Two sets of additions are shown briefly. Mentally calculate and pick the larger sum.',
                  entry: '-1',
                  correct: '3 / 6 / 9 (by Level)',
                  incorrect: '2 / 4 / 6 (by Level)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Missing Sign',
                  icon: Icons.unfold_more_rounded,
                  color: config.vibrantColors[1],
                  description:
                      'Fill in the correct mathematical operators to complete the equation.',
                  entry: '-1',
                  correct: '3 / 6 / 9 (by Level)',
                  incorrect: '1 / 2 / 3 (by Level)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Fraction Battle',
                  icon: Icons.pie_chart_rounded,
                  color: config.vibrantColors[1],
                  description:
                      'Compare fractions or solve addition problems. Answers must be irreducible.',
                  entry: '-1',
                  correct: '3 / 5 / 10 (by Level)',
                  incorrect: '1 / 2 / 4 (by Level)',
                ),
                _buildHelpCard(
                  context,
                  title: 'Weekday Equation',
                  icon: Icons.calendar_month_rounded,
                  color: config.vibrantColors[2],
                  description:
                      'Given the 1st day of a month, calculate the dates for specific weekdays (within a 10-day range).',
                  entry: '-1',
                  correct: '3 / 10 / 30 (by Level)',
                  incorrect: '2 / 5 / 8 (by Level)',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required String entry,
    required String correct,
    required String incorrect,
    String? bonus,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointInfo(context, 'Entry', entry, Colors.orangeAccent),
              _buildPointInfo(context, 'Correct', correct, Colors.greenAccent),
              _buildPointInfo(
                context,
                'Incorrect',
                incorrect,
                Colors.redAccent,
              ),
            ],
          ),
          if (bonus != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bonus: $bonus',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointInfo(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
