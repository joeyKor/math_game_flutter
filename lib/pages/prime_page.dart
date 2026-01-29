import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

class PrimePage extends StatefulWidget {
  const PrimePage({super.key});

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

class _PrimePageState extends State<PrimePage>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  List<int> _numbers = [];
  final Set<int> _selectedIndices = {};
  final Set<int> _foundPrimeIndices = {};
  final Set<int> _wrongIndices = {};
  int _score = 0;
  final int _targetPrimeCount = 4;
  int _sessionScoreChange = -1; // -1 for entry fee
  int _wrongCount = 0;

  // Animation controllers
  late AnimationController _particleController;
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
    // Record session total to history
    _userProvider.addHistoryEntry(
      _sessionScoreChange,
      'Prime Detector Session',
    );
    super.dispose();
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

      List<int> primes = [];
      List<int> composites = [];

      // Generate pool of odd numbers 11-999
      while (primes.length < _targetPrimeCount ||
          composites.length < (16 - _targetPrimeCount)) {
        int n =
            _random.nextInt(495) * 2 +
            11; // Generates odd numbers from 11 to 999
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
        _score += 3;
        _sessionScoreChange += 3;
        context.read<UserProvider>().addScore(3);
        _startExplosion(index);

        if (_foundPrimeIndices.length == _targetPrimeCount) {
          _showWinDialog();
        }
      } else {
        _wrongIndices.add(index);
        _score -= 1;
        _sessionScoreChange -= 1;
        context.read<UserProvider>().addScore(-1);
        _wrongCount++;
        if (_wrongCount >= 4) {
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
    MathDialog.show(
      context,
      title: 'NOT A PRIME!',
      message:
          'Actually, $number is a composite number.\n\n'
          'Factorization: ${factors.join(' × ')}\n'
          'Strikes: $_wrongCount / 4',
      isSuccess: false,
    );
  }

  void _showGameOverDialog() {
    MathDialog.show(
      context,
      title: 'GAME OVER',
      message: 'You made 4 mistakes. Focus more next time!',
      isSuccess: false,
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showWinDialog() {
    MathDialog.show(
      context,
      title: 'EXCELLENT!',
      message:
          'You found all $_targetPrimeCount primes!\nYour eye is getting sharp.',
      isSuccess: true,
      onConfirm: _generateGameBoard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prime Detector (4x4)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                'SCORE: $_score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
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
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isFound
                                    ? Colors.green
                                    : isWrong
                                    ? Colors.red
                                    : AppColors.primary.withOpacity(0.3),
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
                                      : Colors.white,
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
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _generateGameBoard,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Board'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardBg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
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
          ],
        ),
      ),
    );
  }
}
