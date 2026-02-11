import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'pages/square_page.dart';
import 'pages/encyclopedia_page.dart';
import 'pages/archery_page.dart';
import 'pages/prime_page.dart';
import 'pages/flash_page.dart';
import 'pages/compare_page.dart';
import 'pages/settings_page.dart';
import 'pages/point_page.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/pages/statistics_page.dart';
import 'package:math/pages/missing_sign_page.dart';
import 'package:math/pages/fraction_page.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:math/widgets/avatar_display.dart';
import 'pages/weekday_equation_page.dart';
import 'package:math/services/tts_service.dart';
import 'pages/help_page.dart';

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
    return Selector<UserProvider, String>(
      selector: (context, user) => user.currentTheme,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Math App',
          theme: AppThemes.getTheme(currentTheme),
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
          navigatorObservers: [routeObserver],
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: AvatarDisplay(
                                      avatar: user.currentAvatar,
                                      size: 60,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Hello,',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        user.username,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayLarge
                                            ?.copyWith(fontSize: 28),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  ...user.achievements
                                      .where((a) => a.isUnlocked)
                                      .map(
                                        (a) => GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => MathDialog(
                                                title: 'ACHIEVEMENT',
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      a.icon,
                                                      style: const TextStyle(
                                                        fontSize: 48,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      a.title,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      a.description,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                onConfirm: () {},
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                            ),
                                            child: Text(
                                              a.icon,
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
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
                                  const SizedBox(width: 12),
                                  _buildStreakBadge(user.currentStreak),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: IconButton(
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
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'Square',
                          icon: Icons.exposure_rounded,
                          color: config.vibrantColors[0],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      'Squares from 11 to 31',
                                      config.vibrantColors[0],
                                      isSquare: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      'Squares from 32 to 99',
                                      config.vibrantColors[0],
                                      isSquare: true,
                                    ),
                                  ],
                                ),
                                onConfirm: () {},
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Weekday Equation',
                          icon: Icons.calendar_month_rounded,
                          color: config.vibrantColors[2],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      'Two Days (incl. 31st)',
                                      config.vibrantColors[2],
                                      isWeekday: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      'Three Days Sum',
                                      config.vibrantColors[2],
                                      isWeekday: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      3,
                                      'Level 3',
                                      'Arithmetic Operations',
                                      config.vibrantColors[2],
                                      isWeekday: true,
                                    ),
                                  ],
                                ),
                                onConfirm: () {},
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Math Archery',
                          icon: Icons.gps_fixed_rounded,
                          color: config.vibrantColors[2],
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
                          color: config.vibrantColors[3],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      '11 to 999',
                                      config.vibrantColors[3],
                                      isPrimeDetector: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      '1001 to 9999',
                                      config.vibrantColors[3],
                                      isPrimeDetector: true,
                                    ),
                                  ],
                                ),
                                onConfirm: () {},
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Flash Mental',
                          icon: Icons.flash_on_rounded,
                          color: config.vibrantColors[4],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      '3-digit (x2)',
                                      config.vibrantColors[4],
                                      isFlash: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      '3-digit (x3)',
                                      config.vibrantColors[4],
                                      isFlash: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      3,
                                      'Level 3',
                                      '3-digit (x4)',
                                      config.vibrantColors[4],
                                      isFlash: true,
                                    ),
                                  ],
                                ),
                                onConfirm: () {},
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Sum Comparison',
                          icon: Icons.compare_arrows_rounded,
                          color: config.vibrantColors[5],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      '2-digit + 2-digit + 2-digit',
                                      config.vibrantColors[5],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      '3-digit + 2-digit + 2-digit',
                                      config.vibrantColors[5],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      3,
                                      'Level 3',
                                      '3-digit + 3-digit + 3-digit',
                                      config.vibrantColors[5],
                                    ),
                                  ],
                                ),
                                onConfirm: () {}, // Handled in items
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Missing Sign',
                          icon: Icons.unfold_more_rounded,
                          color: config.vibrantColors[1],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      '3 numbers (+, -)',
                                      config.vibrantColors[1],
                                      isMissingSign: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      '3 numbers (+, -, *, /)',
                                      config.vibrantColors[1],
                                      isMissingSign: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      3,
                                      'Level 3',
                                      '4 numbers (All Ops)',
                                      config.vibrantColors[1],
                                      isMissingSign: true,
                                    ),
                                  ],
                                ),
                                onConfirm: () {},
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Fraction Battle',
                          icon: Icons.pie_chart_rounded,
                          color: config.vibrantColors[1],
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => MathDialog(
                                title: 'CHOOSE LEVEL',
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildLevelOption(
                                      context,
                                      1,
                                      'Level 1',
                                      'Compare Diff Denom',
                                      config.vibrantColors[1],
                                      isFraction: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      2,
                                      'Level 2',
                                      'Add Diff Denom',
                                      config.vibrantColors[1],
                                      isFraction: true,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildLevelOption(
                                      context,
                                      3,
                                      'Level 3',
                                      'Advanced Addition',
                                      config.vibrantColors[1],
                                      isFraction: true,
                                    ),
                                  ],
                                ),
                                onConfirm: () {},
                                showConfirm: false,
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Statistics',
                          icon: Icons.bar_chart_rounded,
                          color: config.vibrantColors[0],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const StatisticsPage(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Math Encyclopedia',
                          icon: Icons.menu_book_rounded,
                          color: config.vibrantColors[1],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const EncyclopediaPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHelpButton(context, config),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        final config =
            AppThemes.configs[user.currentTheme] ??
            AppThemes.configs['Default']!;
        final color = config.primary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                '$streak Days',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelOption(
    BuildContext context,
    int level,
    String title,
    String desc,
    Color color, {
    bool isFlash = false,
    bool isMissingSign = false,
    bool isFraction = false,
    bool isSquare = false,
    bool isWeekday = false,
    bool isPrimeDetector = false,
  }) {
    return InkWell(
      onTap: () {
        TtsService().stop();
        Navigator.pop(context);
        context.read<UserProvider>().addScore(-1);

        Widget page;
        if (isFlash) {
          page = FlashPage(difficulty: level);
        } else if (isMissingSign) {
          page = MissingSignPage(difficulty: level);
        } else if (isFraction) {
          page = FractionPage(difficulty: level);
        } else if (isSquare) {
          page = SquarePage(difficulty: level);
        } else if (isWeekday) {
          page = WeekdayEquationPage(difficulty: level);
        } else if (isPrimeDetector) {
          page = PrimePage(difficulty: level);
        } else {
          page = ComparePage(difficulty: level);
        }

        Navigator.push(context, MaterialPageRoute(builder: (c) => page));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpButton(BuildContext context, ThemeConfig config) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => const HelpPage()),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              config.vibrantColors[0].withOpacity(0.8),
              config.vibrantColors[1].withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: config.vibrantColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'HELP (Game Guide)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
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
    final color = Theme.of(context).primaryColor;
    final accent = Theme.of(context).colorScheme.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), accent.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'GLOBAL SCORE',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.totalScore}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Consumer<UserProvider>(
                  builder: (context, user, child) {
                    if (user.pointMultiplier <= 1)
                      return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x${user.pointMultiplier}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
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
