import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:math/theme/app_theme.dart';
import 'package:math/services/user_provider.dart';

class FractionPage extends StatefulWidget {
  final int difficulty;
  const FractionPage({super.key, required this.difficulty});

  @override
  State<FractionPage> createState() => _FractionPageState();
}

class _FractionPageState extends State<FractionPage> {
  late int num1, den1, num2, den2;
  late String operator;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _mode = 'compare'; // 'compare' or 'arithmetic'
  int _ansN = 1;
  int _ansD = 1;
  bool _isNotSimplified = false;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  void _generateProblem() {
    final random = math.Random();
    _isAnswered = false;
    _isCorrect = false;
    _ansN = 1;
    _ansD = 1;

    if (widget.difficulty == 1) {
      _mode = 'compare';
      den1 = random.nextInt(7) + 2;
      den2 = random.nextInt(7) + 2;
      while (den1 == den2) den2 = random.nextInt(7) + 2;

      num1 = random.nextInt(den1 - 1) + 1;
      num2 = random.nextInt(den2 - 1) + 1;

      while (num1 * den2 == num2 * den1) {
        num2 = random.nextInt(den2 - 1) + 1;
      }
    } else if (widget.difficulty == 2) {
      _mode = 'arithmetic';
      den1 = random.nextInt(4) + 2; // 2, 3, 4, 5
      den2 = random.nextInt(4) + 2; // 2, 3, 4, 5
      while (den1 == den2) den2 = random.nextInt(4) + 2;

      num1 = 1;
      num2 = 1;
      operator = '+';
    } else {
      // Level 3
      _mode = 'arithmetic';
      den1 = random.nextInt(8) + 3; // 3-10
      den2 = random.nextInt(8) + 3; // 3-10
      while (den1 == den2) den2 = random.nextInt(8) + 3;

      num1 = random.nextInt(den1 - 2) + 1;
      num2 = random.nextInt(den2 - 2) + 1;
      operator = '+';
    }
    setState(() {});
  }

  void _checkCompare(int index) {
    if (_isAnswered) return;

    double val1 = num1 / den1;
    double val2 = num2 / den2;

    bool correct = false;
    if (index == 1 && val1 > val2) correct = true;
    if (index == 2 && val2 > val1) correct = true;
    if (val1 == val2) correct = true;

    _handleResult(correct);
  }

  void _checkArithmetic(int n, int d) {
    if (_isAnswered) return;
    if (d == 0) return;

    int targetN = num1 * den2 + num2 * den1;
    int targetD = den1 * den2;

    int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);

    int commonTarget = gcd(targetN, targetD);
    targetN ~/= commonTarget;
    targetD ~/= commonTarget;

    int commonInput = gcd(n, d);
    int simplifiedN = n ~/ commonInput;
    int simplifiedD = d ~/ commonInput;

    bool valueCorrect = (simplifiedN == targetN && simplifiedD == targetD);
    bool irreducible = (commonInput == 1);

    _isNotSimplified = valueCorrect && !irreducible;
    bool finalCorrect = valueCorrect && irreducible;

