import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';

class FactorialPage extends StatefulWidget {
  const FactorialPage({super.key});

  @override
  State<FactorialPage> createState() => _FactorialPageState();
}

class _FactorialPageState extends State<FactorialPage> {
  final TextEditingController _controller = TextEditingController();
  String _result = '1';
  String _process = '1!';
  int _sessionScoreChange = 0; // No entry fee
  late UserProvider _userProvider;

  void _calculate() {
    final int? val = int.tryParse(_controller.text);
    if (val != null && val >= 0 && val <= 20) {
      int res = 1;
      List<int> steps = [];
      for (int i = 1; i <= val; i++) {
        res *= i;
        steps.add(i);
      }
      setState(() {
        _result = res.toString();
        _process = val == 0 ? '0! = 1' : '${steps.join(' × ')} = $res';
        _sessionScoreChange += 5;
        context.read<UserProvider>().addScore(5);
      });
    } else if (val != null && val > 20) {
      MathDialog.show(
        context,
        title: 'TOO HEAVY!',
        message:
            'The factorial of $val is way too large for this app. Please enter a number ≤ 20.',
        isSuccess: false,
      );
      _controller.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_sessionScoreChange != 0) {
      _userProvider.addHistoryEntry(
        _sessionScoreChange,
        'Factorial Calc Session',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Factorial Calculator'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter integer (0-20)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: AppColors.cardBg,
                ),
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Result (n!)',
                      style: TextStyle(color: AppColors.textBody),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 20),
                    Text(
                      _process,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textBody,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
