import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';

class MissingSignPage extends StatefulWidget {
  final int difficulty;
  const MissingSignPage({super.key, required this.difficulty});

  @override
  State<MissingSignPage> createState() => _MissingSignPageState();
}

class _MissingSignPageState extends State<MissingSignPage>
    with TickerProviderStateMixin {
  late math.Random _random;
  late List<int> _numbers;
  late List<String> _correctOperators;
  late List<String?> _userOperators;
  late int _result;
  int _score = 0;
  int _correctCount = 0;
  int _comboCount = 0;
  final int _totalQuestions = 10;
  bool _isGameOver = false;
  late ConfettiController _confettiController;
  int _selectedIndex = 0;
  late int _timeLeft;
  Timer? _timer;

  // Animation logic
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;

  int get _maxTime {
    if (widget.difficulty == 1) return 25;
    if (widget.difficulty == 2) return 35;
    return 45;
  }

  final List<String> _allOperators = ['+', '-', '×', '÷'];

  @override
  void initState() {
    super.initState();
    _random = math.Random();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
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

    _generateQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _comboController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _maxTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_isGameOver) return;
    _isGameOver = true;

    String correctEquation = '';
    for (int i = 0; i < _numbers.length; i++) {
      correctEquation += '${_numbers[i]}';
      if (i < _correctOperators.length) {
        correctEquation += ' ${_correctOperators[i]} ';
      }
    }
    correctEquation += ' = $_result';

    MathDialog.show(
      context,
      title: 'TIME UP!',
      message: 'You ran out of time!\nCorrect answer was:\n$correctEquation',
      isSuccess: false,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
    });
  }

  void _generateQuestion() {
    bool valid = false;
    int attempts = 0;
    while (!valid && attempts < 500) {
      attempts++;
      int count;
      if (widget.difficulty == 1) {
        count = 3;
      } else {
        count = 4;
      }
      _numbers = List.generate(count, (_) => _random.nextInt(15) + 1);
      _correctOperators = [];
      _userOperators = List.generate(count - 1, (_) => null);
      _selectedIndex = 0;

      double currentVal = _numbers[0].toDouble();
      for (int i = 0; i < count - 1; i++) {
        String op;
        if (widget.difficulty == 1 || widget.difficulty == 2) {
          op = _random.nextBool() ? '+' : '-';
        } else {
          op = _allOperators[_random.nextInt(_allOperators.length)];
        }

        if (op == '÷') {
          // Ensure divisible for cleaner play
          int nextNum = _numbers[i + 1];
          if (currentVal.toInt() % nextNum != 0) {
            // Regeneration needed or adjust number
            _numbers[i + 1] = _findDivisor(currentVal.toInt());
          }
        }

        _correctOperators.add(op);
        currentVal = _applyOp(currentVal, _numbers[i + 1].toDouble(), op);
      }

      if (currentVal >= 0 &&
          currentVal == currentVal.roundToDouble() &&
          currentVal < 100) {
        _result = currentVal.toInt();
        valid = true;
      }
    }
    setState(() {});
    _startTimer();
  }

  int _findDivisor(int val) {
    List<int> divisors = [];
    for (int i = 1; i <= val; i++) {
      if (val % i == 0 && i < 20) divisors.add(i);
    }
    return divisors.isEmpty ? 1 : divisors[_random.nextInt(divisors.length)];
  }

  double _applyOp(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return a / b;
      default:
        return a;
    }
  }

  void _handleOperatorInput(String op) {
    if (_isGameOver) return;
    setState(() {
      _userOperators[_selectedIndex] = op;
      if (_selectedIndex < _userOperators.length - 1) {
        _selectedIndex++;
      }
    });

    if (_userOperators.every((o) => o != null)) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    double currentVal = _numbers[0].toDouble();
    for (int i = 0; i < _userOperators.length; i++) {
      currentVal = _applyOp(
        currentVal,
        _numbers[i + 1].toDouble(),
        _userOperators[i]!,
      );
    }

    if (currentVal.toInt() == _result) {
      _confettiController.play();
      if (context.read<UserProvider>().isVibrationEnabled) {
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
      _handleSuccess();
    } else {
      _handleFailure();
    }
  }

  void _handleSuccess() {
    final gain = 3 * widget.difficulty;
    _correctCount++;
    _comboCount++;
    int comboBonus = _comboCount;
    _score += (gain + comboBonus);

    final user = context.read<UserProvider>();
    user.addScore(gain);
    user.addDiamonds(comboBonus);

    _triggerComboAnimation();

    if (_comboCount >= 20) {
      _timer?.cancel();
      _confettiController.play();
      _isGameOver = true;
      MathDialog.show(
        context,
        title: 'SIGN MASTER!',
        message:
            'LEGENDARY 20 COMBO REACHED!\nYou decoded the signs perfectly!\nTotal Score: $_score',
        isSuccess: true,
        onConfirm: () => Navigator.pop(context),
      );
      return;
    }

    if (_correctCount >= _totalQuestions) {
      _isGameOver = true;
      MathDialog.show(
        context,
        title: 'MISSION COMPLETE!',
        message: 'You are the Sign Master! Total Score: $_score',
        isSuccess: true,
        onConfirm: () => Navigator.pop(context),
      );
    } else {
      Future.delayed(const Duration(milliseconds: 500), _generateQuestion);
    }
  }

  void _handleFailure() {
    final loss = 1 * widget.difficulty;
    _score -= loss;
    _comboCount = 0;
    context.read<UserProvider>().addScore(
      -loss,
      gameName: 'Missing Sign (Failed)',
    );

    String correctEquation = '';
    for (int i = 0; i < _numbers.length; i++) {
      correctEquation += '${_numbers[i]}';
      if (i < _correctOperators.length) {
        correctEquation += ' ${_correctOperators[i]} ';
      }
    }
    correctEquation += ' = $_result';

    MathDialog.show(
      context,
      title: 'GAME OVER!',
      message:
          'The logic didn\'t match.\nCorrect answer was:\n$correctEquation',
      isSuccess: false,
      onConfirm: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Missing Sign'),
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
          SafeArea(
            child: Column(
              children: [
                _buildProgressHeader(config.vibrantColors[0]),
                _buildTimerBar(config.vibrantColors[0]),
                const Spacer(),
                _buildEquationDisplay(),
                const Spacer(),
                _buildOperatorPad(config.vibrantColors[0]),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: config.vibrantColors,
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

  Widget _buildProgressHeader(Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${widget.difficulty}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Score: $_score',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              Consumer<UserProvider>(
                builder: (context, user, child) => Text(
                  '💎 ${user.diamonds}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _correctCount / _totalQuestions,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.white70),
              Text(
                '$_timeLeft s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _timeLeft / _maxTime,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                _timeLeft < 5 ? Colors.red : color,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquationDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 20,
        children: [
          for (int i = 0; i < _numbers.length; i++) ...[
            Text(
              '${_numbers[i]}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            if (i < _numbers.length - 1) _buildSignPlaceholder(i),
          ],
          const Text(
            '=',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          Text(
            '$_result',
            style: TextStyle(
              fontSize: 42,
              color: Colors.orange.shade300,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignPlaceholder(int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white24,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _userOperators[index] ?? '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _userOperators[index] == null
                ? Colors.white30
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorPad(Color color) {
    List<String> ops = widget.difficulty == 1 ? ['+', '-'] : _allOperators;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ops.map((op) => _buildOpButton(op, color)).toList(),
      ),
    );
  }

  Widget _buildOpButton(String op, Color color) {
    return InkWell(
      onTap: () => _handleOperatorInput(op),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          op,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
