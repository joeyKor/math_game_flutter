import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';

class SystemEquationsPage extends StatefulWidget {
  const SystemEquationsPage({super.key});

  @override
  State<SystemEquationsPage> createState() => _SystemEquationsPageState();
}

class _SystemEquationsPageState extends State<SystemEquationsPage>
    with TickerProviderStateMixin {
  late String _problemText;
  late int _correctAnswer;
  late String _targetVar;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _score = 0;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _comboCount = 0;
  bool _isAnswerChecked = false;
  int _currentLevel = 1; // Level 1, 2, or 3

  // Animation variables
  late AnimationController _particleController;
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            setState(() {
              for (var p in _particles) p.update();
              _particles.removeWhere((p) => p.life <= 0);
            });
          });

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
    _answerController.dispose();
    _focusNode.dispose();
    _particleController.dispose();
    _comboController.dispose();
    context.read<UserProvider>().addHistoryEntry(
      _sessionScoreChange,
      'Equation Master Session',
    );
    super.dispose();
  }

  void _generateProblem() {
    _isAnswerChecked = false;
    _answerController.clear();

    final r = math.Random();

    if (_currentLevel == 1) {
      // Level 1: 2 Variables (x, y)
      // x + y = A, x - y = B
      int x = r.nextInt(20) + 5; // 5 to 25
      int y = r.nextInt(x - 2) + 1; // Ensure y < x

      int sum = x + y;
      int diff = x - y;

      if (r.nextBool()) {
        _targetVar = 'x';
        _correctAnswer = x;
      } else {
        _targetVar = 'y';
        _correctAnswer = y;
      }
      _problemText =
          "Given:\nx + y = $sum\nx - y = $diff\n\nFind the value of $_targetVar.";
    } else if (_currentLevel == 2) {
      // Level 2: 3 Variables (Standard, Larger Numbers)
      int x = r.nextInt(51) + 20; // 20 to 70
      int y = r.nextInt(51) + 20;
      int z = r.nextInt(51) + 20;

      int ab = x + y;
      int bc = y + z;
      int ca = z + x;

      int targetIdx = r.nextInt(3);
      if (targetIdx == 0) {
        _targetVar = 'x';
        _correctAnswer = x;
      } else if (targetIdx == 1) {
        _targetVar = 'y';
        _correctAnswer = y;
      } else {
        _targetVar = 'z';
        _correctAnswer = z;
      }
      _problemText =
          "Given:\nx + y = $ab\ny + z = $bc\nz + x = $ca\n\nFind the value of $_targetVar.";
    } else {
      // Level 3: Complex Systems (Mixed operators/multipliers)
      int x = r.nextInt(15) + 5;
      int y = r.nextInt(15) + 5;
      int z = r.nextInt(15) + 5;

      // Type 1: 2x + y = A, y + z = B, x - z = C
      // Type 2: x + y + z = A, x - y = B, y - z = C
      int type = r.nextInt(2);
      if (type == 0) {
        int eq1 = (2 * x) + y;
        int eq2 = y + z;
        int eq3 = x - z;
        _problemText = "Given:\n2x + y = $eq1\ny + z = $eq2\nx - z = $eq3";
      } else {
        int eq1 = x + y + z;
        int eq2 = x - y;
        int eq3 = y - z;
        _problemText = "Given:\nx + y + z = $eq1\nx - y = $eq2\ny - z = $eq3";
      }

      int targetIdx = r.nextInt(3);
      if (targetIdx == 0) {
        _targetVar = 'x';
        _correctAnswer = x;
      } else if (targetIdx == 1) {
        _targetVar = 'y';
        _correctAnswer = y;
      } else {
        _targetVar = 'z';
        _correctAnswer = z;
      }
      _problemText += "\n\nFind the value of $_targetVar.";
    }

    setState(() {});
    _focusNode.requestFocus();
  }

  void _checkAnswer() {
    if (_isAnswerChecked) return;

    int? userAnswer = int.tryParse(_answerController.text);
    if (userAnswer == null) return;

    setState(() => _isAnswerChecked = true);

    final user = context.read<UserProvider>();
    bool isCorrect = userAnswer == _correctAnswer;

    if (isCorrect) {
      int gain = _currentLevel * 10;
      _score += gain;
      _sessionScoreChange += gain;
      _comboCount++;

      user.addScore(gain);
      user.addDiamonds(_comboCount);

      _startExplosion();
      _triggerComboAnimation();

      if (user.isTtsEnabled) {
        TtsService().speak(CommentaryService.getHitPhrase(user.username));
      }

      if (_comboCount >= 20) {
        _showSuccessDialog();
      } else {
        Future.delayed(const Duration(seconds: 1), _generateProblem);
      }
    } else {
      const loss = 5;
      _score -= loss;
      _sessionScoreChange -= loss;
      _comboCount = 0;
      user.addScore(-loss);

      if (user.isTtsEnabled) {
        TtsService().speak(CommentaryService.getMissPhrase(user.username));
      }

      _showFailureDialog();
    }
  }

  void _showSuccessDialog() {
    MathDialog.show(
      context,
      title: 'EQUATION MASTER!',
      message:
          'LEGENDARY 20 COMBO!\nYou solved the Level $_currentLevel system perfectly!\nTotal Score: $_score',
      isSuccess: true,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showFailureDialog() {
    MathDialog.show(
      context,
      title: 'INCORRECT!',
      message:
          'The correct answer for $_targetVar was $_correctAnswer.\nKeep trying!',
      isSuccess: false,
      onConfirm: _generateProblem,
    );
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
    });
  }

  void _startExplosion() {
    final RenderBox? box =
        _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position =
        box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()) +
        Offset(box.size.width / 2, box.size.height / 2);

    for (int i = 0; i < 30; i++) {
      double angle = _random.nextDouble() * 2 * math.pi;
      double speed = _random.nextDouble() * 5 + 2;
      _particles.add(
        Particle(
          position: position,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          color: [
            Colors.purpleAccent,
            Colors.cyanAccent,
            Colors.white,
          ][_random.nextInt(3)],
          size: _random.nextDouble() * 4 + 2,
          life: 1.0,
        ),
      );
    }
    _particleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Equation Master'),
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
                  fontSize: 16,
                ),
              ),
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Level Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [1, 2, 3].map((lvl) {
                        bool isSelected = _currentLevel == lvl;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentLevel = lvl;
                              _comboCount =
                                  0; // Reset combo when switching level
                              _generateProblem();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.cyanAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'LV $lvl',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    key: _cardKey,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _currentLevel == 3
                              ? Colors.purpleAccent.withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _currentLevel == 3
                                ? Icons.psychology
                                : Icons.calculate,
                            color: _currentLevel == 3
                                ? Colors.purpleAccent
                                : Colors.cyanAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _problemText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _answerController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '?',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _currentLevel == 3
                              ? Colors.purpleAccent
                              : Colors.cyanAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_currentLevel == 3
                                  ? Colors.purpleAccent
                                  : Colors.cyanAccent)
                              .withOpacity(0.7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'SOLVE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: ParticlePainter(_particles),
              child: Container(),
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
                        Icons.bolt_rounded,
                        color: Colors.cyanAccent,
                        size: 100,
                      ),
                      Text(
                        '$_comboCount COMBO!',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(4, 4),
                            ),
                          ],
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
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  });

  void update() {
    position += velocity;
    life -= 0.02;
    size *= 0.95;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var particle in particles) {
      if (particle.life > 0) {
        paint.color = particle.color.withOpacity(particle.life.clamp(0.0, 1.0));
        canvas.drawCircle(particle.position, particle.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
