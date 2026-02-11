import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:vibration/vibration.dart';

enum FlashDisplayState { empty, num1, num2, input }

class FlashPage extends StatefulWidget {
  final int difficulty;
  const FlashPage({super.key, required this.difficulty});

  @override
  State<FlashPage> createState() => _FlashPageState();
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

class _FlashPageState extends State<FlashPage> with TickerProviderStateMixin {
  List<int> _nums = [];
  int _currentDisplayIndex = -1; // -1 for empty/other
  String _userInput = '';
  int _score = 0;
  int _correctCount = 0;
  final int _totalQuestions = 10;
  bool _isChallengeComplete = false;
  FlashDisplayState _displayState = FlashDisplayState.empty;
  bool _isSequenceRunning = false;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _comboCount = 0;

  int get _numsCount =>
      widget.difficulty == 3 ? 4 : (widget.difficulty == 2 ? 3 : 2);
  int get _scoreMultiplier => widget.difficulty;

  // Stopwatch logic
  final Stopwatch _totalStopwatch = Stopwatch();
  Timer? _timer;
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

    _startChallenge();
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
    _timer?.cancel();
    // Record session total to history
    _userProvider.addHistoryEntry(_sessionScoreChange, 'Flash Mental Session');
    super.dispose();
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
    });
  }

  void _startChallenge() {
    setState(() {
      _score = 0;
      _correctCount = 0;
      _comboCount = 0;
      _userInput = '';
      _isChallengeComplete = false;
      _totalStopwatch.reset();
      _totalStopwatch.start();
      _generateNextQuestion();
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_totalStopwatch.isRunning) {
        setState(() {
          _elapsedTime = (_totalStopwatch.elapsedMilliseconds / 1000.0)
              .toStringAsFixed(1);
        });
      }
    });
  }

  void _generateNextQuestion() {
    final random = math.Random();
    _nums = List.generate(_numsCount, (_) => random.nextInt(900) + 100);
    _userInput = '';
    _startSequence();
  }

  Future<void> _startSequence() async {
    if (!mounted) return;
    setState(() {
      _isSequenceRunning = true;
      _displayState = FlashDisplayState.empty;
      _currentDisplayIndex = -1;
    });

    for (int i = 0; i < _nums.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _currentDisplayIndex = i;
      });
      // Level 1: 2 seconds, Others: 3 seconds
      final duration = widget.difficulty == 1 ? 2 : 3;
      await Future.delayed(Duration(seconds: duration));
      if (!mounted) return;
      setState(() {
        _currentDisplayIndex = -1;
      });
    }

    if (!mounted) return;
    setState(() {
      _displayState = FlashDisplayState.input;
      _isSequenceRunning = false;
    });
  }

  void _onKeyPress(String key) {
    if (_isChallengeComplete || _isSequenceRunning) return;
    setState(() {
      if (key == 'CLR') {
        _userInput = '';
      } else if (key == 'DEL') {
        if (_userInput.isNotEmpty) {
          _userInput = _userInput.substring(0, _userInput.length - 1);
        }
      } else {
        if (_userInput.length < 5) {
          _userInput += key;
        }
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
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.cyanAccent,
      AppColors.accent,
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

  void _handleCorrectAnswer() {
    final gain = 3 * _scoreMultiplier;
    _correctCount++;
    _comboCount++;
    int comboBonus = _comboCount;
    _score += (gain + comboBonus);
    _sessionScoreChange += (gain + comboBonus);
    context.read<UserProvider>().addScore(gain);
    context.read<UserProvider>().addScore(comboBonus, gameName: 'Flash Combo');

    _triggerComboAnimation();

    if (_comboCount >= 20) {
      MathDialog.show(
        context,
        title: 'FLASH EXPERT!',
        message:
            'Amazing 20 COMBO reached!\nYou have absolute concentration!\nTotal Score: $_score',
        isSuccess: true,
        onConfirm: () => Navigator.pop(context),
      );
      return;
    }

    if (_correctCount >= _totalQuestions) {
      _totalStopwatch.stop();
      _isChallengeComplete = true;
      _timer?.cancel();
      _showCompleteDialog();
    } else {
      _generateNextQuestion();
    }
  }

  void _checkAnswer() {
    if (_userInput.isEmpty || _isChallengeComplete) return;

    int? userVal = int.tryParse(_userInput);
    int correctResult = _nums.reduce((a, b) => a + b);

    if (userVal == correctResult) {
      _startExplosion();
      if (context.read<UserProvider>().isVibrationEnabled) {
        Vibration.vibrate(duration: 50);
      }
      _handleCorrectAnswer();
    } else {
      final loss = 1 * _scoreMultiplier;
      setState(() {
        _score -= loss;
        _sessionScoreChange -= loss;
        _comboCount = 0;
      });
      _userProvider.addScore(-loss);
      _showGameOverDialog(correctResult);
    }
  }

  void _showGameOverDialog(int correctResult) {
    String equation = _nums.join(' + ');
    MathDialog.show(
      context,
      title: 'GAME OVER',
      message:
          'One mistake is all it takes!\n\n'
          'Problem: $equation\n'
          'Correct Answer: $correctResult',
      isSuccess: false,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showCompleteDialog() {
    MathDialog.show(
      context,
      title: 'CHALLENGE COMPLETE!',
      message:
          'You finished 10 problems with lightning speed!\n\n'
          'TOTAL RECORD: $_elapsedTime s',
      isSuccess: true,
      onConfirm: _startChallenge,
    );
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
        title: const Text('Flash Mental (10 Problems)'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Row(
                children: [
                  Text(
                    'SCORE: $_score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'COMBO: $_comboCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    '$_correctCount / $_totalQuestions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: accent,
                    ),
                  ),
                ],
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
                              if (_currentDisplayIndex != -1)
                                Text(
                                  '${_nums[_currentDisplayIndex]}',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color,
                                  ),
                                ),
                              if (_displayState == FlashDisplayState.input) ...[
                                Text(
                                  _userInput.isEmpty ? '?' : _userInput,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _userInput.isEmpty
                                        ? color.withOpacity(0.3)
                                        : color,
                                  ),
                                ),
                              ],
                              if (_displayState == FlashDisplayState.empty &&
                                  _currentDisplayIndex == -1)
                                const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Custom Keypad
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
                        ? Colors.redAccent
                        : Theme.of(context).textTheme.titleLarge?.color,
                    padding: const EdgeInsets.symmetric(vertical: 24),
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
          onPressed: (_isChallengeComplete || _isSequenceRunning)
              ? null
              : _checkAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 24),
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
