import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/widgets/avatar_display.dart';

class PointShopPage extends StatefulWidget {
  const PointShopPage({super.key});

  @override
  State<PointShopPage> createState() => _PointShopPageState();
}

class _PointShopPageState extends State<PointShopPage> {
  int _selectedCategory = 0; // 0: Items, 1: Themes, 2: Avatars

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
                    _buildCategoryTabs(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCategoryContent(context, user, config),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
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

  Future<void> _showMultiplierConfirmation(
    BuildContext context,
    UserProvider user,
    int multiplier,
    String name,
    int cost,
    Color color,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.bolt_rounded, color: color),
            const SizedBox(width: 12),
            const Text('Buy Boost?'),
          ],
        ),
        content: Text(
          'Activate "$name" for $cost points? This boost lasts until the end of today!',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ACTIVATE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (user.totalScore >= cost) {
        final success = await user.purchaseMultiplier(multiplier, cost);
        if (success && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$name activated!')));
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

  Widget _buildMultiplierItem(
    BuildContext context,
    UserProvider user, {
    required int multiplier,
    required String name,
    required String description,
    required Color color,
    required int cost,
  }) {
    final isActive = user.pointMultiplier == multiplier;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? color
              : (Theme.of(context).textTheme.titleLarge?.color ?? Colors.white)
                    .withOpacity(0.1),
          width: isActive ? 2 : 1,
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
            child: Icon(Icons.bolt_rounded, color: color, size: 30),
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
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color),
              ),
              child: Text(
                'Active',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _showMultiplierConfirmation(
                context,
                user,
                multiplier,
                name,
                cost,
                color,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('$cost P'),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarGrid(BuildContext context, UserProvider user) {
    const avatars = [
      {'emoji': '👤', 'cost': 0},
      // Premium Emoji Avatars
      {'emoji': 'assets/avatars/emoji_cat.png', 'cost': 500},
      {'emoji': 'assets/avatars/hero_spider.png', 'cost': 500},
      {'emoji': 'assets/avatars/hero_super.png', 'cost': 500},
      {'emoji': 'assets/avatars/hero_panther.png', 'cost': 500},
      {'emoji': 'assets/avatars/emoji_robot.png', 'cost': 500},
      {'emoji': 'assets/avatars/emoji_owl.png', 'cost': 500},

      // Animals
      {'emoji': '🦁', 'cost': 100},
      {'emoji': '🐯', 'cost': 100},
      {'emoji': '🐱', 'cost': 100},
      {'emoji': '🐶', 'cost': 100},
      {'emoji': '🐼', 'cost': 100},
      {'emoji': '🦒', 'cost': 150},
      {'emoji': '🦏', 'cost': 150},
      {'emoji': '🦓', 'cost': 150},
      {'emoji': '🦍', 'cost': 150},
      {'emoji': '🐘', 'cost': 150},
      {'emoji': '🦊', 'cost': 200},
      {'emoji': '🦉', 'cost': 200},
      {'emoji': '🐨', 'cost': 200},
      {'emoji': '🐧', 'cost': 200},
      {'emoji': '🐸', 'cost': 200},
      {'emoji': '🐙', 'cost': 250},
      {'emoji': '🐢', 'cost': 250},
      {'emoji': '🦄', 'cost': 300},
      {'emoji': '🐉', 'cost': 300},
      {'emoji': '🦖', 'cost': 300},
      {'emoji': '🐳', 'cost': 300},

      // Science & Math
      {'emoji': '👩‍🔬', 'cost': 350},
      {'emoji': '👨‍🔬', 'cost': 350},
      {'emoji': '👩‍🚀', 'cost': 400},
      {'emoji': '👨‍🚀', 'cost': 400},
      {'emoji': '👩‍💻', 'cost': 400},
      {'emoji': '👨‍💻', 'cost': 400},
      {'emoji': '🧠', 'cost': 450},
      {'emoji': '🧪', 'cost': 500},
      {'emoji': '🧬', 'cost': 500},
      {'emoji': '🔭', 'cost': 500},
      {'emoji': '⚛️', 'cost': 550},

      // School & Achievement
      {'emoji': '🏫', 'cost': 600},
      {'emoji': '🎓', 'cost': 600},
      {'emoji': '👩‍🏫', 'cost': 650},
      {'emoji': '👨‍🏫', 'cost': 650},
      {'emoji': '📚', 'cost': 700},
      {'emoji': '🏆', 'cost': 750},
      {'emoji': '🥇', 'cost': 800},
      {'emoji': '📜', 'cost': 800},

      // Objects & Fun
      {'emoji': '🚀', 'cost': 850},
      {'emoji': '🛸', 'cost': 900},
      {'emoji': '🎮', 'cost': 900},
      {'emoji': '🎨', 'cost': 900},
      {'emoji': '🎩', 'cost': 950},
      {'emoji': '🕶️', 'cost': 950},
      {'emoji': '🤖', 'cost': 1000},
      {'emoji': '👾', 'cost': 1000},
      {'emoji': '🎯', 'cost': 1000},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        return _buildAvatarItem(
          context,
          user,
          avatar['emoji'] as String,
          avatar['cost'] as int,
        );
      },
    );
  }

  Widget _buildAvatarItem(
    BuildContext context,
    UserProvider user,
    String emoji,
    int cost,
  ) {
    final isUnlocked = user.unlockedAvatars.contains(emoji);
    final isCurrent = user.currentAvatar == emoji;
    final color = Theme.of(context).primaryColor;
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

    return InkWell(
      onTap: () => _showAvatarPreview(
        context,
        user,
        emoji,
        cost,
        config.vibrantColors[0],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? color.withOpacity(0.2)
              : Theme.of(context).cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? color : Colors.white.withOpacity(0.1),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AvatarDisplay(avatar: emoji, size: 32),
            if (!isUnlocked)
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$cost',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            if (isCurrent)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.check_circle, size: 16, color: Colors.green),
              ),
          ],
        ),
      ),
    );
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

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTabItem(0, Icons.bolt, 'Items'),
          _buildTabItem(1, Icons.palette, 'Themes'),
          _buildTabItem(2, Icons.face, 'Avatars'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isSelected = _selectedCategory == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent(
    BuildContext context,
    UserProvider user,
    ThemeConfig config,
  ) {
    switch (_selectedCategory) {
      case 0:
        return ListView(
          key: const ValueKey('Items'),
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(context, 'Daily Boosts'),
            const SizedBox(height: 12),
            _buildMultiplierItem(
              context,
              user,
              multiplier: 2,
              name: 'Double Points',
              description: 'Gain 2x points for all games today!',
              color: config.vibrantColors[0],
              cost: 1000,
            ),
            _buildMultiplierItem(
              context,
              user,
              multiplier: 3,
              name: 'Triple Points',
              description: 'Gain 3x points for all games today!',
              color: config.vibrantColors[1],
              cost: 3000,
            ),
            _buildMultiplierItem(
              context,
              user,
              multiplier: 5,
              name: '5x Points Burst',
              description: 'Gain massive 5x points for all games today!',
              color: config.vibrantColors[0],
              cost: 7000,
            ),
          ],
        );
      case 1:
        return ListView(
          key: const ValueKey('Themes'),
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(context, 'Unlock New Themes'),
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
              id: 'Paper',
              name: 'Antique Scroll',
              description: 'A clean, light theme with high readability.',
              color: const Color(0xFFB58900),
              cost: 100,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Midnight',
              name: 'Midnight Mist',
              description: 'Deep slates and ghostly whites.',
              color: const Color(0xFF94A3B8),
              cost: 100,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Ocean',
              name: 'Abyssal Deep',
              description: 'Cold, heavy blues of the bottomless ocean.',
              color: const Color(0xFF38BDF8),
              cost: 200,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Frost',
              name: 'Frost Bite',
              description: 'Crisp arctic cyans and snowy whites.',
              color: const Color(0xFF67E8F9),
              cost: 200,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Space',
              name: 'Galactic Void',
              description: 'Deep purple cosmic energy with neon cyan accents.',
              color: const Color(0xFFA855F7),
              cost: 300,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Forest',
              name: 'Forest Bliss',
              description: 'Soothing emerald and forest greens.',
              color: const Color(0xFF22C55E),
              cost: 300,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Sunset',
              name: 'Burning Sunset',
              description: 'Intense oranges and fiery reds.',
              color: const Color(0xFFF97316),
              cost: 400,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Lava',
              name: 'Magma Flow',
              description: 'Intense volcanic reds and oranges.',
              color: const Color(0xFFEF4444),
              cost: 400,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Matrix',
              name: 'Hacker Terminal',
              description: 'Pure black background with glowing digital green.',
              color: const Color(0xFF00FF41),
              cost: 500,
            ),
            _buildThemeItem(
              context,
              user,
              id: 'Royal',
              name: 'Golden Monarchy',
              description: 'Elegant blacks and gleaming gold highlights.',
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
          ],
        );
      case 2:
        return ListView(
          key: const ValueKey('Avatars'),
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(context, 'Collection: Avatars'),
            const SizedBox(height: 16),
            _buildAvatarGrid(context, user),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _showAvatarPreview(
    BuildContext context,
    UserProvider user,
    String emoji,
    int cost,
    Color themeColor,
  ) async {
    final isUnlocked = user.unlockedAvatars.contains(emoji);
    final isCurrent = user.currentAvatar == emoji;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            AvatarDisplay(avatar: emoji, size: 120),
            const SizedBox(height: 24),
            Text(
              isUnlocked ? 'Character Unlocked' : 'Locked Character',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            if (!isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: themeColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$cost Points',
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isCurrent
                      ? null
                      : () async {
                          if (isUnlocked) {
                            user.setAvatar(emoji);
                            Navigator.pop(context);
                          } else {
                            if (user.totalScore >= cost) {
                              await user.unlockAvatar(emoji, cost);
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough points!'),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isCurrent
                        ? 'EQUIPPED'
                        : (isUnlocked ? 'USE AVATAR' : 'UNLOCK'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
