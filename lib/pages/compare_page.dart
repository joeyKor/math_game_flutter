import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';
import 'package:vibration/vibration.dart';

enum CompareState { reveal, choice, result }

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

class ComparePage extends StatefulWidget {
  final int difficulty;
  const ComparePage({super.key, required this.difficulty});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage>
    with TickerProviderStateMixin {
  late List<int> _leftNums;
  late List<int> _rightNums;
  CompareState _state = CompareState.reveal;
  int _countdown = 10;
  Timer? _countdownTimer;
  int? _userChoice; // 0 for left, 1 for right
  int _score = 0;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _comboCount = 0;
  late UserProvider _userProvider;

  // Animation logic
  late AnimationController _particleController;
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;

  final List<Particle> _particles = [];
  final GlobalKey _problemDisplayKey = GlobalKey();
  final math.Random _random = math.Random();

  int get _maxCountdown =>
      widget.difficulty == 3 ? 15 : (widget.difficulty == 2 ? 12 : 10);
  int get _scoreMultiplier => widget.difficulty;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _particleController.dispose();
    _comboController.dispose();
    // Record session total to history
    _userProvider.addHistoryEntry(
      _sessionScoreChange,
      'Sum Comparison Session',
    );
    super.dispose();
  }

  void _generateProblem() {
    final random = math.Random();

    int attempts = 0;
    while (attempts < 200) {
      attempts++;
      if (widget.difficulty == 1) {
        // Level 1: 2+2+2
        _leftNums = List.generate(3, (_) => random.nextInt(90) + 10);
        _rightNums = List.generate(3, (_) => random.nextInt(90) + 10);
      } else if (widget.difficulty == 2) {
        // Level 2: 3+2+2
        _leftNums = [
          random.nextInt(900) + 100,
          random.nextInt(90) + 10,
          random.nextInt(90) + 10,
        ];
        _rightNums = [
          random.nextInt(900) + 100,
          random.nextInt(90) + 10,
          random.nextInt(90) + 10,
        ];
        _leftNums.shuffle();
        _rightNums.shuffle();
      } else {
        // Level 3: 3+3+3
        _leftNums = List.generate(3, (_) => random.nextInt(900) + 100);
        _rightNums = List.generate(3, (_) => random.nextInt(900) + 100);
      }

      int sumLeft = _leftNums.reduce((a, b) => a + b);
      int sumRight = _rightNums.reduce((a, b) => a + b);
      int diff = (sumLeft - sumRight).abs();

      if (diff >= 1 && diff <= 9) {
        break;
      }
    }

    _state = CompareState.reveal;
    _countdown = _maxCountdown;
    _userChoice = null;

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _state = CompareState.choice;
          timer.cancel();
        }
      });
    });
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
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

  void _handleChoice(int choice) {
    if (_state != CompareState.choice && _state != CompareState.reveal) return;

    setState(() {
      _userChoice = choice;
      _state = CompareState.result;
    });

    int sumLeft = _leftNums.reduce((a, b) => a + b);
    int sumRight = _rightNums.reduce((a, b) => a + b);
    bool isCorrect =
        (choice == 0 && sumLeft > sumRight) ||
        (choice == 1 && sumRight > sumLeft);

    final gain = 3 * _scoreMultiplier;
    final loss = 2 * _scoreMultiplier;
    final user = context.read<UserProvider>();

    if (isCorrect) {
      _score += gain;
      _sessionScoreChange += gain;
      _comboCount++;
      int comboBonus = _comboCount;
      _score += comboBonus;
      _sessionScoreChange += comboBonus;

      _comboCount > 0 ? user.addDiamonds(comboBonus) : user.addScore(gain);
      if (_comboCount > 0) user.addScore(gain);

      _startExplosion();
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
          Vibration.vibrate(duration: 50);
        }
      }

      if (_comboCount >= 20) {
        MathDialog.show(
          context,
          title: 'COMPARISON KING!',
          message:
              'LEGENDARY 20 COMBO!\nYou have sharp eyes for numbers!\nTotal Score: $_score',
          isSuccess: true,
          onConfirm: () => Navigator.pop(context),
        );
        return;
      }

      // Auto-generate next problem after a short delay to see results
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _state == CompareState.result) {
          _generateProblem();
        }
      });
    } else {
      _score -= loss;
      _sessionScoreChange -= loss;
      _comboCount = 0;
      _userProvider.addScore(-loss);

      MathDialog.show(
        context,
        title: 'GAME OVER!',
        message: CommentaryService.getMissPhrase(user.username),
        isSuccess: false,
        onConfirm: () => Navigator.pop(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final color = Theme.of(context).primaryColor;
    final accent = Theme.of(context).colorScheme.secondary;

    int sumLeft = _leftNums.reduce((a, b) => a + b);
    int sumRight = _rightNums.reduce((a, b) => a + b);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Sum Comparison'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    '💎 ${context.watch<UserProvider>().diamonds}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _generateProblem,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(
                context,
              ).textTheme.titleLarge?.color?.withOpacity(0.7),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    key: _problemDisplayKey,
                    child: _buildHeader(color, accent),
                  ),
                  _buildCompareButtons(sumLeft, sumRight, color, accent),
                  const Spacer(),
                  if (_state == CompareState.result)
                    _buildResults(sumLeft, sumRight, accent),
                  const SizedBox(height: 40),
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

  Widget _buildHeader(Color color, Color accent) {
    String message = '';
    Color statusColor = Colors.white;

    switch (_state) {
      case CompareState.reveal:
        message = 'Memorize the sums! ($_countdown)';
        statusColor = accent;
        break;
      case CompareState.choice:
        message = 'Which one is LARGER?';
        statusColor = color;
        break;
      case CompareState.result:
        message = 'Check the result!';
        statusColor =
            Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ??
            Colors.white70;
        break;
    }

    return Column(
      children: [
        Text(
          message,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        if (_state == CompareState.reveal)
          LinearProgressIndicator(
            value: _countdown / _maxCountdown,
            backgroundColor: Colors.white10,
            color: accent,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
      ],
    );
  }

  Widget _buildCompareButtons(
    int sumLeft,
    int sumRight,
    Color color,
    Color accent,
  ) {
    return Row(
      children: [
        _buildChoiceCard(index: 0, sum: _leftNums.join(' + '), color: color),
        const SizedBox(width: 16),
        _buildChoiceCard(index: 1, sum: _rightNums.join(' + '), color: accent),
      ],
    );
  }

  Widget _buildChoiceCard({
    required int index,
    required String sum,
    required Color color,
  }) {
    bool isRevealed =
        _state == CompareState.reveal || _state == CompareState.result;
    bool isClickable =
        _state == CompareState.choice || _state == CompareState.reveal;

    return Expanded(
      child: AspectRatio(
        aspectRatio: 0.8,
        child: GestureDetector(
          onTap: isClickable ? () => _handleChoice(index) : null,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _userChoice == index ? color : color.withOpacity(0.2),
                width: _userChoice == index ? 3 : 1.5,
              ),
              boxShadow: [
                if (isClickable || _userChoice == index)
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isRevealed)
                  Icon(
                    Icons.help_outline_rounded,
                    size: 48,
                    color: color.withOpacity(0.5),
                  )
                else
                  Text(
                    sum,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(int left, int right, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBigResult(left, left > right, accent),
        const Text('vs', style: TextStyle(color: Colors.white24, fontSize: 20)),
        _buildBigResult(right, right > left, accent),
      ],
    );
  }

  Widget _buildBigResult(int value, bool isWinner, Color accent) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isWinner
                ? accent
                : Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
        ),
        if (isWinner)
          Text(
            'WINNER',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }
}
