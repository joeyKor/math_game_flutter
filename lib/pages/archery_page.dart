import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart' as exp;
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';
import 'package:vibration/vibration.dart';

class ArcheryPage extends StatefulWidget {
  const ArcheryPage({super.key});

  @override
  State<ArcheryPage> createState() => _ArcheryPageState();
}

class TargetData {
  int value;
  int points;
  bool isSolved;
  TargetData({
    required this.value,
    required this.points,
    this.isSolved = false,
  });
}

class _ArcheryPageState extends State<ArcheryPage>
    with TickerProviderStateMixin {
  int _score = 0;
  List<TargetData> _targets = [];
  List<int> _baseNumbers = [];
  List<int> _usedIndices = [];
  String _currentExpression = '';
  int _sessionScoreChange = -1; // -1 for entry fee
  int _roundMisses = 0;

  // Animation controllers
  late AnimationController _arrowController;
  Animation<Offset>? _arrowAnimation;
  Offset _animStart = Offset.zero;
  Offset _animEnd = Offset.zero;
  int? _animatingTargetIndex;
  bool _isAnimating = false;
  bool _showBullseye = false;
  bool _showSniper = false;
  bool _showGoldenHit = false;
  bool _showComboBonus = false;
  int _comboCount = 0;
  late AnimationController _bullseyeController;
  late AnimationController _shakeController;
  late Animation<double> _bullseyeScale;
  late Animation<double> _bullseyeOpacity;
  late Animation<Offset> _shakeAnimation;
  late UserProvider _userProvider;

  final GlobalKey _shootButtonKey = GlobalKey();
  final List<GlobalKey> _targetKeys = List.generate(12, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bullseyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bullseyeScale = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_bullseyeController);
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(8, 0)),
        weight: 25,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(
          begin: const Offset(8, 0),
          end: const Offset(-8, 0),
        ),
        weight: 50,
      ),
      TweenSequenceItem<Offset>(
        tween: Tween<Offset>(begin: const Offset(-8, 0), end: Offset.zero),
        weight: 25,
      ),
    ]).animate(_shakeController);
    _bullseyeOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_bullseyeController);
    _startNewFullRound();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _bullseyeController.dispose();
    _shakeController.dispose();
    // Record session total to history
    _userProvider.addHistoryEntry(_sessionScoreChange, 'Math Archery Session');
    super.dispose();
  }

  void _startNewFullRound({bool isManual = false}) {
    if (isManual) {
      setState(() {
        _score -= 1;
        _sessionScoreChange -= 1;
      });
      _userProvider.addScore(-1);
    }
    _roundMisses = 0;
    _comboCount = 0;
    _generateNumbers();
    _refreshTargets();
  }

  void _generateNumbers() {
    final random = math.Random();
    List<int> numbers = [];
    while (numbers.length < 4) {
      int n = random.nextInt(7) + 1;
      int currentCount = numbers.where((x) => x == n).length;
      if (currentCount < 2) {
        numbers.add(n);
      }
    }
    _baseNumbers = numbers;
    _usedIndices = [];
    _currentExpression = '';
  }

  void _refreshTargets() {
    final random = math.Random();
    _targets = [];
    Set<int> usedValues = {};

    void addUniqueTarget(int min, int max, int points) {
      int val;
      do {
        val = random.nextInt(max - min + 1) + min;
      } while (usedValues.contains(val));
      usedValues.add(val);
      _targets.add(TargetData(value: val, points: points));
    }

    // 2 targets for 1pt (1-9)
    for (int i = 0; i < 2; i++) addUniqueTarget(1, 9, 1);
    // 4 targets for 3pt (10-99)
    for (int i = 0; i < 4; i++) addUniqueTarget(10, 99, 3);
    // 4 targets for 10pt (100-999)
    for (int i = 0; i < 4; i++) addUniqueTarget(100, 999, 10);
    // 2 targets for 50pt (1000-9999)
    for (int i = 0; i < 2; i++) addUniqueTarget(1000, 9999, 50);

    setState(() {});
  }

  void _passRound() {
    setState(() {
      _score -= 1;
      _sessionScoreChange -= 1;
      _roundMisses = 0;
      _comboCount = 0;
      _generateNumbers();
    });
    _userProvider.addScore(-1);
  }

  void _onNumberTap(int index) {
    int count = _usedIndices.where((i) => i == index).length;
    if (count >= 2) return;

    setState(() {
      _usedIndices.add(index);
      _currentExpression += _baseNumbers[index].toString();
    });
  }

  void _onOperatorTap(String op) {
    setState(() {
      _currentExpression += op;
    });
  }

  void _onClear() {
    setState(() {
      _usedIndices = [];
      _currentExpression = '';
    });
  }

  void _onDelete() {
    if (_currentExpression.isEmpty) return;
    setState(() {
      String lastChar = _currentExpression.substring(
        _currentExpression.length - 1,
      );
      if (int.tryParse(lastChar) != null) {
        // If it's a digit, it must be the last used index
        if (_usedIndices.isNotEmpty) {
          _usedIndices.removeLast();
        }
      }
      _currentExpression = _currentExpression.substring(
        0,
        _currentExpression.length - 1,
      );
    });
  }

  double _factorial(double n) {
    if (n < 0 || n > 12) return double.nan;
    if (n == 0) return 1;
    double res = 1;
    for (int i = 1; i <= n.toInt(); i++) res *= i;
    return res;
  }

  void _checkAnswer() {
    // All 4 base numbers must be used at least once
    if (Set.from(_usedIndices).length != 4) {
      MathDialog.show(
        context,
        title: 'WAIT!',
        message: 'Please use all 4 base numbers at least once.',
        isSuccess: false,
      );
      return;
    }

    // Validate single digits
    final numberRegex = RegExp(r'\d+');
    final matches = numberRegex.allMatches(_currentExpression);
    for (final match in matches) {
      if (match.group(0)!.length > 1) {
        MathDialog.show(
          context,
          title: 'HINT',
          message: 'Numbers must be used as single digits (e.g., 3*4, not 34).',
          isSuccess: false,
        );
        return;
      }
    }

    try {
      String exprStr = _currentExpression.replaceAll('÷', '/');

      // Exponentiation Polish
      if (RegExp(r'\^($|[^\d\(])').hasMatch(exprStr)) {
        MathDialog.show(
          context,
          title: 'FORMULA ERROR',
          message: 'An exponent (number) must follow the power (^) symbol.',
          isSuccess: false,
        );
        return;
      }

      // Factorial Pre-processing
      final bracketFactRegex = RegExp(r'\(([^()]+)\)!');
      while (bracketFactRegex.hasMatch(exprStr)) {
        exprStr = exprStr.replaceFirstMapped(bracketFactRegex, (match) {
          String inner = match.group(1)!;
          exp.Parser p = exp.Parser();
          double innerVal = p
              .parse(inner)
              .evaluate(exp.EvaluationType.REAL, exp.ContextModel());
          return _factorial(innerVal).toInt().toString();
        });
      }
      final numFactRegex = RegExp(r'(\d+)!');
      while (numFactRegex.hasMatch(exprStr)) {
        exprStr = exprStr.replaceFirstMapped(numFactRegex, (match) {
          double val = double.parse(match.group(1)!);
          return _factorial(val).toInt().toString();
        });
      }

      // Root Pre-processing
      // Handle √(expr) -> sqrt(expr)
      final bracketRootRegex = RegExp(r'√\(([^()]+)\)');
      while (bracketRootRegex.hasMatch(exprStr)) {
        exprStr = exprStr.replaceFirstMapped(bracketRootRegex, (match) {
          return 'sqrt(${match.group(1)})';
        });
      }
      // Handle √number -> sqrt(number)
      final numRootRegex = RegExp(r'√(\d+)');
      while (numRootRegex.hasMatch(exprStr)) {
        exprStr = exprStr.replaceFirstMapped(numRootRegex, (match) {
          return 'sqrt(${match.group(1)})';
        });
      }

      exp.Parser p = exp.Parser();
      exp.Expression expObj = p.parse(exprStr);
      double eval = expObj.evaluate(
        exp.EvaluationType.REAL,
        exp.ContextModel(),
      );

      TargetData? hitTarget;
      for (var target in _targets) {
        if (!target.isSolved && (eval - target.value).abs() < 0.0001) {
          hitTarget = target;
          break;
        }
      }

      if (hitTarget != null) {
        int hitIndex = _targets.indexOf(hitTarget);
        _playArrowAnimation(hitIndex, hitTarget);
      } else {
        setState(() {
          _score -= 1;
          _sessionScoreChange -= 1;
        });
        context.read<UserProvider>().addScore(-1);

        final user = context.read<UserProvider>();
        final resultStr = eval.toStringAsFixed(eval % 1 == 0 ? 0 : 1);

        MathDialog.show(
          context,
          title: 'MISSED!',
          message: CommentaryService.getMissPhrase(
            user.username,
            result: resultStr,
          ),
          isSuccess: false,
        );
        _roundMisses++;
        _comboCount = 0; // Reset combo on miss
      }
    } catch (e) {
      MathDialog.show(
        context,
        title: 'INVALID',
        message: 'The expression could not be calculated.',
        isSuccess: false,
      );
    }
  }

  void _playArrowAnimation(int targetIndex, TargetData target) async {
    final RenderBox? shootBox =
        _shootButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? targetBox =
        _targetKeys[targetIndex].currentContext?.findRenderObject()
            as RenderBox?;

    if (shootBox == null || targetBox == null) {
      _onHitResult(target);
      return;
    }

    final shootPos =
        shootBox.localToGlobal(Offset.zero) +
        Offset(shootBox.size.width / 2, shootBox.size.height / 2);
    final targetPos =
        targetBox.localToGlobal(Offset.zero) +
        Offset(targetBox.size.width / 2, targetBox.size.height / 2);

    setState(() {
      _isAnimating = true;
      _animatingTargetIndex = targetIndex;
      _animStart = shootPos;
      _animEnd = targetPos;
      _arrowAnimation = Tween<Offset>(begin: shootPos, end: targetPos).animate(
        CurvedAnimation(parent: _arrowController, curve: Curves.easeIn),
      );
    });

    // Safety timeout: Reset animation flag anyway after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isAnimating) {
        setState(() => _isAnimating = false);
      }
    });

    try {
      await _arrowController
          .forward(from: 0)
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () => _arrowController.stop(),
          );
    } catch (_) {
    } finally {
      if (mounted) _onHitResult(target);
    }
  }

  void _onHitResult(TargetData target) {
    if (!mounted) return;

    int comboBonus = 0;
    int solvedCount = 0;
    final user = context.read<UserProvider>();

    try {
      setState(() {
        _isAnimating = false;
        if (target.isSolved) return; // Already processed

        target.isSolved = true;
        _score += target.points;
        _sessionScoreChange += target.points;
        _comboCount++;

        comboBonus = _comboCount;

        if (comboBonus > 0) {
          _score += comboBonus;
          _sessionScoreChange += comboBonus;
        }

        solvedCount = _targets.where((t) => t.isSolved).length;
      });

      // Background updates (don't await)
      user.addScore(target.points, gameName: 'Math Archery').catchError((_) {});
      if (comboBonus > 0) {
        user
            .addScore(comboBonus, gameName: 'Math Archery Combo')
            .catchError((_) {});
      }

      // Visuals
      String anim = '';
      if (_comboCount >= 2) {
        anim = (_comboCount % 5 == 0) ? 'milestone' : 'combo';
      } else if (_usedIndices.toSet().length == 4) {
        anim = 'sniper';
      } else if (_usedIndices.length == 4) {
        anim = 'bullseye';
      } else if (target.points == 50) {
        anim = 'golden';
      }

      if (anim.isNotEmpty) _triggerSpecialAnimation(anim);

      // Sound & Vibration (Safe for Windows)
      bool isDesktop =
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS;

      if (!isDesktop) {
        try {
          if (user.isVibrationEnabled) Vibration.vibrate(duration: 50);
        } catch (_) {}
      }

      bool isPerfect = solvedCount == _targets.length;
      if (isPerfect) {
        int bonus = 50;
        if (_roundMisses == 0) bonus += 100;

        setState(() {
          _score += bonus;
          _sessionScoreChange += bonus;
        });
        user
            .addScore(bonus, gameName: 'Math Archery Perfect')
            .catchError((_) {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            MathDialog.show(
              context,
              title: _roundMisses == 0
                  ? 'LEGENDARY SHARPSHOOTER!'
                  : 'PERFECT SCORE!',
              message: _roundMisses == 0
                  ? 'Flawless victory! No misses! +150 points!'
                  : CommentaryService.getWinPhrase(user.username),
              isSuccess: true,
              onConfirm: _startNewFullRound,
            );
          }
        });
      } else if (user.isTtsEnabled) {
        TtsService().speak(
          CommentaryService.getHitPhrase(
            user.username,
            target: target.value.toString(),
            formula: _currentExpression.replaceAll('÷', ' divided by '),
          ),
        );
      }

      setState(() {
        _generateNumbers();
      });
    } catch (e) {
      debugPrint("Error in _onHitResult: $e");
      setState(() => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final color = Theme.of(context).primaryColor;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Math Archery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SCORE: $_score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: accent,
                      ),
                    ),
                    if (_comboCount > 0)
                      Text(
                        '$_comboCount COMBO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.cyanAccent,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () => _startNewFullRound(isManual: true),
                  icon: Icon(Icons.refresh, color: color.withOpacity(0.7)),
                  tooltip: 'Skip Round (-1pt)',
                ),
              ],
            ),
          ),
        ],
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
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: _shakeAnimation.value,
                  child: child,
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.9,
                            children: List.generate(_targets.length, (index) {
                              return _buildTargetItem(index);
                            }),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardTheme.color?.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Text(
                              _currentExpression.isEmpty
                                  ? 'Hit all 12 targets!'
                                  : _currentExpression,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _currentExpression.isEmpty
                                    ? color.withOpacity(0.3)
                                    : accent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Available Numbers',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...List.generate(_baseNumbers.length, (index) {
                                int usageCount = _usedIndices
                                    .where((i) => i == index)
                                    .length;
                                bool fullyUsed = usageCount >= 2;

                                return GestureDetector(
                                  onTap: fullyUsed
                                      ? null
                                      : () => _onNumberTap(index),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: fullyUsed
                                          ? Colors.white10
                                          : Theme.of(
                                              context,
                                            ).cardTheme.color?.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: usageCount > 0
                                            ? color
                                            : color.withOpacity(0.5),
                                        width: usageCount > 0 ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Text(
                                            '${_baseNumbers[index]}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: fullyUsed
                                                  ? Colors.white24
                                                  : Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.color,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 4,
                                          bottom: 4,
                                          child: Row(
                                            children: List.generate(2, (i) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  left: 2,
                                                ),
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: i < usageCount
                                                      ? accent
                                                      : Colors.white10,
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _passRound,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'PASS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildKeypad(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isAnimating && _arrowAnimation != null)
            AnimatedBuilder(
              animation: _arrowController,
              builder: (context, child) {
                final pos = _arrowAnimation!.value;
                return Positioned(
                  left: pos.dx - 20,
                  top: pos.dy - 20,
                  child: Transform.rotate(
                    angle: _calculateArrowAngle(),
                    child: Icon(
                      Icons.navigation_rounded,
                      color: accent,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          if (_showBullseye)
            Center(
              child: FadeTransition(
                opacity: _bullseyeOpacity,
                child: ScaleTransition(
                  scale: _bullseyeScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed_rounded, color: accent, size: 100),
                      const SizedBox(height: 10),
                      Text(
                        'BULLSEYE!',
                        style: TextStyle(
                          color: accent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Perfect Resource Use!',
                        style: TextStyle(
                          color: accent.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showSniper)
            Center(
              child: FadeTransition(
                opacity: _bullseyeOpacity,
                child: ScaleTransition(
                  scale: _bullseyeScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.track_changes_rounded,
                        color: Colors.redAccent,
                        size: 100,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'SNIPER!',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Unique Mastery!',
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showGoldenHit)
            Center(
              child: FadeTransition(
                opacity: _bullseyeOpacity,
                child: ScaleTransition(
                  scale: _bullseyeScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.amber, size: 100),
                      const SizedBox(height: 10),
                      Text(
                        'JACKPOT!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Mega Target Down!',
                        style: TextStyle(
                          color: Colors.amber.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showComboBonus)
            Center(
              child: FadeTransition(
                opacity: _bullseyeOpacity,
                child: ScaleTransition(
                  scale: _bullseyeScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.cyanAccent,
                        size: 100,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_comboCount COMBO!',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bonus +$_comboCount Points!',
                        style: TextStyle(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateArrowAngle() {
    return math.atan2(
          _animEnd.dy - _animStart.dy,
          _animEnd.dx - _animStart.dx,
        ) +
        (math.pi / 2);
  }

  void _triggerSpecialAnimation(String type) {
    setState(() {
      _showBullseye = type == 'bullseye';
      _showSniper = type == 'sniper';
      _showGoldenHit = type == 'golden';
      _showComboBonus = type == 'combo' || type == 'milestone';
    });
    if (type == 'milestone') {
      _shakeController.forward(from: 0);
    }
    _bullseyeController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _showBullseye = false;
          _showSniper = false;
          _showGoldenHit = false;
          _showComboBonus = false;
        });
      }
    });
  }

  Widget _buildTargetItem(int index) {
    if (index >= _targets.length) return const SizedBox();
    final target = _targets[index];
    bool solved = target.isSolved;
    bool isBeingHit = _isAnimating && _animatingTargetIndex == index;
    final accent = Theme.of(context).colorScheme.secondary;

    return Container(
      key: _targetKeys[index],
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: solved
            ? Colors.black45
            : Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: solved
              ? Colors.white10
              : Theme.of(context).primaryColor.withOpacity(0.15),
        ),
        boxShadow: [
          if (isBeingHit)
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: solved ? Colors.white24 : accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${target.points} pt',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: solved ? Colors.white54 : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${target.value}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: solved
                  ? Colors.white24
                  : Theme.of(context).textTheme.titleLarge?.color,
              decoration: solved ? TextDecoration.lineThrough : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildKeyRow(context, ['+', '-', '*', '÷']),
          const SizedBox(height: 8),
          _buildKeyRow(context, ['(', ')', '^', '!', '√']),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: _onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                      foregroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'DEL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: _onClear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CLEAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    key: _shootButtonKey,
                    onPressed: _isAnimating ? null : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'SHOOT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(BuildContext context, List<String> keys) {
    return Row(
      children: keys
          .map(
            (key) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () => _onOperatorTap(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).cardTheme.color?.withOpacity(0.7),
                    foregroundColor: Theme.of(
                      context,
                    ).textTheme.titleLarge?.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
