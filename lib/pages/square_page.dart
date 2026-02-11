import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:vibration/vibration.dart';

class SquarePage extends StatefulWidget {
  final int difficulty;
  const SquarePage({super.key, required this.difficulty});

  @override
  State<SquarePage> createState() => _SquarePageState();
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

class _SquarePageState extends State<SquarePage> with TickerProviderStateMixin {
  int _currentNumber = 1;
  int _score = 0;
  String _userInput = '';
  bool _answered = false;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _comboCount = 0;

  // Stopwatch logic
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = '0.0';

  // Animation logic
  late AnimationController _particleController;
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;

  final List<Particle> _particles = [];
  final GlobalKey _problemDisplayKey = GlobalKey();
  final math.Random _random = math.Random();
  late UserProvider _userProvider;

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
    _generateNextQuestion();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _elapsedTime = (_stopwatch.elapsedMilliseconds / 1000.0)
              .toStringAsFixed(1);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _comboController.dispose();
    _timer.cancel();
    // Record session total to history
    _userProvider.addHistoryEntry(_sessionScoreChange, 'Square Quiz Session');
    super.dispose();
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
    });
  }

  void _generateNextQuestion() {
    setState(() {
      int next;
      if (widget.difficulty == 1) {
        // Level 1: 11 to 31
        next = _random.nextInt(21) + 11;
      } else {
        // Level 2: 32 to 99
        next = _random.nextInt(68) + 32;
      }

      _currentNumber = next;
      _userInput = '';
      _answered = false;
      _stopwatch.reset();
      _stopwatch.start();
    });
  }

  void _onKeyPress(String key) {
    if (_answered) return;
    setState(() {
      if (key == 'CLR') {
        _userInput = '';
      } else if (key == 'DEL') {
        if (_userInput.isNotEmpty) {
          _userInput = _userInput.substring(0, _userInput.length - 1);
        }
      } else if (key == 'SUB') {
        _checkAnswer();
      } else {
        if (_userInput.length < 5) {
          _userInput += key;
        }
      }
    });
  }

  void _checkAnswer() {
    if (_userInput.isEmpty) return;

    _stopwatch.stop();
    int? userVal = int.tryParse(_userInput);
    int correctResult = _currentNumber * _currentNumber;

    setState(() {
      _answered = true;
      if (userVal == correctResult) {
        final gain = widget.difficulty == 1 ? 3 : 8;
        _score += gain;
        _sessionScoreChange += gain;
        _comboCount++;

        int comboBonus = _comboCount;
        _score += comboBonus;
        _sessionScoreChange += comboBonus;

        context.read<UserProvider>().addScore(gain);
        if (comboBonus > 0) {
          context.read<UserProvider>().addScore(
            comboBonus,
            gameName: 'Square Combo',
          );
        }

        _startExplosion();
        _triggerComboAnimation();

        final user = context.read<UserProvider>();
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
            title: 'LEGENDARY COMBO!',
            message:
                'You reached 20 combos! Absolutely amazing!\nTotal Score: $_score',
            isSuccess: true,
            onConfirm: () => Navigator.pop(context),
          );
        } else {
          MathDialog.show(
            context,
            title: _comboCount > 1 ? '$_comboCount COMBO!' : 'WELL DONE!',
            message:
                '$_currentNumber² is indeed $correctResult.\nTime: $_elapsedTime seconds.',
            isSuccess: true,
            onConfirm: _generateNextQuestion,
          );
        }
      } else {
        final loss = widget.difficulty == 1 ? 2 : 4;
        _score -= loss;
        _sessionScoreChange -= loss;
        context.read<UserProvider>().addScore(-loss);
        MathDialog.show(
          context,
          title: 'NOT QUITE',
          message:
              '$_currentNumber² = $correctResult.\nFocus and try the next one!',
          isSuccess: false,
          onConfirm: _generateNextQuestion,
        );
      }
    });
  }

  void _startExplosion() {
    final RenderBox? box =
        _problemDisplayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position =
        box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()) +
        Offset(box.size.width / 2, box.size.height / 2);

    final List<Color> colors = [
      AppColors.primary,
      AppColors.accent,
      Colors.yellowAccent,
      Colors.cyanAccent,
      Colors.white,
    ];

    for (int i = 0; i < 30; i++) {
      double angle = _random.nextDouble() * 2 * math.pi;
      double speed = _random.nextDouble() * 5 + 2;
      _particles.add(
        Particle(
          position: position,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          color: colors[_random.nextInt(colors.length)],
          size: _random.nextDouble() * 4 + 2,
          life: 1.0,
        ),
      );
    }
    _particleController.forward(from: 0);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Square Quiz (Level ${widget.difficulty})'),
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
                        color: color,
                      ),
                    ),
                    if (_comboCount > 0)
                      Text(
                        '$_comboCount COMBO',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.cyanAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Timer Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_elapsedTime s',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Problem Display
                        Container(
                          key: _problemDisplayKey,
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardTheme.color?.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_currentNumber²',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                '=',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                _userInput.isEmpty ? '?' : _userInput,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: _userInput.isEmpty
                                      ? color.withOpacity(0.3)
                                      : color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_answered) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _generateNextQuestion,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Next Question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildKeypad(context),
                const SizedBox(height: 20),
              ],
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

  Widget _buildKeypad(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildKeyRow(context, ['1', '2', '3']),
          const SizedBox(height: 8),
          _buildKeyRow(context, ['4', '5', '6']),
          const SizedBox(height: 8),
          _buildKeyRow(context, ['7', '8', '9']),
          const SizedBox(height: 8),
          _buildKeyRow(context, ['CLR', '0', 'DEL']),
          const SizedBox(height: 8),
          _buildSubmitButton(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ElevatedButton(
                  onPressed: () => _onKeyPress(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).cardTheme.color?.withOpacity(0.7),
                    foregroundColor: (key == 'CLR' || key == 'DEL')
                        ? Colors.orangeAccent
                        : Theme.of(context).textTheme.titleLarge?.color,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 18,
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

  Widget _buildSubmitButton(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: _answered ? null : _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'SUBMIT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
