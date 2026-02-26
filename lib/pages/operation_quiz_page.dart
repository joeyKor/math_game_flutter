import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';

class OperationQuizPage extends StatefulWidget {
  final int level;
  const OperationQuizPage({super.key, required this.level});

  @override
  State<OperationQuizPage> createState() => _OperationQuizPageState();
}

class Rule {
  final String description;
  final int Function(int a, int b) formula;
  Rule(this.description, this.formula);
}

class _OperationQuizPageState extends State<OperationQuizPage>
    with TickerProviderStateMixin {
  late List<String> _clues;
  late String _question;
  late int _correctAnswer;
  late String _symbol;
  late Rule _currentRule;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _score = 0;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _comboCount = 0;
  bool _isAnswerChecked = false;
  bool _isHintPurchased = false;

  // Animation variables
  late AnimationController _particleController;
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  final GlobalKey _cardKey = GlobalKey();

  final List<String> _symbols = ['△', '☆', '◈', '✦', '✪', '❂', '❖'];

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
      'Symbol Logic Session',
    );
    super.dispose();
  }

  void _generateProblem() {
    _isAnswerChecked = false;
    _isHintPurchased = false;
    _answerController.clear();
    _clues = [];

    final r = math.Random();
    _symbol = _symbols[r.nextInt(_symbols.length)];

    // Define potential rules with varying complexity
    List<Rule> rules = [
      Rule('A * B + 1', (a, b) => (a * b) + 1),
      Rule('A * B - 2', (a, b) => (a * b) - 2),
      Rule(
        '(A + B) * 2',
        (a, b) => (a * b) + (a + b),
      ), // Reuse existing but distinct
      Rule('A * 2 + B', (a, b) => (a * 2) + b),
      Rule('A + B * 2', (a, b) => a + (b * 2)),
      Rule('A * A - 5', (a, b) => (a * a) - 5),
    ];

    if (widget.level >= 2) {
      rules.addAll([
        Rule('A * B - (A + B)', (a, b) => (a * b) - (a + b)),
        Rule('(A + 1) * (B - 1)', (a, b) => (a + 1) * (b - 1)),
        Rule('(A + B) * (A - b)', (a, b) => (a + b) * (a - b)),
        Rule('2*A + 3*B', (a, b) => (2 * a) + (3 * b)),
        Rule('A * A + B * B', (a, b) => (a * a) + (b * b)),
        Rule('A * (B + A)', (a, b) => a * (b + a)),
      ]);
    }

    if (widget.level >= 3) {
      rules.addAll([
        // Division-based rules (ensuring integer results in formula check)
        Rule('(A * B) / 2 + 5', (a, b) => ((a * b) ~/ 2) + 5),
        Rule('(A + B) % 7 + A', (a, b) => ((a + b) % 7) + a),
        Rule('A * B - (A * A)', (a, b) => (a * b) - (a * a)),
        Rule('(A * A * A) - (B * B)', (a, b) => (a * a * a) - (b * b)),
        Rule('B * B * B + A', (a, b) => (b * b * b) + a),
        Rule('(A + B) * (A + B) - 10', (a, b) => (a + b) * (a + b) - 10),
        Rule('(A * B) % 10 + 20', (a, b) => (a * b) % 10 + 20),
        Rule('(A * A) / B + A', (a, b) => (a * a ~/ b) + a),
        Rule('(A + B) * 3 - (A * B) / 2', (a, b) => (a + b) * 3 - (a * b ~/ 2)),
      ]);
    }

    _currentRule = rules[r.nextInt(rules.length)];

    // Generate clues
    Set<String> used = {};
    int operandRange = (widget.level == 3) ? 15 : 8;
    int operandStart = (widget.level == 3) ? 3 : 2;

    while (_clues.length < 3) {
      int a = r.nextInt(operandRange) + operandStart;
      int b = r.nextInt(operandRange) + operandStart;

      // Level 3 specific constraints for division/modulo to make sense
      if (widget.level == 3) {
        if (_currentRule.description.contains('/') && (a * b) % 2 != 0)
          continue;
        if (_currentRule.description.contains('/ B') && a * a % b != 0)
          continue;
      }

      String key = '$a,$b';
      if (used.contains(key)) continue;

      int result = _currentRule.formula(a, b);
      if (result < -100 || result > 2000) continue;

      _clues.add('$a $_symbol $b = $result');
      used.add(key);
    }

    // Generate question
    int qa, qb;
    while (true) {
      qa = r.nextInt(operandRange + 5) + operandStart;
      qb = r.nextInt(operandRange + 5) + operandStart;

      if (widget.level == 3) {
        if (_currentRule.description.contains('/') && (qa * qb) % 2 != 0)
          continue;
        if (_currentRule.description.contains('/ B') && qa * qa % qb != 0)
          continue;
      }

      String key = '$qa,$qb';
      if (used.contains(key)) continue;

      _correctAnswer = _currentRule.formula(qa, qb);
      if (_correctAnswer < -100 || _correctAnswer > 3000) continue;

      _question = '$qa $_symbol $qb = ?';
      break;
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
      int gain = widget.level * 10;
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

  void _buyHint() {
    if (_isHintPurchased) return;

    final user = context.read<UserProvider>();
    int cost = 50; // Unified cost for all levels

    if (user.totalScore < cost) {
      MathDialog.show(
        context,
        title: 'NOT ENOUGH POINTS!',
        message: 'Hint costs $cost score points. You have ${user.totalScore}.',
        isSuccess: false,
      );
      return;
    }

    MathDialog.show(
      context,
      title: 'BUY HINT?',
      message: 'Revealing the rule costs $cost points and resets your combo.',
      isSuccess: true,
      onConfirm: () {
        user.addScore(-cost);
        _sessionScoreChange -= cost;
        setState(() {
          _isHintPurchased = true;
          _comboCount = 0; // Penalty: Reset combo
        });
      },
    );
  }

  void _showSuccessDialog() {
    MathDialog.show(
      context,
      title: 'SYMBOL MASTER!',
      message:
          'LEGENDARY 20 COMBO!\nYou decoded the Level ${widget.level} logic perfectly!\nTotal Score: $_score',
      isSuccess: true,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showFailureDialog() {
    MathDialog.show(
      context,
      title: 'INCORRECT!',
      message:
          'The logic was: ${_currentRule.description}.\nThe correct answer was $_correctAnswer.',
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
            Colors.deepPurpleAccent,
            Colors.amberAccent,
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
        title: const Text('Symbol Logic'),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          'LV ${widget.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _buyHint,
                        icon: const Icon(
                          Icons.lightbulb,
                          color: Colors.amberAccent,
                        ),
                        tooltip: 'Buy Hint',
                      ),
                    ],
                  ),
                  if (_isHintPurchased)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Rule: ${_currentRule.description.replaceAll('*', '×')}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    key: _cardKey,
                    elevation: 12,
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
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.psychology_outlined,
                            color: Colors.amberAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Deduce the Rule:",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Clues section
                          ..._clues.map(
                            (clue) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                clue,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const Divider(
                            height: 32,
                            color: Colors.white24,
                            indent: 40,
                            endIndent: 40,
                          ),
                          Text(
                            _question,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
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
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.amberAccent,
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
                      backgroundColor: Colors.amberAccent.withOpacity(0.8),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'DECODE',
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
                        Icons.auto_awesome,
                        color: Colors.amberAccent,
                        size: 100,
                      ),
                      Text(
                        '$_comboCount COMBO!',
                        style: const TextStyle(
                          color: Colors.amberAccent,
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
