import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart' as exp;
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

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
    with SingleTickerProviderStateMixin {
  int _score = 0;
  List<TargetData> _targets = [];
  List<int> _baseNumbers = [];
  List<int> _usedIndices = [];
  String _currentExpression = '';
  int _sessionScoreChange = -1; // -1 for entry fee

  // Animation controllers
  late AnimationController _arrowController;
  Animation<Offset>? _arrowAnimation;
  Offset _animStart = Offset.zero;
  Offset _animEnd = Offset.zero;
  int? _animatingTargetIndex;
  bool _isAnimating = false;
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
        MathDialog.show(
          context,
          title: 'MISSED!',
          message:
              'Result: ${eval.toStringAsFixed(eval % 1 == 0 ? 0 : 1)}. Try another way!',
          isSuccess: false,
        );
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
      // Fallback if keys are not ready
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

    await _arrowController.forward(from: 0);

    setState(() {
      _isAnimating = false;
    });

    _onHitResult(target);
  }

  void _onHitResult(TargetData target) {
    setState(() {
      target.isSolved = true;
      _score += target.points;
      _sessionScoreChange += target.points;
      context.read<UserProvider>().addScore(target.points);
      _generateNumbers();
    });

    int solvedCount = _targets.where((t) => t.isSolved).length;
    if (solvedCount == _targets.length) {
      MathDialog.show(
        context,
        title: 'PERFECT SCORE!',
        message: 'You cleared all targets with these numbers! AMAZING!',
        isSuccess: true,
        onConfirm: _startNewFullRound,
      );
    } else {
      MathDialog.show(
        context,
        title: '🎯 BULLS-EYE!',
        message:
            'Hit target! Scored ${target.points} pt. ${_targets.length - solvedCount} targets left.',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Archery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'SCORE: $_score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _startNewFullRound(isManual: true),
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Skip Round (-1pt)',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _currentExpression.isEmpty
                                ? 'Hit all 12 targets!'
                                : _currentExpression,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _currentExpression.isEmpty
                                  ? Colors.white24
                                  : AppColors.accent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Available Numbers',
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_baseNumbers.length, (
                                index,
                              ) {
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
                                      horizontal: 6,
                                    ),
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: fullyUsed
                                          ? Colors.white10
                                          : AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: usageCount > 0
                                            ? AppColors.primary
                                            : AppColors.primary.withOpacity(
                                                0.5,
                                              ),
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
                                                  : Colors.white,
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
                                                      ? AppColors.accent
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
                            ),
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: _passRound,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.accent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'PASS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
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
                _buildKeypad(),
                const SizedBox(height: 20),
              ],
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
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: AppColors.accent,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
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

  Widget _buildTargetItem(int index) {
    if (index >= _targets.length) return const SizedBox();
    final target = _targets[index];
    bool solved = target.isSolved;
    bool isBeingHit = _isAnimating && _animatingTargetIndex == index;

    return Container(
      key: _targetKeys[index],
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: solved ? Colors.black45 : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: solved ? Colors.white10 : AppColors.primary.withOpacity(0.15),
        ),
        boxShadow: [
          if (isBeingHit)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
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
              color: solved ? Colors.white24 : AppColors.accent,
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
              color: solved ? Colors.white24 : Colors.white,
              decoration: solved ? TextDecoration.lineThrough : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildKeyRow(['+', '-', '*', '÷']),
          const SizedBox(height: 8),
          _buildKeyRow(['(', ')', '^', '!', '√']),
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys
          .map(
            (key) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () => _onOperatorTap(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBg,
                    foregroundColor: Colors.white,
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