    _handleResult(finalCorrect);
  }

  void _handleResult(bool correct) {
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    if (correct) {
      int score = widget.difficulty == 1 ? 2 : (widget.difficulty == 2 ? 3 : 5);
      context.read<UserProvider>().addScore(score, gameName: 'Fraction Battle');
    } else {
      int penalty = widget.difficulty == 1
          ? -1
          : (widget.difficulty == 2 ? -2 : -3);
      context.read<UserProvider>().addScore(
        penalty,
        gameName: 'Fraction Battle (Incorrect)',
      );
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _generateProblem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

    return Scaffold(
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
            child: Column(
              children: [
                _buildHeader(context, config),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_mode == 'compare') _buildCompareView(config),
                          if (_mode == 'arithmetic')
                            _buildArithmeticView(config),
                          const SizedBox(height: 32),
                          if (_mode == 'compare')
                            const Text(
                              'Select the larger fraction!',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (_isAnswered) _buildFeedback(config),
                          if (_mode == 'arithmetic' && !_isAnswered)
                            _buildCustomKeyboard(config),
                        ],
                      ),
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

  String _currentFocus = 'N'; // 'N' for Numerator, 'D' for Denominator
  String _numInput = '';
  String _denInput = '';

  void _onNumberPressed(int n) {
    if (_isAnswered) return;
    setState(() {
      if (_currentFocus == 'N') {
        if (_numInput.length < 3) _numInput += n.toString();
        _ansN = int.tryParse(_numInput) ?? 0;
      } else {
        if (_denInput.length < 3) _denInput += n.toString();
        _ansD = int.tryParse(_denInput) ?? 0;
      }
    });
  }

  void _onBackspace() {
    if (_isAnswered) return;
    setState(() {
      if (_currentFocus == 'N') {
        if (_numInput.isNotEmpty) {
          _numInput = _numInput.substring(0, _numInput.length - 1);
          _ansN = int.tryParse(_numInput) ?? 0;
        }
      } else {
        if (_denInput.isNotEmpty) {
          _denInput = _denInput.substring(0, _denInput.length - 1);
          _ansD = int.tryParse(_denInput) ?? 0;
        }
      }
    });
  }

  Widget _buildHeader(BuildContext context, ThemeConfig config) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
            ),
          ),
          Column(
            children: [
              Text(
                'Fraction Battle',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 20),
              ),
              Text(
                'Level ${widget.difficulty}',
                style: TextStyle(
                  color: config.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCompareView(ThemeConfig config) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFractionCard(
              num1,
              den1,
              config.vibrantColors[0],
              onTap: () => _checkCompare(1),
            ),
            _buildFractionCard(
              num2,
              den2,
              config.vibrantColors[1],
              onTap: () => _checkCompare(2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArithmeticView(ThemeConfig config) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFractionCard(num1, den1, config.vibrantColors[0]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: config.textColor,
                ),
              ),
            ),
            _buildFractionCard(num2, den2, config.vibrantColors[1]),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          'Enter IRREDUCIBLE result',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                _buildNumberDisplay(
                  'Numerator',
                  _numInput.isEmpty ? '?' : _numInput,
                  _currentFocus == 'N',
                  onTap: () => setState(() => _currentFocus = 'N'),
                ),
                Container(
                  width: 80,
                  height: 3,
                  color: Colors.white54,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
                _buildNumberDisplay(
                  'Denominator',
                  _denInput.isEmpty ? '?' : _denInput,
                  _currentFocus == 'D',
                  onTap: () => setState(() => _currentFocus = 'D'),
                ),
              ],
            ),
            const SizedBox(width: 24),
            _buildCheckButton(config),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberDisplay(
    String label,
    String value,
    bool isFocused, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: isFocused
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused ? Colors.orangeAccent : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isFocused ? Colors.orangeAccent : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckButton(ThemeConfig config) {
    return InkWell(
      onTap: _isAnswered ? null : () => _checkArithmetic(_ansN, _ansD),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        width: 80,
        decoration: BoxDecoration(
          color: config.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.accent.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: config.accent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: config.accent, size: 32),
            const SizedBox(height: 8),
            Text(
              'CHECK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: config.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomKeyboard(ThemeConfig config) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3, 4, 5]
                .map(
                  (n) => _buildKeyboardButton(
                    n.toString(),
                    () => _onNumberPressed(n),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [6, 7, 8, 9, 0]
                .map(
                  (n) => _buildKeyboardButton(
                    n.toString(),
                    () => _onNumberPressed(n),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeyboardButton(
                'CLEAR',
                () {
                  setState(() {
                    if (_currentFocus == 'N') {
                      _numInput = '';
                      _ansN = 0;
                    } else {
                      _denInput = '';
                      _ansD = 0;
                    }
                  });
                },
                width: 120,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
              _buildKeyboardButton(
                '⌫',
                _onBackspace,
                width: 80,
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardButton(
    String label,
    VoidCallback onTap, {
    double width = 60,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: 50,
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (color ?? Colors.white).withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 1 ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFractionCard(
    int num,
    int den,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: _isAnswered ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          if (widget.difficulty != 1)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: CustomPaint(
                painter: PizzaPainter(num: num, den: den, color: color),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white10,
                size: 48,
              ),
            ),
          const SizedBox(height: 12),
          Column(
            children: [
              Text(
                '$num',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 30,
                height: 2,
                color: Colors.white70,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              Text(
                '$den',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(ThemeConfig config) {
    String feedbackText = '';
    Color feedbackColor = Colors.red;

    if (_isCorrect) {
      feedbackText = 'Correct! +${widget.difficulty == 1 ? 2 : 3}';
      feedbackColor = Colors.green;
    } else if (_isNotSimplified) {
      feedbackText = 'Simplify it!';
      feedbackColor = Colors.orange;
    } else {
      feedbackText = 'Incorrect! ${widget.difficulty == 1 ? -1 : -2}';
      feedbackColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: feedbackColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: feedbackColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCorrect
                ? Icons.check_circle_rounded
                : (_isNotSimplified
                      ? Icons.info_outline_rounded
                      : Icons.cancel_rounded),
            color: feedbackColor,
          ),
          const SizedBox(width: 8),
          Text(
            feedbackText,
            style: TextStyle(
              color: feedbackColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class PizzaPainter extends CustomPainter {
  final int num;
  final int den;
  final Color color;

  PizzaPainter({required this.num, required this.den, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final slicePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    double sweepAngle = (2 * math.pi) / den;
    for (int i = 0; i < num; i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + (i * sweepAngle),
        sweepAngle,
        true,
        slicePaint,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 0; i < den; i++) {
      double angle = -math.pi / 2 + (i * sweepAngle);
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        linePaint,
      );
    }

    final borderPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant PizzaPainter oldDelegate) =>
      oldDelegate.num != num || oldDelegate.den != den;
}
