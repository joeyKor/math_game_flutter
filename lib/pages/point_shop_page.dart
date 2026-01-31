import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

class PointShopPage extends StatelessWidget {
  const PointShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('🏆 Point Shop'),
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
          Consumer<UserProvider>(
            builder: (context, user, child) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildBalanceHeader(context, user.totalScore),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            'Unlock New Themes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Default',
                            name: 'Classic Slate',
                            description: 'The standard professional look.',
                            color: const Color(0xFF6366F1),
                            cost: 0,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Space',
                            name: 'Galactic Void',
                            description:
                                'Deep purple cosmic energy with neon cyan accents.',
                            color: const Color(0xFFA855F7),
                            cost: 1000,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Matrix',
                            name: 'Hacker Terminal',
                            description:
                                'Pure black background with glowing digital green.',
                            color: const Color(0xFF00FF41),
                            cost: 1000,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Sunset',
                            name: 'Burning Sunset',
                            description: 'Intense oranges and fiery reds.',
                            color: const Color(0xFFF97316),
                            cost: 1000,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Ocean',
                            name: 'Abyssal Deep',
                            description:
                                'Cold, heavy blues of the bottomless ocean.',
                            color: const Color(0xFF38BDF8),
                            cost: 1000,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Paper',
                            name: 'Antique Scroll',
                            description:
                                'A clean, light theme with high readability.',
                            color: const Color(0xFFB58900),
                            cost: 1000,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Royal',
                            name: 'Golden Monarchy',
                            description:
                                'Elegant blacks and gleaming gold highlights.',
                            color: const Color(0xFFFFD700),
                            cost: 500,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Cyberpunk',
                            name: 'Cyberpunk Night',
                            description: 'Neon pink, cyan, and yellow energy.',
                            color: const Color(0xFFFF00E0),
                            cost: 500,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Forest',
                            name: 'Forest Bliss',
                            description: 'Soothing emerald and forest greens.',
                            color: const Color(0xFF22C55E),
                            cost: 500,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Frost',
                            name: 'Frost Bite',
                            description: 'Crisp arctic cyans and snowy whites.',
                            color: const Color(0xFF67E8F9),
                            cost: 500,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Lava',
                            name: 'Magma Flow',
                            description: 'Intense volcanic reds and oranges.',
                            color: const Color(0xFFEF4444),
                            cost: 500,
                          ),
                          _buildThemeItem(
                            context,
                            user,
                            id: 'Midnight',
                            name: 'Midnight Mist',
                            description: 'Deep slates and ghostly whites.',
                            color: const Color(0xFF94A3B8),
                            cost: 500,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, int score) {
    final color = Theme.of(context).primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color:
                (Theme.of(context).textTheme.titleLarge?.color ?? Colors.white)
                    .withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your Balance',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score P',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurchaseConfirmation(
    BuildContext context,
    UserProvider user,
    String id,
    String name,
    int cost,
    Color themeColor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.shopping_cart_rounded, color: themeColor),
            const SizedBox(width: 12),
            const Text('Unlock Theme?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to unlock "$name" for $cost points?',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Balance:',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${user.totalScore} P',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('UNLOCK'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (user.totalScore >= cost) {
        final success = await user.unlockTheme(id, cost);
        if (success && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name unlocked!')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Not enough points!')));
        }
      }
    }
  }

  Widget _buildThemeItem(
    BuildContext context,
    UserProvider user, {
    required String id,
    required String name,
    required String description,
    required Color color,
    required int cost,
  }) {
    final isUnlocked = user.unlockedThemes.contains(id);
    final isCurrent = user.currentTheme == id;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? color
              : (Theme.of(context).textTheme.titleLarge?.color ?? Colors.white)
                    .withOpacity(0.1),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.palette_rounded, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Text(
              'Applied',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            )
          else if (isUnlocked)
            ElevatedButton(
              onPressed: () => user.setTheme(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
              ),
              child: const Text('Apply'),
            )
          else
            ElevatedButton(
              onPressed: () => _showPurchaseConfirmation(
                context,
                user,
                id,
                name,
                cost,
                color,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text('$cost P'),
            ),
        ],
      ),
    );
  }
}
