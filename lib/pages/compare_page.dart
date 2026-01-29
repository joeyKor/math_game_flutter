import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

enum CompareState { reveal, choice, result }

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late List<int> _leftNums;
  late List<int> _rightNums;
  CompareState _state = CompareState.reveal;
  int _countdown = 10;
  Timer? _countdownTimer;
  int? _userChoice; // 0 for left, 1 for right
  int _score = 0;
  int _sessionScoreChange = -1; // -1 for entry fee
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
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
    // Record session total to history
    _userProvider.addHistoryEntry(
      _sessionScoreChange,
      'Sum Comparison Session',
    );
    super.dispose();
  }

  void _generateProblem() {
    final random = math.Random();

    while (true) {
      _leftNums = List.generate(3, (_) => random.nextInt(90) + 10);
      _rightNums = List.generate(3, (_) => random.nextInt(90) + 10);

      int sumLeft = _leftNums.reduce((a, b) => a + b);
      int sumRight = _rightNums.reduce((a, b) => a + b);
      int diff = (sumLeft - sumRight).abs();

      if (diff >= 1 && diff <= 9) {
        break;
      }
    }

    _state = CompareState.reveal;
    _countdown = 10;
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

    if (isCorrect) {
      _score += 3;
      _sessionScoreChange += 3;
      context.read<UserProvider>().addScore(3);
    } else {
      _score -= 2;
      _sessionScoreChange -= 2;
      context.read<UserProvider>().addScore(-2);
    }

    MathDialog.show(
      context,
      title: isCorrect ? 'CORRECT!' : 'WRONG!',
      message: isCorrect
          ? 'You have a sharp eye and quick brain!'
          : 'The other side was larger. Try again!',
      isSuccess: isCorrect,
      onConfirm: _generateProblem,
    );
  }

  @override
  Widget build(BuildContext context) {
    int sumLeft = _leftNums.reduce((a, b) => a + b);
    int sumRight = _rightNums.reduce((a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sum Comparison'),
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
          IconButton(
            onPressed: _generateProblem,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const Spacer(),
              _buildCompareButtons(sumLeft, sumRight),
              const Spacer(),
              if (_state == CompareState.result)
                _buildResults(sumLeft, sumRight),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String message = '';
    Color statusColor = Colors.white;

    switch (_state) {
      case CompareState.reveal:
        message = 'Memorize the sums! ($_countdown)';
        statusColor = AppColors.accent;
        break;
      case CompareState.choice:
        message = 'Which one is LARGER?';
        statusColor = AppColors.primary;
        break;
      case CompareState.result:
        message = 'Check the result!';
        statusColor = Colors.white70;
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
            value: _countdown / 10,
            backgroundColor: Colors.white10,
            color: AppColors.accent,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
      ],
    );
  }

  Widget _buildCompareButtons(int sumLeft, int sumRight) {
    return Row(
      children: [
        _buildChoiceCard(
          index: 0,
          sum: _leftNums.join(' + '),
          color: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _buildChoiceCard(
          index: 1,
          sum: _rightNums.join(' + '),
          color: AppColors.secondary,
        ),
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
              color: AppColors.cardBg,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildResults(int left, int right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBigResult(left, left > right),
        const Text('vs', style: TextStyle(color: Colors.white24, fontSize: 20)),
        _buildBigResult(right, right > left),
      ],
    );
  }

  Widget _buildBigResult(int value, bool isWinner) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isWinner ? AppColors.accent : Colors.white24,
          ),
        ),
        if (isWinner)
          const Text(
            'WINNER',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }
}
