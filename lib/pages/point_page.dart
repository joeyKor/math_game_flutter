import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/pages/point_history_page.dart';

class PointPage extends StatelessWidget {
  const PointPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background (matching HomePage)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.background, Color(0xFF1E1E2C)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: Consumer<UserProvider>(
                      builder: (context, user, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPointCard(context, user.totalScore),
                            const SizedBox(height: 40),
                            _buildHistoryButton(context),
                            const SizedBox(height: 40),
                            Text(
                              'Keep up the great work!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        );
                      },
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
            'Points Explorer',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(BuildContext context, int points) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.accent,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            'TOTAL POINTS',
            style: TextStyle(
              color: AppColors.accent.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'P',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const PointHistoryPage()),
      ),
      icon: const Icon(Icons.history_rounded),
      label: const Text('포인트 적립내역 보기'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent.withOpacity(0.2),
        foregroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.accent.withOpacity(0.3)),
        ),
      ),
    );
  }
}
