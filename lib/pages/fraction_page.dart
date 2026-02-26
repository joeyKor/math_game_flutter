import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:math/theme/app_theme.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:vibration/vibration.dart';

class FractionPage extends StatefulWidget {
  final int difficulty;
  const FractionPage({super.key, required this.difficulty});

  @override
  State<FractionPage> createState() => _FractionPageState();
}

class _FractionData {
  int num;
  int den;
  _FractionData(this.num, this.den);
}

class _FractionPageState extends State<FractionPage>
    with TickerProviderStateMixin {
  List<_FractionData> _problemFractions = [];
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _mode = 'compare'; // 'compare' or 'arithmetic'
  int _ansN = 1;
  int _ansD = 1;
  bool _isNotSimplified = false;
  List<int> _selectedIndices = [];
  int _comboCount = 0;

  // Animation logic
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;

  @override
  void initState() {
    super.initState();
    _comboController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _comboOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_comboController);
    _comboScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_comboController);

    _generateProblem();
  }

  @override
  void dispose() {
    _comboController.dispose();
    super.dispose();
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
    });
  }

  void _generateProblem() {
    final random = math.Random();
    _isAnswered = false;
    _isCorrect = false;
    _isNotSimplified = false;
    _ansN = 1;
    _ansD = 1;
    _numInput = '';
    _denInput = '';
    _currentFocus = 'N';

    if (widget.difficulty == 1) {
      _mode = 'compare';
      _problemFractions = [];
      _selectedIndices = [];
      int attempts = 0;
      while (_problemFractions.length < 2 && attempts < 100) {
        attempts++;
        int den = random.nextInt(8) + 2; // 2-9
        int num = random.nextInt(den - 1) + 1;
        _FractionData newFrag = _FractionData(num, den);

        // Ensure no duplicates by value
        bool duplicate = _problemFractions.any(
          (f) => f.num * newFrag.den == newFrag.num * f.den,
        );
        if (!duplicate) {
          _problemFractions.add(newFrag);
        }
      }
    } else if (widget.difficulty == 2) {
      _mode = 'arithmetic';
      // Level 2: 2 fractions addition
      int den1 = random.nextInt(5) + 2; // 2-6
      int den2 = random.nextInt(5) + 2; // 2-6
      int num1 = random.nextInt(den1 - 1) + 1;
      int num2 = random.nextInt(den2 - 1) + 1;
      _problemFractions = [
        _FractionData(num1, den1),
        _FractionData(num2, den2),
      ];
    } else {
      // Level 3: 3 fractions addition
      _mode = 'arithmetic';
      _problemFractions = [];
      for (int i = 0; i < 3; i++) {
        int den = random.nextInt(6) + 2; // 2-7
        int num = random.nextInt(den - 1) + 1;
        _problemFractions.add(_FractionData(num, den));
      }
    }
    setState(() {});
  }

  int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);

  void _checkCompare(int index) {
    // If tapping the LAST selected index, allow deselection (UNDO)
    if (_selectedIndices.isNotEmpty && _selectedIndices.last == index) {
      setState(() {
        _selectedIndices.removeLast();
      });
      return;
    }

    if (_selectedIndices.contains(index)) return;

    final clickedVal =
        _problemFractions[index].num / _problemFractions[index].den;

    // Check if there's any unselected fraction larger than the clicked one
    bool isLargest = true;
    for (int i = 0; i < _problemFractions.length; i++) {
      if (!_selectedIndices.contains(i)) {
        if (_problemFractions[i].num / _problemFractions[i].den >
            clickedVal + 0.00001) {
          isLargest = false;
          break;
        }
      }
    }

    if (isLargest) {
      setState(() {
        _selectedIndices.add(index);
      });
      if (_selectedIndices.length == _problemFractions.length) {
        _handleResult(true);
      }
    } else {
      _handleResult(false);
    }
  }

  void _checkArithmetic(int n, int d) {
    if (_isAnswered) return;
    if (d == 0) return;

    // Calculate sum of all fractions
    int commonDen = 1;
    for (var f in _problemFractions) {
      commonDen *= f.den;
    }

    int totalNum = 0;
    for (var f in _problemFractions) {
      totalNum += f.num * (commonDen ~/ f.den);
    }

    int commonGCD = gcd(totalNum, commonDen);
    int targetN = totalNum ~/ commonGCD;
    int targetD = commonDen ~/ commonGCD;

    int inputGCD = gcd(n, d);
    int simplifiedN = n ~/ inputGCD;
    int simplifiedD = d ~/ inputGCD;

    bool valueCorrect = (simplifiedN == targetN && simplifiedD == targetD);
    bool irreducible = (inputGCD == 1);

    if (valueCorrect && !irreducible) {
      setState(() {
        _isNotSimplified = true;
      });
      return; // Wait for user to simplify
    }

    bool finalCorrect = valueCorrect && irreducible;
    _handleResult(finalCorrect);
  }

  void _handleResult(bool correct) {
    final user = context.read<UserProvider>();
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });

    if (correct) {
      _comboCount++;
      int comboBonus = _comboCount;
      int score = widget.difficulty == 1
          ? 3
          : (widget.difficulty == 2 ? 5 : 10);
      user.addScore(score);
      user.addDiamonds(comboBonus);

      _triggerComboAnimation();

      if (user.isTtsEnabled) {
        TtsService().speak(CommentaryService.getHitPhrase(user.username));
      }
      if (user.isVibrationEnabled) {
        bool isDesktop =
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS;
        if (!isDesktop) {
          try {
            Vibration.vibrate(duration: 50);
          } catch (e) {
            debugPrint('Vibration error: $e');
          }
        }
      }

      if (_comboCount >= 20) {
        MathDialog.show(
          context,
          title: 'FRACTION ACE!',
          message:
              'LEGENDARY 20 COMBO REACHED!\nYou are a fraction specialist!\nTotal Score: ${user.totalScore}',
          isSuccess: true,
          onConfirm: () => Navigator.pop(context),
        );
        return;
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _generateProblem();
      });
    } else {
      _comboCount = 0;
      int penalty = widget.difficulty == 1
          ? -1
          : (widget.difficulty == 2 ? -2 : -4);
      user.addScore(penalty, gameName: 'Fraction Battle (Incorrect)');

      String explanation = '';
      if (widget.difficulty == 1) {
        // Sort fractions to show correct order
        List<_FractionData> sorted = List.from(_problemFractions);
        sorted.sort((a, b) => (b.num / b.den).compareTo(a.num / a.den));
        explanation =
            'Correct Order:\n${sorted.map((f) => '${f.num}/${f.den}').join(' > ')}';
      } else {
        // Calculate correct sum
        int commonDen = 1;
        for (var f in _problemFractions) commonDen *= f.den;
        int totalNum = 0;
        for (var f in _problemFractions) {
          totalNum += f.num * (commonDen ~/ f.den);
        }
        int commonGCD = gcd(totalNum, commonDen);
        explanation =
            'Correct Answer: ${totalNum ~/ commonGCD}/${commonDen ~/ commonGCD}';
      }

      MathDialog.show(
        context,
        title: 'GAME OVER!',
        message: 'You made a mistake!\n$explanation',
        isSuccess: false,
        onConfirm: () => Navigator.pop(context),
      );
    }
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
                          if (_isNotSimplified) _buildSimplifiedHint(),
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
          if (_showComboBonus)
            Center(
              child: FadeTransition(
                opacity: _comboOpacity,
                child: ScaleTransition(
                  scale: _comboScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.cyanAccent,
                        size: 100,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_comboCount COMBO!',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bonus +$_comboCount Diamonds!',
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

  String _currentFocus = 'N';
  String _numInput = '';
  String _denInput = '';

  void _onNumberPressed(int n) {
    if (_isAnswered) return;
    setState(() {
      _isNotSimplified = false;
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
      _isNotSimplified = false;
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
              Row(
                children: [
                  Text(
                    'Level ${widget.difficulty}',
                    style: TextStyle(
                      color: config.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Combo: $_comboCount',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            'Score: ${context.watch<UserProvider>().totalScore}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '💎 ${context.watch<UserProvider>().diamonds}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareView(ThemeConfig config) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 30,
          runSpacing: 30,
          children: _problemFractions.asMap().entries.map((entry) {
            int order = _selectedIndices.indexOf(entry.key);
            return _buildFractionCard(
              entry.value.num,
              entry.value.den,
              config.vibrantColors[entry.key % config.vibrantColors.length],
              onTap: () => _checkCompare(entry.key),
              showShape: false,
              isSelected: _selectedIndices.contains(entry.key),
              selectedIndex: order >= 0 ? order + 1 : 0,
            );
          }).toList(),
        ),
        if (!_isAnswered && _selectedIndices.isNotEmpty) ...[
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedIndices.clear();
              });
            },
            icon: const Icon(Icons.undo_rounded, color: Colors.orangeAccent),
            label: const Text(
              'Reset Selection',
              style: TextStyle(color: Colors.orangeAccent),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        const Text(
          'Select fractions from LARGEST to SMALLEST!',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildArithmeticView(ThemeConfig config) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 20,
          children: [
            for (int i = 0; i < _problemFractions.length; i++) ...[
              _buildFractionCard(
                _problemFractions[i].num,
                _problemFractions[i].den,
                config.vibrantColors[i % config.vibrantColors.length],
              ),
              if (i < _problemFractions.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: config.textColor,
                    ),
                  ),
                ),
            ],
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
            const Text(
              'CHECK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomKeyboard(ThemeConfig config) {
    return Column(
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
                    _ansN = 1;
                  } else {
                    _denInput = '';
                    _ansD = 1;
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
    bool showShape = true,
    bool isSelected = false,
    int selectedIndex = 0,
  }) {
    return InkWell(
      onTap: _isAnswered || isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isSelected ? 0.6 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                if (showShape)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: CustomPaint(
                      painter: PizzaPainter(num: num, den: den, color: color),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.2),
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$num',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 28,
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
                ),
              ],
            ),
            if (selectedIndex > 0)
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$selectedIndex',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplifiedHint() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: const Text(
        'Value is correct! Please SIMPLIFY the fraction.',
        style: TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeedback(ThemeConfig config) {
    String feedbackText = _isCorrect ? 'Correct!' : 'Incorrect!';
    Color feedbackColor = _isCorrect ? Colors.green : Colors.red;

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
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
