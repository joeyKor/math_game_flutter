import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';

class PhysicsMathPage extends StatefulWidget {
  const PhysicsMathPage({super.key});

  @override
  State<PhysicsMathPage> createState() => _PhysicsMathPageState();
}

class _PhysicsMathPageState extends State<PhysicsMathPage>
    with TickerProviderStateMixin {
  late String _problemText;
  late String _hintFormula;
  late double _correctAnswer;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _score = 0;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _comboCount = 0;
  bool _isAnswerChecked = false;
  bool _isHintUsed = false;
  bool _showHintText = false;

  // Particle & Combo animations
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
      'Physics Math Session',
    );
    super.dispose();
  }

  void _generateProblem() {
    _isAnswerChecked = false;
    _isHintUsed = false;
    _showHintText = false;
    _answerController.clear();

    final r = math.Random();
    int type = r.nextInt(7); // Increased to include new types (0 to 6)

    double val1, val2;

    switch (type) {
      case 0: // Speed: v = d / t
        val1 = (r.nextInt(10) + 1) * 10.0; // Distance
        val2 = (r.nextInt(4) + 1).toDouble(); // Time
        _correctAnswer = val1 / val2;
        _problemText =
            "A car travels $val1 km in $val2 hours. What is its average speed (km/h)?";
        _hintFormula = "Speed (v) = Distance (d) / Time (t)";
        break;
      case 1: // Gravity (Free Fall): h = 0.5 * g * t^2
        val2 = (r.nextInt(5) + 1).toDouble(); // Time (t) in seconds (1 to 5)
        _correctAnswer = 0.5 * 9.8 * val2 * val2; // h = 0.5 * 9.8 * t^2
        _problemText =
            "An object is dropped from a building and hits the ground in $val2 seconds. How high is the building (m)? (g=9.8m/s²)";
        _hintFormula = "Height (h) = 0.5 × g × t²";
        break;
      case 2: // Newton's Law: F = m * a
        val1 = (r.nextInt(15) + 5).toDouble(); // Mass (m)
        val2 = (r.nextInt(10) + 2).toDouble(); // Accel (a)
        _correctAnswer = val1 * val2;
        _problemText =
            "A force is applied to a ${val1}kg object, giving it an acceleration of ${val2}m/s². What is the force (N)?";
        _hintFormula = "Force (F) = mass (m) × acceleration (a)";
        break;
      case 3: // Work: W = F * d
        val1 = (r.nextInt(50) + 10).toDouble(); // Force (F)
        val2 = (r.nextInt(20) + 5).toDouble(); // Distance (d)
        _correctAnswer = val1 * val2;
        _problemText =
            "A constant force of ${val1}N acts on an object, moving it ${val2}m in the direction of the force. How much work is done (J)?";
        _hintFormula = "Work (W) = Force (F) × Distance (d)";
        break;
      case 4: // Density: rho = m / V
        val1 = (r.nextInt(100) + 20).toDouble(); // Mass (m)
        val2 = (r.nextInt(10) + 2).toDouble(); // Volume (V)
        _correctAnswer = val1 / val2;
        _problemText =
            "A substance has a mass of ${val1}g and a volume of ${val2}cm³. What is its density (g/cm³)?";
        _hintFormula = "Density (ρ) = mass (m) / Volume (V)";
        break;
      case 5: // Pressure: P = F / A
        val1 = (r.nextInt(200) + 50).toDouble(); // Force (F)
        val2 = (r.nextInt(5) + 1).toDouble(); // Area (A)
        _correctAnswer = val1 / val2;
        _problemText =
            "A force of ${val1}N is applied uniformly over an area of ${val2}m². Calculate the pressure (Pa).";
        _hintFormula = "Pressure (P) = Force (F) / Area (A)";
        break;
      case 6: // Ohm's Law: V = I * R
      default:
        val1 = (r.nextInt(10) + 1).toDouble(); // Current (I)
        val2 = (r.nextInt(20) + 5).toDouble(); // Resistance (R)
        _correctAnswer = val1 * val2;
        _problemText =
            "A current of ${val1}A flows through a resistor with a resistance of $val2Ω. What is the voltage (V)?";
        _hintFormula = "Voltage (V) = Current (I) × Resistance (R)";
        break;
    }

    _correctAnswer = double.parse(_correctAnswer.toStringAsFixed(1));
    if (_correctAnswer == _correctAnswer.toInt()) {
      _correctAnswer = _correctAnswer.toInt().toDouble();
    }

    setState(() {});
    _focusNode.requestFocus();
  }

  void _useHint() {
    if (_isAnswerChecked || _isHintUsed) return;
    setState(() {
      _isHintUsed = true;
      _showHintText = true;
      _comboCount = 0; // Combo stops immediately
    });
  }

  void _checkAnswer() {
    if (_isAnswerChecked) return;

    double? userAnswer = double.tryParse(_answerController.text);
    if (userAnswer == null) return;

    setState(() => _isAnswerChecked = true);

    final user = context.read<UserProvider>();
    bool isCorrect = (userAnswer - _correctAnswer).abs() < 0.1;

    if (isCorrect) {
      // If hint used: 10 points and combo reset. Else: 30 points and combo ++
      int gain = _isHintUsed ? 10 : 30;

      _score += gain;
      _sessionScoreChange += gain;

      if (_isHintUsed) {
        _comboCount = 0;
      } else {
        _comboCount++;
      }

      user.addScore(gain);
      if (!_isHintUsed) {
        user.addDiamonds(_comboCount);
      }

      _startExplosion();
      if (!_isHintUsed) _triggerComboAnimation();

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
      title: 'PHYSICS MASTER!',
      message:
          'LEGENDARY 20 COMBO!\nYour physics intuition is flawless!\nTotal Score: $_score',
      isSuccess: true,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showFailureDialog() {
    MathDialog.show(
      context,
      title: 'INCORRECT!',
      message: 'The correct answer was $_correctAnswer.\nKeep practicing!',
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
            Colors.orangeAccent,
            Colors.yellowAccent,
            Colors.cyanAccent,
            Colors.white,
          ][_random.nextInt(4)],
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
        title: const Text('Physics Math'),
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
                  const SizedBox(height: 40),
                  Card(
                    key: _cardKey,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.speed_rounded,
                            color: Colors.orangeAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _problemText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_showHintText) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                "Formula: $_hintFormula",
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _answerController,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Enter answer',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.orangeAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (_isAnswerChecked || _isHintUsed)
                            ? null
                            : _useHint,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('HINT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'SUBMIT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isHintUsed)
                    const Text(
                      'Hint used: Reward reduced to 10 pts & Combo reset',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
                        color: Colors.orangeAccent,
                        size: 100,
                      ),
                      Text(
                        '$_comboCount COMBO!',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
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
