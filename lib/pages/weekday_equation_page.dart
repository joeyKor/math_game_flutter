import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/services/tts_service.dart';
import 'package:math/services/commentary_service.dart';
import 'package:vibration/vibration.dart';

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

class WeekdayEquationPage extends StatefulWidget {
  final int difficulty;
  const WeekdayEquationPage({super.key, required this.difficulty});

  @override
  State<WeekdayEquationPage> createState() => _WeekdayEquationPageState();
}

class _WeekdayEquationPageState extends State<WeekdayEquationPage>
    with SingleTickerProviderStateMixin {
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late int _refWeekdayIndex;
  List<int> _dayIndices = [];
  List<int> _dayOffsets = [];
  late int _targetSum;
  String _expression = '';

  List<String> _userInputs = [];
  int _activeFieldIndex = 0;
  bool _isProcessing = false;

  int _score = 0;
  int _sessionScoreChange = -1;
  late UserProvider _userProvider;

  int get _scoreGain =>
      widget.difficulty == 3 ? 30 : (widget.difficulty == 2 ? 10 : 3);

  // Animation logic
  late AnimationController _particleController;
  final List<Particle> _particles = [];
  final GlobalKey _problemDisplayKey = GlobalKey();
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            for (var p in _particles) p.update();
            _particles.removeWhere((p) => p.life <= 0);
          });
    _generateProblem();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _userProvider.addHistoryEntry(
      _sessionScoreChange,
      'Weekday Equation Session',
    );
    super.dispose();
  }

  int _getDate(int dayIndex, int refIndex, int offset) {
    return ((dayIndex - refIndex) % 7 + 7) % 7 + 1 + offset;
  }

  void _generateProblem() {
    final random = math.Random();
    _refWeekdayIndex = random.nextInt(7);
    _dayIndices = [];
    _dayOffsets = [];
    _userInputs = [];
    List<int> usedDates = [];

    int count = widget.difficulty == 1 ? 2 : 3;

    if (widget.difficulty == 1) {
      for (int i = 0; i < count; i++) {
        while (true) {
          int dIdx = random.nextInt(7);
          // Level 1: Limit range to 1-10 days
          int off = random.nextBool() ? 0 : 7;
          int val = _getDate(dIdx, _refWeekdayIndex, off);
          if (val <= 10 && !usedDates.contains(val)) {
            _dayIndices.add(dIdx);
            _dayOffsets.add(off);
            _userInputs.add('');
            usedDates.add(val);
            break;
          }
        }
      }
      int valA = _getDate(_dayIndices[0], _refWeekdayIndex, _dayOffsets[0]);
      int valB = _getDate(_dayIndices[1], _refWeekdayIndex, _dayOffsets[1]);
      _targetSum = valA + valB;
      _expression =
          '${_weekdays[_dayIndices[0]]} + ${_weekdays[_dayIndices[1]]} = $_targetSum';
    } else if (widget.difficulty == 2) {
      List<int> vals = [];
      for (int i = 0; i < count; i++) {
        while (true) {
          int dIdx = random.nextInt(7);
          // Level 2: Limit range to 1-10 days
          int off = random.nextBool() ? 0 : 7;
          int val = _getDate(dIdx, _refWeekdayIndex, off);
          if (val <= 10 && !usedDates.contains(val)) {
            _dayIndices.add(dIdx);
            _dayOffsets.add(off);
            _userInputs.add('');
            vals.add(val);
            usedDates.add(val);
            break;
          }
        }
      }
      _targetSum = vals.reduce((a, b) => a + b);
      _expression =
          '${_weekdays[_dayIndices[0]]} + ${_weekdays[_dayIndices[1]]} + ${_weekdays[_dayIndices[2]]} = $_targetSum';
    } else {
      // Level 3: Arithmetic Ops (within 10 days)
      while (true) {
        _dayIndices = [];
        _dayOffsets = [];
        _userInputs = [];
        usedDates = [];
        List<int> vals = [];
        for (int i = 0; i < 3; i++) {
          while (true) {
            int dIdx = random.nextInt(7);
            int off = random.nextBool() ? 0 : 7;
            int val = _getDate(dIdx, _refWeekdayIndex, off);
            if (val <= 10 && !usedDates.contains(val)) {
              _dayIndices.add(dIdx);
              _dayOffsets.add(off);
              _userInputs.add('');
              vals.add(val);
              usedDates.add(val);
              break;
            }
          }
        }

        final ops = ['+', '-', '*'];
        String op1 = ops[random.nextInt(ops.length)];
        String op2 = ops[random.nextInt(ops.length)];

        int result;
        if (op1 == '*') {
          result = vals[0] * vals[1];
          if (op2 == '+')
            result += vals[2];
          else if (op2 == '-')
            result -= vals[2];
          else
            result *= vals[2];
        } else if (op2 == '*') {
          result = vals[1] * vals[2];
          if (op1 == '+')
            result = vals[0] + result;
          else
            result = vals[0] - result;
        } else {
          if (op1 == '+')
            result = vals[0] + vals[1];
          else
            result = vals[0] - vals[1];

          if (op2 == '+')
            result += vals[2];
          else
            result -= vals[2];
        }

        if (result > 0) {
          _targetSum = result;
          _expression =
              '${_weekdays[_dayIndices[0]]} $op1 ${_weekdays[_dayIndices[1]]} $op2 ${_weekdays[_dayIndices[2]]} = $_targetSum';
          break;
        }
      }
    }

    _activeFieldIndex = 0;
    _isProcessing = false;
    setState(() {});
  }

  void _startExplosion() {
    try {
      final RenderBox? box =
          _problemDisplayKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;

      final RenderBox? overlay =
          Navigator.of(context).overlay?.context.findRenderObject()
              as RenderBox?;
      final position = box.localToGlobal(
        Offset(box.size.width / 2, box.size.height / 2),
        ancestor: overlay,
      );

      final List<Color> colors = [
        Colors.orangeAccent,
        Colors.yellowAccent,
        Colors.cyanAccent,
        Colors.pinkAccent,
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
    } catch (e) {
      debugPrint('Explosion error: $e');
    }
  }

  void _onKeyPress(String key) {
    if (_isProcessing) return;
    setState(() {
      if (key == 'CLR') {
        _userInputs[_activeFieldIndex] = '';
      } else if (key == 'DEL') {
        if (_userInputs[_activeFieldIndex].isNotEmpty) {
          _userInputs[_activeFieldIndex] = _userInputs[_activeFieldIndex]
              .substring(0, _userInputs[_activeFieldIndex].length - 1);
        }
      } else {
        if (_userInputs[_activeFieldIndex].length < 2) {
          _userInputs[_activeFieldIndex] += key;
        }
      }
    });
  }

  void _checkAnswer() {
    if (_isProcessing) return;

    try {
      List<int?> answers = _userInputs.map((e) => int.tryParse(e)).toList();

      if (answers.any((e) => e == null)) return;

      List<int> correctVals = [];
      for (int i = 0; i < _dayIndices.length; i++) {
        correctVals.add(
          _getDate(_dayIndices[i], _refWeekdayIndex, _dayOffsets[i]),
        );
      }

      bool isCorrect = true;
      for (int i = 0; i < correctVals.length; i++) {
        if (answers[i] != correctVals[i]) {
          isCorrect = false;
          break;
        }
      }

      final user = context.read<UserProvider>();
      final gain = _scoreGain;
      final loss = widget.difficulty == 1
          ? 2
          : (widget.difficulty == 2 ? 5 : 8);

      if (isCorrect) {
        setState(() {
          _isProcessing = true;
          _score += gain;
          _sessionScoreChange += gain;
        });

        _startExplosion();
        _userProvider.addScore(gain);

        if (user.isTtsEnabled) {
          try {
            TtsService().speak(CommentaryService.getHitPhrase(user.username));
          } catch (e) {
            debugPrint('TTS error: $e');
          }
        }
        if (user.isVibrationEnabled) {
          try {
            Vibration.vibrate(duration: 50);
          } catch (e) {
            debugPrint('Vibration error: $e');
          }
        }

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _generateProblem();
        });
      } else {
        setState(() {
          _score -= loss;
          _sessionScoreChange -= loss;
        });
        _userProvider.addScore(-loss);

        String correctString = "";
        for (int i = 0; i < correctVals.length; i++) {
          correctString +=
              "${_weekdays[_dayIndices[i]]}=${correctVals[i]}${i < correctVals.length - 1 ? ', ' : ''}";
        }

        MathDialog.show(
          context,
          title: 'WRONG!',
          message: 'Correct:\n$correctString\nExpr: $_expression',
          isSuccess: false,
          onConfirm: () {
            _generateProblem();
          },
        );
      }
    } catch (e) {
      debugPrint('General error in _checkAnswer: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<UserProvider>().currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final color = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Weekday Equation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text(
                'SCORE: $_score',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildReferenceCard(),
                        const SizedBox(height: 30),
                        _buildProblemArea(),
                        const SizedBox(height: 30),
                        _buildInputs(color),
                      ],
                    ),
                  ),
                ),
                _buildKeypad(color),
                const SizedBox(height: 20),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles),
                  child: Container(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.white70),
          const SizedBox(width: 12),
          Text(
            '1st is ${_weekdays[_refWeekdayIndex]}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemArea() {
    return Column(
      key: _problemDisplayKey,
      children: [
        Text(
          'Problem',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          _expression,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInputs(Color color) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_userInputs.length, (index) {
        return SizedBox(
          width: 100,
          child: _buildInputSlot(
            index: index,
            label: _weekdays[_dayIndices[index]],
            value: _userInputs[index],
            color: color,
          ),
        );
      }),
    );
  }

  Widget _buildInputSlot({
    required int index,
    required String label,
    required String value,
    required Color color,
  }) {
    bool isActive = _activeFieldIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFieldIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? color : Colors.white.withOpacity(0.2),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Text(
              value.isEmpty ? '?' : value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: value.isEmpty ? Colors.white24 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3', '4']),
          const SizedBox(height: 8),
          _buildKeyRow(['5', '6', '7', '8']),
          const SizedBox(height: 8),
          _buildKeyRow(['9', '0', 'CLR', 'DEL']),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        bool isAction = key == 'CLR' || key == 'DEL';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => _onKeyPress(key),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: isAction ? Colors.orangeAccent : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
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
        );
      }).toList(),
    );
  }
}
