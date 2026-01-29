import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'pages/square_page.dart';
import 'pages/factorial_page.dart';
import 'pages/archery_page.dart';
import 'pages/prime_page.dart';
import 'pages/flash_page.dart';
import 'pages/compare_page.dart';
import 'pages/settings_page.dart';
import 'pages/point_page.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MathApp(),
    ),
  );
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MathApp extends StatelessWidget {
  const MathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '수학 어플',
      theme: premiumTheme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
      navigatorObservers: [routeObserver],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Consumer<UserProvider>(
                    builder: (context, user, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Math Master',
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => const PointPage(),
                                  ),
                                ),
                                child: AnimatedScoreBadge(
                                  totalScore: user.totalScore,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const SettingsPage(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white70,
                            ),
                            iconSize: 32,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.9,
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'Square',
                          icon: Icons.exposure_rounded,
                          color: AppColors.primary,
                          onTap: () {
                            context.read<UserProvider>().addScore(-1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const SquarePage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Factorial',
                          icon: Icons.priority_high_rounded,
                          color: AppColors.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const FactorialPage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Math Archery',
                          icon: Icons.gps_fixed_rounded,
                          color: AppColors.accent,
                          onTap: () {
                            context.read<UserProvider>().addScore(-1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const ArcheryPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Prime Detector',
                          icon: Icons.search_rounded,
                          color: Colors.orangeAccent,
                          onTap: () {
                            context.read<UserProvider>().addScore(-1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const PrimePage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Flash Mental',
                          icon: Icons.flash_on_rounded,
                          color: Colors.amber,
                          onTap: () {
                            context.read<UserProvider>().addScore(-1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const FlashPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Sum Comparison',
                          icon: Icons.compare_arrows_rounded,
                          color: Colors.tealAccent,
                          onTap: () {
                            context.read<UserProvider>().addScore(-1);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const ComparePage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedScoreBadge extends StatefulWidget {
  final int totalScore;

  const AnimatedScoreBadge({super.key, required this.totalScore});

  @override
  State<AnimatedScoreBadge> createState() => _AnimatedScoreBadgeState();
}

class _AnimatedScoreBadgeState extends State<AnimatedScoreBadge>
    with TickerProviderStateMixin, RouteAware {
  late AnimationController _bumpController;
  late Animation<double> _scaleAnimation;
  int _prevScore = 0;
  int _pendingDelta = 0;
  bool _isVisible = true;
  final List<_FloatingDelta> _deltas = [];

  @override
  void initState() {
    super.initState();
    _prevScore = widget.totalScore;
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _bumpController, curve: Curves.easeInOut),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _bumpController.dispose();
    for (var d in _deltas) d.controller.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _isVisible = false;
  }

  @override
  void didPopNext() {
    _isVisible = true;
    if (_pendingDelta != 0) {
      _addDelta(_pendingDelta);
      _bumpController.forward(from: 0);
      _pendingDelta = 0;
    }
  }

  @override
  void didUpdateWidget(AnimatedScoreBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalScore != _prevScore) {
      int delta = widget.totalScore - _prevScore;
      _prevScore = widget.totalScore;

      if (_isVisible) {
        _addDelta(delta);
        _bumpController.forward(from: 0);
      } else {
        _pendingDelta += delta;
      }
    }
  }

  void _addDelta(int delta) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    final deltaObj = _FloatingDelta(
      delta: delta,
      controller: controller,
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: controller, curve: const Interval(0.5, 1.0)),
      ),
      offset: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, -50),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
    );

    setState(() {
      _deltas.add(deltaObj);
    });

    controller.forward().then((_) {
      setState(() {
        _deltas.remove(deltaObj);
      });
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'GLOBAL SCORE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.totalScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        ..._deltas.map(
          (d) => Positioned(
            right: -10,
            top: 0,
            child: AnimatedBuilder(
              animation: d.controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: d.offset.value,
                  child: Opacity(
                    opacity: d.opacity.value,
                    child: Text(
                      d.delta > 0 ? '+${d.delta}' : '${d.delta}',
                      style: TextStyle(
                        color: d.delta > 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingDelta {
  final int delta;
  final AnimationController controller;
  final Animation<double> opacity;
  final Animation<Offset> offset;

  _FloatingDelta({
    required this.delta,
    required this.controller,
    required this.opacity,
    required this.offset,
  });
}
