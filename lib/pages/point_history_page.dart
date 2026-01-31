import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:intl/intl.dart';

class PointHistoryPage extends StatelessWidget {
  const PointHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Theme Background
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
                _buildAppBar(context),
                Expanded(
                  child: Consumer<UserProvider>(
                    builder: (context, user, child) {
                      if (user.history.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_rounded,
                                color: Colors.white.withOpacity(0.1),
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No history yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: user.history.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final transaction = user.history[index];
                          return _buildHistoryItem(context, transaction);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Point History',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, transaction) {
    final bool isPositive = transaction.points > 0;
    final dateStr = DateFormat('yy/MM/dd HH:mm').format(transaction.date);
    final cardBg = Theme.of(context).cardTheme.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isPositive ? Colors.greenAccent : Colors.redAccent)
              .withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.greenAccent : Colors.redAccent)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.gameName,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isPositive ? '+${transaction.points}' : '${transaction.points}',
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'P',
            style: TextStyle(
              color: (isPositive ? Colors.greenAccent : Colors.redAccent)
                  .withOpacity(0.5),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
