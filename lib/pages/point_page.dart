import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/pages/point_history_page.dart';
import 'package:math/pages/qr_collection_page.dart';
import 'package:math/pages/point_shop_page.dart';
import 'package:math/models/achievement.dart';

import 'package:math/widgets/math_dialog.dart';
import 'package:confetti/confetti.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PointPage extends StatefulWidget {
  const PointPage({super.key});

  @override
  State<PointPage> createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Consumer<UserProvider>(
                    builder: (context, user, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            _buildPointCard(context, user.totalScore),
                            const SizedBox(height: 30),
                            _buildAchievementsSection(
                              context,
                              user.achievements,
                            ),
                            const SizedBox(height: 30),
                            _buildHistoryButton(context),
                            const SizedBox(height: 20),
                            _buildQRButton(context),
                            const SizedBox(height: 20),
                            _buildPointShopButton(context),
                            const SizedBox(height: 20),
                            _buildChangePointButton(context),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
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
    final color = Theme.of(context).primaryColor;
    final cardBg = Theme.of(context).cardTheme.color ?? Colors.black;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_rounded, color: color, size: 60),
          const SizedBox(height: 20),
          Text(
            'TOTAL POINTS',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: points),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Text(
                '$value',
                style: TextStyle(
                  color: Theme.of(context).textTheme.displayLarge?.color,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'P',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    List<Achievement> achievements,
  ) {
    final unlocked = achievements.where((a) => a.isUnlocked).toList();
    final color = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${unlocked.length}/${achievements.length}',
                style: TextStyle(color: color.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => MathDialog(
                      title: 'ACHIEVEMENT',
                      isSuccess: a.isUnlocked,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.icon, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          if (!a.isUnlocked) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Goal: ${a.description}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onConfirm: () {},
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: a.isUnlocked
                        ? color.withOpacity(0.1)
                        : Theme.of(context).cardTheme.color?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: a.isUnlocked
                          ? color.withOpacity(0.3)
                          : Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color!.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        a.icon,
                        style: TextStyle(
                          fontSize: 30,
                          color:
                              (Theme.of(context).textTheme.titleLarge?.color ??
                                      Colors.white)
                                  .withOpacity(a.isUnlocked ? 1.0 : 0.3),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        a.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.titleLarge?.color ??
                                      Colors.white)
                                  .withOpacity(a.isUnlocked ? 1.0 : 0.3),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const PointHistoryPage()),
      ),
      icon: const Icon(Icons.history_rounded),
      label: const Text('View Point History'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildQRButton(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const QRCollectionPage()),
        );
        if (result == true) {
          _confettiController.play();
        }
      },
      icon: const Icon(Icons.qr_code_scanner_rounded),
      label: const Text('Add via QR Code'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildPointShopButton(BuildContext context) {
    const color = Colors.orange;
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const PointShopPage()),
      ),
      icon: const Icon(Icons.shopping_bag_rounded),
      label: const Text('Point Shop'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildChangePointButton(BuildContext context) {
    final color = Theme.of(context).textTheme.titleLarge?.color ?? Colors.white;
    return ElevatedButton.icon(
      onPressed: () => _showPasswordDialog(context),
      icon: const Icon(Icons.edit_note_rounded),
      label: const Text('Change Point (Admin)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.05),
        foregroundColor: color.withOpacity(0.7),
        minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.1)),
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Password Required',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: TextField(
              controller: controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter Password',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                ),
                fillColor: Colors.black.withOpacity(0.2),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text == '9891') {
                  Navigator.pop(context);
                  _showPointChangeDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect Password'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(
                'Verify',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPointChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return PointChangeForm(onSuccess: () => _confettiController.play());
      },
    );
  }
}

class PointChangeForm extends StatefulWidget {
  final VoidCallback onSuccess;
  const PointChangeForm({super.key, required this.onSuccess});

  @override
  State<PointChangeForm> createState() => _PointChangeFormState();
}

class _PointChangeFormState extends State<PointChangeForm> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isAccumulate = true;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Change Points',
        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  hintText: 'e.g. Admin Adjustment',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  fillColor: Colors.black.withOpacity(0.2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('+'),
                    selected: _isAccumulate,
                    onSelected: (val) => setState(() => _isAccumulate = val),
                    selectedColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _isAccumulate ? color : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('-'),
                    selected: !_isAccumulate,
                    onSelected: (val) => setState(() => _isAccumulate = !val),
                    selectedColor: Colors.redAccent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: !_isAccumulate ? Colors.redAccent : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  fillColor: Colors.black.withOpacity(0.2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final content = _contentController.text.trim();
            final amountStr = _amountController.text.trim();
            if (content.isEmpty || amountStr.isEmpty) return;
            final prefix = _isAccumulate ? 'p' : 'm';
            final qrData = '$prefix${amountStr}_$content';

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'QR Code for this Reward',
                  style: TextStyle(color: Colors.black),
                ),
                content: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: Text('GENERATE QR', style: TextStyle(color: secondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final content = _contentController.text.trim();
            final amountStr = _amountController.text.trim();
            if (content.isEmpty || amountStr.isEmpty) return;
            final amountValue = int.tryParse(amountStr) ?? 0;
            final finalAmount = _isAccumulate ? amountValue : -amountValue;

            Provider.of<UserProvider>(
              context,
              listen: false,
            ).addScore(finalAmount, gameName: content);
            Navigator.pop(context);
            widget.onSuccess();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('SUBMIT'),
        ),
      ],
    );
  }
}
