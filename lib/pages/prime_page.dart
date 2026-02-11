import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';
import 'package:vibration/vibration.dart';

class PrimePage extends StatefulWidget {
  final int difficulty;
  const PrimePage({super.key, this.difficulty = 1});

  @override
  State<PrimePage> createState() => _PrimePageState();
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

class _PrimePageState extends State<PrimePage> with TickerProviderStateMixin {
  final math.Random _random = math.Random();
  List<int> _numbers = [];
  final Set<int> _selectedIndices = {};
  final Set<int> _foundPrimeIndices = {};
  final Set<int> _wrongIndices = {};
  int _score = 0;
  final int _targetPrimeCount = 4;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _wrongCount = 0;
  int _comboCount = 0;

  // Animation logic
  late AnimationController _particleController;
  late AnimationController _comboController;
  late Animation<double> _comboOpacity;
  late Animation<double> _comboScale;
  bool _showComboBonus = false;

  final List<Particle> _particles = [];
  final List<GlobalKey> _gridKeys = List.generate(16, (_) => GlobalKey());
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
    _generateGameBoard();
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
    // Record session total to history
    _userProvider.addHistoryEntry(
      _sessionScoreChange,
      'Prime Detector Session',
    );
    super.dispose();
  }

  void _triggerComboAnimation() {
    setState(() => _showComboBonus = true);
    _comboController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showComboBonus = false);
    });
  }

  bool _isPrime(int n) {
    if (n < 2) return false;
    for (int i = 2; i <= math.sqrt(n); i++) {
      if (n % i == 0) return false;
    }
    return true;
  }

  void _generateGameBoard() {
    setState(() {
      _selectedIndices.clear();
      _foundPrimeIndices.clear();
      _wrongIndices.clear();
      _wrongCount = 0;
      _comboCount = 0;

      List<int> primes = [];
      List<int> composites = [];
      int attempts = 0;

      // Generate pool of odd numbers based on difficulty
      while ((primes.length < _targetPrimeCount ||
              composites.length < (16 - _targetPrimeCount)) &&
          attempts < 500) {
        attempts++;
        int n;
        if (widget.difficulty == 2) {
          // Level 2: 1001 to 9999 (odd)
          n = _random.nextInt(4500) * 2 + 1001;
        } else {
          // Level 1: 11 to 999 (odd)
          n = _random.nextInt(495) * 2 + 11;
        }

        if (_isPrime(n)) {
          if (primes.length < _targetPrimeCount && !primes.contains(n)) {
            primes.add(n);
          }
        } else {
          if (composites.length < (16 - _targetPrimeCount) &&
              !composites.contains(n)) {
            composites.add(n);
          }
        }
      }

      _numbers = [...primes, ...composites];
      _numbers.shuffle(_random);
    });
  }

  List<int> _getPrimeFactors(int n) {
    List<int> factors = [];
    int d = 2;
    int temp = n;
    while (temp > 1) {
      while (temp % d == 0) {
        factors.add(d);
        temp ~/= d;
      }
      d++;
      if (d * d > temp) {
        if (temp > 1) factors.add(temp);
        break;
      }
    }
    return factors;
  }

  void _onNumberTap(int index) {
    if (_selectedIndices.contains(index) || _foundPrimeIndices.contains(index))
      return;

    setState(() {
      _selectedIndices.add(index);
      int number = _numbers[index];
      if (_isPrime(number)) {
        _foundPrimeIndices.add(index);
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
            gameName: 'Prime Combo',
          );
        }
        _startExplosion(index);
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

        _triggerComboAnimation();

        if (_comboCount >= 20) {
          MathDialog.show(
            context,
            title: 'PRIME MASTER!',
            message:
                'LEGENDARY 20 COMBO!\nYou found the primes with precision!\nTotal Score: $_score',
            isSuccess: true,
            onConfirm: () => Navigator.pop(context),
          );
          return;
        }

        if (_foundPrimeIndices.length == _targetPrimeCount) {
          _score += 30;
          _sessionScoreChange += 30;
          context.read<UserProvider>().addScore(30);
          _showWinDialog();
        } else {
          // Success commentary for regular hits (no popup)
          final user = context.read<UserProvider>();
          if (user.isTtsEnabled) {
            TtsService().speak(
              CommentaryService.getHitPhrase(
                user.username,
                target: number.toString(),
              ),
            );
          }
        }
      } else {
        _wrongIndices.add(index);
        final loss = widget.difficulty == 1 ? 2 : 4;
        _score -= loss;
        _sessionScoreChange -= loss;
        context.read<UserProvider>().addScore(-loss);
        _wrongCount++;
        _comboCount = 0;
        if (_wrongCount >= 2) {
          _showGameOverDialog();
        } else {
          _showWrongDialog(number);
        }
      }
    });
  }

  void _startExplosion(int index) {
    final RenderBox? box =
        _gridKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position =
        box.localToGlobal(Offset.zero, ancestor: context.findRenderObject()) +
        Offset(box.size.width / 2, box.size.height / 2);

    final List<Color> colors = [
      Colors.greenAccent,
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

  void _showWrongDialog(int number) {
    final factors = _getPrimeFactors(number);
    final user = context.read<UserProvider>();
    MathDialog.show(
      context,
      title: 'NOT A PRIME!',
      message:
          "${CommentaryService.getMissPhrase(user.username, result: number.toString())}\n"
          "Actually, $number is composite!\n"
          "Factorization: ${factors.join(' × ')}",
      isSuccess: false,
    );
  }

  void _showGameOverDialog() {
    final user = context.read<UserProvider>();
    MathDialog.show(
      context,
      title: 'GAME OVER',
      message: CommentaryService.getGameOverPhrase(user.username),
      isSuccess: false,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showWinDialog() {
    final user = context.read<UserProvider>();
    MathDialog.show(
      context,
      title: 'EXCELLENT!',
      message: CommentaryService.getWinPhrase(user.username),
      isSuccess: true,
      onConfirm: _generateGameBoard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final color = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Prime Detector (4x4)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Find $_targetPrimeCount Primes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        bool isFound = _foundPrimeIndices.contains(index);
                        bool isWrong = _wrongIndices.contains(index);

                        return GestureDetector(
                          key: _gridKeys[index],
                          onTap: () => _onNumberTap(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFound
                                  ? Colors.green.withOpacity(0.3)
                                  : isWrong
                                  ? Colors.red.withOpacity(0.3)
                                  : Theme.of(
                                      context,
                                    ).cardTheme.color?.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isFound
                                    ? Colors.green
                                    : isWrong
                                    ? Colors.red
                                    : color.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                if (isFound)
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${_numbers[index]}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isFound
                                      ? Colors.greenAccent
                                      : isWrong
                                      ? Colors.redAccent
                                      : Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.color,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_foundPrimeIndices.length} / $_targetPrimeCount Found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _generateGameBoard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Board'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).cardTheme.color?.withOpacity(0.7),
                      foregroundColor: Theme.of(
                        context,
                      ).textTheme.titleLarge?.color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
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
}
