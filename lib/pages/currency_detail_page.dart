import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;

class CurrencyDetailPage extends StatefulWidget {
  final String currencyCode;
  final String currencyName;
  final String symbol;

  const CurrencyDetailPage({
    super.key,
    required this.currencyCode,
    required this.currencyName,
    required this.symbol,
  });

  @override
  State<CurrencyDetailPage> createState() => _CurrencyDetailPageState();
}

class _CurrencyDetailPageState extends State<CurrencyDetailPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isBuying = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleTransaction() async {
    int? amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid integer amount')),
      );
      return;
    }

    final user = context.read<UserProvider>();
    bool success;
    if (_isBuying) {
      success = await user.buyCurrency(widget.currencyCode, amount.toDouble());
    } else {
      success = await user.sellCurrency(widget.currencyCode, amount.toDouble());
    }

    if (success) {
      _amountController.clear();
      if (mounted) {
        MathDialog.show(
          context,
          title: 'TRANSACTION SUCCESS!',
          message: _isBuying
              ? 'Successfully bought $amount ${widget.currencyCode}'
              : 'Successfully sold $amount ${widget.currencyCode}',
          isSuccess: true,
          onConfirm: () => Navigator.pop(context),
        );
      }
    } else {
      if (mounted) {
        MathDialog.show(
          context,
          title: 'TRANSACTION FAILED!',
          message: _isBuying
              ? 'Not enough points for $amount ${widget.currencyCode}'
              : 'Not enough ${widget.currencyCode} holdings to sell',
          isSuccess: false,
          onConfirm: () => Navigator.pop(context),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final config =
        AppThemes.configs[user.currentTheme] ?? AppThemes.configs['Default']!;
    final buyPrice = user.currencyPrices[widget.currencyCode] ?? 0;
    final sellPrice = user.getSellPrice(widget.currencyCode);
    final history = user.currencyHistory[widget.currencyCode] ?? [];
    final nf = NumberFormat('#,###');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${widget.currencyName} (${widget.currencyCode})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [config.gradientStart, config.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPriceTrend(buyPrice, history),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF161622),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildMarketInfo(buyPrice, sellPrice, nf),
                        const SizedBox(height: 40),
                        _buildTradeBox(user, buyPrice, sellPrice, nf),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTrend(int currentPrice, List<int> history) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRICE TREND (Last 7 Days)',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : CustomPaint(
                    size: Size.infinite,
                    painter: PriceChartPainter(
                      history: history,
                      color: Colors.blueAccent,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInfo(int buyPrice, int sellPrice, NumberFormat nf) {
    return Row(
      children: [
        _buildInfoCard(
          'Buy Price',
          '${nf.format(buyPrice)}P',
          Colors.blueAccent,
        ),
        const SizedBox(width: 16),
        _buildInfoCard(
          'Sell Price',
          '${nf.format(sellPrice)}P',
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeBox(
    UserProvider user,
    int buyPrice,
    int sellPrice,
    NumberFormat nf,
  ) {
    final holding = user.currencyHoldings[widget.currencyCode] ?? 0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTypeToggle(true, 'BUY')),
              Expanded(child: _buildTypeToggle(false, 'SELL')),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: Colors.white10),
            labelText: 'Units to ${_isBuying ? "Buy" : "Sell"}',
            labelStyle: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _buildEstimatedTotal(buyPrice, sellPrice, nf),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _showHistory(user, nf),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available: ${holding.toInt()} ${widget.currencyCode}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _handleTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBuying ? Colors.blueAccent : Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
            ),
            child: Text(
              'CONFIRM ${_isBuying ? "PURCHASE" : "SALE"}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTotal(int buyPrice, int sellPrice, NumberFormat nf) {
    int? amount = int.tryParse(_amountController.text) ?? 0;
    int total = _isBuying ? (amount * buyPrice) : (amount * sellPrice);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Total Value: ',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
        Text(
          '${nf.format(total)} Points',
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showHistory(UserProvider user, NumberFormat nf) {
    final history =
        user.fxHistory[widget.currencyCode]?.reversed.toList() ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF161622),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction History',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.currencyName} Account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            // List or Empty State
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No transactions yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your buy and sell history will appear here.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final tx = history[index];
                        final isBuy = tx.type == 'BUY';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      (isBuy
                                              ? Colors.blueAccent
                                              : Colors.redAccent)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  isBuy
                                      ? Icons.keyboard_double_arrow_up_rounded
                                      : Icons
                                            .keyboard_double_arrow_down_rounded,
                                  color: isBuy
                                      ? Colors.blueAccent
                                      : Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isBuy ? 'Bought' : 'Sold',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'MMM d, yyyy • HH:mm',
                                      ).format(tx.date),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isBuy ? "+" : "-"}${tx.amount.toInt()} ${widget.currencyCode}',
                                    style: TextStyle(
                                      color: isBuy
                                          ? Colors.blueAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${nf.format(tx.totalPoints)} P',
                                    style: TextStyle(
                                      color: Colors.amberAccent.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(bool value, String label) {
    final active = _isBuying == value;
    return GestureDetector(
      onTap: () => setState(() {
        _isBuying = value;
        _amountController.clear();
      }),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: active
              ? (value ? Colors.blueAccent : Colors.redAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class PriceChartPainter extends CustomPainter {
  final List<int> history;
  final Color color;

  PriceChartPainter({required this.history, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    int minVal = history.reduce(math.min);
    int maxVal = history.reduce(math.max);
    int range = maxVal - minVal;
    if (range == 0) range = 1;

    double xStep = size.width / (history.length - 1);
    List<Offset> points = [];

    for (int i = 0; i < history.length; i++) {
      double x = i * xStep;
      double y =
          size.height -
          ((history[i] - minVal) / range * size.height * 0.6 +
              size.height * 0.2);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == history.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots and labels
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < history.length; i++) {
      final point = points[i];
      canvas.drawCircle(point, 4, dotPaint);

      // Draw Price Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${history[i]}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black45,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(point.dx - textPainter.width / 2, point.dy - 20),
      );
    }

    // Draw Axis Guides
    _drawAxisLabel(canvas, size, '7 Days Ago', 0);
    _drawAxisLabel(canvas, size, 'Today', size.width - 40);
  }

  void _drawAxisLabel(Canvas canvas, Size size, String text, double x) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, size.height - tp.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
