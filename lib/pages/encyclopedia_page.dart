import 'package:flutter/material.dart';
import 'package:math/theme/app_theme.dart';
import 'package:math/widgets/math_dialog.dart';
import 'package:provider/provider.dart';
import 'package:math/services/user_provider.dart';
import 'package:math/pages/visualizer_page.dart';
import 'package:math/pages/geometry_page.dart';
import 'package:math/pages/unit_circle_page.dart';
import 'package:math/pages/statistics_visualizer_page.dart';

class EncyclopediaEntry {
  final String name;
  final String formula;
  final Color color;
  final String definition;
  final String explanation;
  final String example;
  final String? history;
  final String? realLifeCase;
  final Widget? diagram;

  EncyclopediaEntry({
    required this.name,
    required this.formula,
    required this.color,
    required this.definition,
    required this.explanation,
    required this.example,
    this.history,
    this.realLifeCase,
    this.diagram,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..close();

    canvas.drawPath(path, paint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: 'b',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.82));

    final dashPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.8),
      dashPaint,
    );
    textPainter.text = TextSpan(
      text: 'h',
      style: TextStyle(color: color.withOpacity(0.7), fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.52, size.height * 0.45));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CirclePainter extends CustomPainter {
  final Color color;
  CirclePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(center, center + Offset(radius, 0), paint);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'r',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, center + Offset(radius / 2, -20));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RectanglePainter extends CustomPainter {
  final Color color;
  RectanglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.6,
      size.height * 0.4,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, paint);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: 'l',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.72));
    textPainter.text = TextSpan(
      text: 'w',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.82, size.height * 0.45));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ParallelogramPainter extends CustomPainter {
  final Color color;
  ParallelogramPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..close();

    canvas.drawPath(path, paint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: 'b',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.45, size.height * 0.72));

    final dashPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.7),
      dashPaint,
    );
    textPainter.text = TextSpan(
      text: 'h',
      style: TextStyle(color: color.withOpacity(0.7), fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.22, size.height * 0.45));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RightTrianglePainter extends CustomPainter {
  final Color color;
  RightTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2) // Top
      ..lineTo(size.width * 0.2, size.height * 0.8) // Bottom Left (Right Angle)
      ..lineTo(size.width * 0.8, size.height * 0.8) // Bottom Right
      ..close();

    canvas.drawPath(path, paint);

    // Right angle symbol
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.7, 15, 15),
      paint..strokeWidth = 1,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Label a (height)
    textPainter.text = TextSpan(
      text: 'a',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.45));

    // Label b (base)
    textPainter.text = TextSpan(
      text: 'b',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.82));

    // Label c (hypotenuse)
    textPainter.text = TextSpan(
      text: 'c',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.55, size.height * 0.4));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TrapezoidPainter extends CustomPainter {
  final Color color;
  TrapezoidPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.35, size.height * 0.3) // Top Left
      ..lineTo(size.width * 0.65, size.height * 0.3) // Top Right
      ..lineTo(size.width * 0.85, size.height * 0.7) // Bottom Right
      ..lineTo(size.width * 0.15, size.height * 0.7) // Bottom Left
      ..close();

    canvas.drawPath(path, paint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Upper base a
    textPainter.text = TextSpan(
      text: 'a',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.22));

    // Lower base b
    textPainter.text = TextSpan(
      text: 'b',
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.72));

    // Height h
    final dashPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.3),
      Offset(size.width * 0.35, size.height * 0.7),
      dashPaint,
    );
    textPainter.text = TextSpan(
      text: 'h',
      style: TextStyle(color: color.withOpacity(0.7), fontSize: 14),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.28, size.height * 0.45));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PrismPainter extends CustomPainter {
  final Color color;
  PrismPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final w = size.width * 0.4;
    final h = size.height * 0.3;
    final d = size.width * 0.2;
    final ox = size.width * 0.25;
    final oy = size.height * 0.45;

    // Front
    canvas.drawRect(Rect.fromLTWH(ox, oy, w, h), paint);
    // Back
    canvas.drawRect(
      Rect.fromLTWH(ox + d, oy - d, w, h),
      paint..color = color.withOpacity(0.3),
    );
    // Connectors
    canvas.drawLine(Offset(ox, oy), Offset(ox + d, oy - d), paint);
    canvas.drawLine(Offset(ox + w, oy), Offset(ox + w + d, oy - d), paint);
    canvas.drawLine(Offset(ox, oy + h), Offset(ox + d, oy + h - d), paint);
    canvas.drawLine(
      Offset(ox + w, oy + h),
      Offset(ox + w + d, oy + h - d),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CurvePainter extends CustomPainter {
  final Color color;
  final bool isIntegral;
  CurvePainter(this.color, {this.isIntegral = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.8),
      axisPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.9),
      axisPaint,
    );

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.7,
      size.width * 0.8,
      size.height * 0.2,
    );
    canvas.drawPath(path, paint);

    if (isIntegral) {
      final fillPath = Path();
      fillPath.moveTo(size.width * 0.3, size.height * 0.8);
      fillPath.lineTo(size.width * 0.3, size.height * 0.7);
      fillPath.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.7,
        size.width * 0.7,
        size.height * 0.35,
      );
      fillPath.lineTo(size.width * 0.7, size.height * 0.8);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
    } else {
      // Tangent line for differentiation
      final tangentPaint = Paint()
        ..color = Colors.pinkAccent
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(size.width * 0.35, size.height * 0.8),
        Offset(size.width * 0.75, size.height * 0.4),
        tangentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NumberSystemPainter extends CustomPainter {
  final Color color;
  final String activeType;
  NumberSystemPainter(this.color, this.activeType);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw nested rectangles for hierarchy
    _drawNestedBox(
      canvas,
      centerX,
      centerY,
      size.width * 0.9,
      size.height * 0.9,
      'Complex',
      activeType == 'Complex',
    );
    _drawNestedBox(
      canvas,
      centerX,
      centerY,
      size.width * 0.75,
      size.height * 0.75,
      'Real',
      activeType == 'Real',
    );
    _drawNestedBox(
      canvas,
      centerX,
      centerY,
      size.width * 0.55,
      size.height * 0.55,
      'Rational',
      activeType == 'Rational',
    );
    _drawNestedBox(
      canvas,
      centerX,
      centerY,
      size.width * 0.35,
      size.height * 0.35,
      'Integer',
      activeType == 'Integer',
    );
    _drawNestedBox(
      canvas,
      centerX,
      centerY,
      size.width * 0.15,
      size.height * 0.15,
      'Natural',
      activeType == 'Natural',
    );
  }

  void _drawNestedBox(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    String label,
    bool isActive,
  ) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    final paint = Paint()
      ..color = isActive ? color : color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 3 : 1;

    canvas.drawRect(rect, paint);

    if (isActive) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isActive ? color : color.withOpacity(0.5),
          fontSize: 10,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(rect.left + 5, rect.top + 5));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FunctionPainter extends CustomPainter {
  final Color color;
  FunctionPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
      axisPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.9),
      axisPaint,
    );
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class EncyclopediaPage extends StatefulWidget {
  const EncyclopediaPage({super.key});

  @override
  State<EncyclopediaPage> createState() => _EncyclopediaPageState();
}

class _EncyclopediaPageState extends State<EncyclopediaPage> {
  late final List<EncyclopediaEntry> _primaryEntries;
  late final List<EncyclopediaEntry> _secondaryEntries;
  late final List<EncyclopediaEntry> _advancedEntries;
  late final List<EncyclopediaEntry> _numberSystemEntries;

  @override
  void initState() {
    super.initState();
    _initEntries();
  }

  void _initEntries() {
    _primaryEntries = [
      EncyclopediaEntry(
        name: 'Triangle Area',
        formula: 'A = ½bh',
        color: Colors.orangeAccent,
        definition: '삼각형의 넓이 구하기',
        explanation:
            '삼각형의 넓이는 밑변(b)과 높이(h)를 곱한 값의 절반입니다. 이는 삼각형이 동일한 밑변과 높이를 가진 평행사변형 넓이의 절반이기 때문입니다.',
        example: '밑변이 6cm이고 높이가 4cm인 삼각형의 넓이는 6 × 4 ÷ 2 = 12cm² 입니다.',
        history:
            '기원전 1550년경 작성된 고대 이집트의 린드 수학 파피루스에도 삼각형의 넓이를 구하는 방법이 기록되어 있습니다.',
        realLifeCase: '지붕의 면적을 구하거나, 땅의 넓이를 측량할 때 가장 기본적으로 사용되는 공식입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: TrianglePainter(Colors.orangeAccent),
        ),
      ),
      EncyclopediaEntry(
        name: 'Rectangle Area',
        formula: 'A = lw',
        color: Colors.blueAccent,
        definition: '직사각형의 넓이 구하기',
        explanation:
            '가로(l)와 세로(w)의 길이를 곱하여 넓이를 구합니다. 모든 칸의 개수를 세는 것과 같은 원리입니다.',
        example: '가로 5cm, 세로 3cm인 직사각형의 넓이는 5 × 3 = 15cm² 입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: RectanglePainter(Colors.blueAccent),
        ),
      ),
      EncyclopediaEntry(
        name: 'Average (Mean)',
        formula: 'Σx / n',
        color: Colors.greenAccent,
        definition: '평균 구하기',
        explanation: '여러 값들의 총합(Σx)을 값의 개수(n)로 나눈 값입니다. 자료 전체를 대표하는 값으로 쓰입니다.',
        example: '시험 점수가 80, 90, 70점일 때 평균은 (80+90+70) ÷ 3 = 80점입니다.',
      ),
      EncyclopediaEntry(
        name: 'Percentage',
        formula: 'rate × 100%',
        color: Colors.pinkAccent,
        definition: '백분율(퍼센트)',
        explanation: '전체 수량을 100으로 가정했을 때의 비율입니다. 비율에 100을 곱하여 구하며 % 기호를 붙입니다.',
        example: '10개 중 2개는 2 ÷ 10 × 100 = 20% 입니다.',
      ),
      EncyclopediaEntry(
        name: 'GCD (Greatest Common Divisor)',
        formula: 'GCD(a, b)',
        color: Colors.amberAccent,
        definition: '최대공약수',
        explanation:
            '두 수 이상의 공통된 약수 중 가장 큰 수입니다. 소인수분해를 하거나 거꾸로 나누기를 하여 구할 수 있습니다.',
        example: '12와 18의 최대공약수는 6입니다.',
      ),
      EncyclopediaEntry(
        name: 'LCM (Least Common Multiple)',
        formula: 'LCM(a, b)',
        color: Colors.lightBlueAccent,
        definition: '최소공배수',
        explanation:
            '두 수 이상의 공통된 배수 중 가장 작은 수입니다. 두 수의 곱을 최대공약수로 나누어 구할 수도 있습니다.',
        example: '12와 18의 최소공배수는 36입니다.',
      ),
      EncyclopediaEntry(
        name: 'Trapezoid Area',
        formula: 'A = (a+b)h / 2',
        color: Colors.orange,
        definition: '사다리꼴의 넓이',
        explanation:
            '윗변(a)과 아랫변(b)의 길이를 더한 후 높이(h)를 곱하고 2로 나눕니다. 사다리꼴 두 개를 붙이면 평행사변형이 되는 원리를 이용합니다.',
        example: '윗변 4, 아랫변 6, 높이 5인 사다리꼴의 넓이는 (4+6) × 5 ÷ 2 = 25입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: TrapezoidPainter(Colors.orange),
        ),
      ),
      EncyclopediaEntry(
        name: 'Prism Volume',
        formula: 'V = lwh',
        color: Colors.brown,
        definition: '직육면체의 부피',
        explanation:
            '가로(l), 세로(w), 높호(h)의 세 길이를 모두 곱하여 구합니다. 밑면의 넓이에 높이를 곱한 것과 같습니다.',
        example: '가로 5, 세로 4, 높이 3인 직육면체의 부피는 5 × 4 × 3 = 60입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: PrismPainter(Colors.brown),
        ),
      ),
      EncyclopediaEntry(
        name: 'Parallelogram Area',
        formula: 'A = bh',
        color: Colors.teal,
        definition: '평행사변형의 넓이',
        explanation:
            '밑변(b)의 길이에 높이(h)를 곱하여 구합니다. 평행사변형을 잘라 붙이면 직사각형이 되는 원리를 이용합니다.',
        example: '밑변이 8, 높이가 5인 평행사변형의 넓이는 8 × 5 = 40입니다.',
        history: '고대 바빌로니아 시대부터 토지 측량을 위해 사용된 아주 오래된 공식 중 하나입니다.',
        realLifeCase: '바닥 타일을 깔거나 건물의 단면적을 계산할 때 광범위하게 사용됩니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: ParallelogramPainter(Colors.teal),
        ),
      ),
      EncyclopediaEntry(
        name: 'Ratio & Proportion',
        formula: 'a:b = c:d',
        color: Colors.deepOrangeAccent,
        definition: '비와 비례식',
        explanation:
            '두 양의 크기를 비교한 비가 서로 같음을 나타내는 식입니다. 내항의 곱과 외항의 곱이 같다는 성질이 있습니다.',
        example: '1:2 = 3:x 일 때, 1 × x = 2 × 3 이므로 x = 6입니다.',
        history: '고대 그리스의 수학자 에우독소스가 정립한 비례론은 근대 수학의 밑거름이 되었습니다.',
        realLifeCase: '요리 레시피의 분량을 늘리거나, 지도의 축척을 보고 실제 거리를 계산할 때 필수적입니다.',
      ),
    ];

    _secondaryEntries = [
      EncyclopediaEntry(
        name: 'Prime Factorization',
        formula: 'n = p₁ᵃ × p₂ᵇ...',
        color: Colors.indigoAccent,
        definition: '소인수분해',
        explanation:
            '1보다 큰 자연수를 소수들만의 곱으로 나타내는 것입니다. 수를 완전히 분해하여 그 성질을 파악할 수 있게 해줍니다.',
        example: '60을 소인수분해하면 2² × 3 × 5 입니다.',
      ),
      EncyclopediaEntry(
        name: 'Linear Function',
        formula: 'y = ax + b',
        color: Colors.purpleAccent,
        definition: '일차함수',
        explanation:
            '변수 x의 차수가 1인 함수입니다. 그래프를 그리면 직선 형태가 되며, a는 기울기, b는 y절편을 뜻합니다.',
        example: 'y = 2x + 1 그래프는 기울기가 2이고 (0, 1)을 지나는 직선입니다.',
        history: '데카르트가 좌표평면을 도입하면서 대수적인 식과 기하학적인 직선을 연결하는 중요한 토대가 되었습니다.',
        realLifeCase:
            '택시 요금(기본요금 + 거리당 요금)이나 정기적인 저축액 계산 등 생활 속 변화를 예측할 때 쓰입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: FunctionPainter(Colors.purpleAccent),
        ),
      ),
      EncyclopediaEntry(
        name: 'Square Roots',
        formula: '√a × √b = √ab',
        color: Colors.tealAccent,
        definition: '제곱근의 계산',
        explanation:
            '제곱해서 a가 되는 수를 √a라고 합니다. 양수일 때 제곱근끼리의 곱은 루트 안의 숫자끼리 곱한 것과 같습니다.',
        example: '√2 × √3 = √6 입니다.',
      ),
      EncyclopediaEntry(
        name: 'Pythagorean',
        formula: 'a² + b² = c²',
        color: Colors.blueAccent,
        definition: '피타고라스 정리',
        explanation: '직각삼각형에서 직각을 낀 두 변의 제곱의 합은 빗변의 제곱과 같습니다.',
        example: '한 변이 3, 다른 변이 4인 직각삼각형의 빗변은 √(3²+4²) = 5입니다.',
        history:
            '피타고라스 학파가 증명했다고 알려져 있지만, 사실 고대 바빌로니아와 중국에서도 이미 알고 있었던 아주 오래된 정리입니다.',
        realLifeCase:
            '모니터의 크기(대각선 길이)를 계산하거나, 건축물에서 기둥의 높이와 그림자 길이를 이용해 거리를 잴 때 필수적입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: RightTrianglePainter(Colors.blueAccent),
        ),
      ),
      EncyclopediaEntry(
        name: 'Circle Area',
        formula: 'A = πr²',
        color: Colors.redAccent,
        definition: '원의 넓이',
        explanation: '반지름(r)의 제곱에 원주율(π)을 곱한 값입니다.',
        example: '반지름이 3cm인 원의 넓이는 3² × π = 9π cm² 입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: CirclePainter(Colors.redAccent),
        ),
      ),
      EncyclopediaEntry(
        name: 'Quadratic Formula',
        formula: 'x = \frac{-b ± sqrt{b²-4ac}}{2a}',
        color: Colors.amber,
        definition: '이차방정식의 근의 공식',
        explanation:
            '이차방정식 ax² + bx + c = 0의 해를 구하는 공식입니다. 어떤 이차방정식도 이 공식만 있으면 해를 구할 수 있습니다.',
        example: 'x² - 3x + 2 = 0 에서 a=1, b=-3, c=2이므로 대입하면 x=1 또는 x=2가 나옵니다.',
        history: '9세기 페르시아의 수학자 알 콰리즈미가 그의 저서에서 체계적으로 정리하여 유럽에 전파되었습니다.',
        realLifeCase:
            '물체의 포물선 운동(공 던지기, 분수)을 계산하거나 기업이 최대 이윤을 얻기 위한 가격을 책정할 때 쓰입니다.',
      ),
      EncyclopediaEntry(
        name: 'Distance Formula',
        formula: 'd = sqrt{(x₂-x₁)² + (y₂-y₁)²}',
        color: Colors.lightGreen,
        definition: '두 점 사이의 거리',
        explanation:
            '좌표평면 위에서 두 점 사이의 직선 거리를 구하는 공식입니다. 피타고라스 정리를 좌표로 옮겨놓은 것과 같습니다.',
        example:
            '(1,2)와 (4,6) 사이의 거리는 sqrt{(4-1)² + (6-2)²} = sqrt{3²+4²} = 5입니다.',
        history: '해석기하학의 창시자인 데카르트가 좌표를 도입하면서 이 공식도 널리 알려지게 되었습니다.',
        realLifeCase:
            'GPS 앱이 내 위치와 목적지 사이의 직선 거리를 계산하거나, 게임 캐릭터 간의 거리를 잴 때 사용됩니다.',
      ),
    ];

    _advancedEntries = [
      EncyclopediaEntry(
        name: 'Differentiation',
        formula: "f'(x) = dy/dx",
        color: Colors.pinkAccent,
        definition: '미분',
        explanation: '함수의 순간적인 변화율을 구하는 것입니다. 그래프에서는 특정 점에서의 접선의 기울기를 의미합니다.',
        example: "f(x) = x² 일 때 f'(x) = 2x 입니다.",
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: CurvePainter(Colors.pinkAccent),
        ),
      ),
      EncyclopediaEntry(
        name: 'Integration',
        formula: '∫ f(x) dx',
        color: Colors.cyanAccent,
        definition: '적분',
        explanation: '미분의 역연산으로, 함수 아래의 넓이를 구하는 과정입니다. 작은 양들을 무한히 더해가는 개념입니다.',
        example: 'f(x) = 2x 일 때 ∫ 2x dx = x² + C 입니다.',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: CurvePainter(Colors.cyanAccent, isIntegral: true),
        ),
      ),
      EncyclopediaEntry(
        name: 'Euler\'s Identity',
        formula: 'e^{iπ} + 1 = 0',
        color: Colors.orange,
        definition: '오일러 항등식',
        explanation:
            '수학의 가장 중요한 다섯 가지 상수(e, i, π, 1, 0)를 하나의 아름다운 식으로 연결한 공식입니다.',
        example: '계산보다는 그 자체의 조화로움과 수학적 증명 과정에서 큰 의미를 갖습니다.',
        history:
            '수학자 레온하르트 오일러가 발견했으며, "세상에서 가장 아름다운 공식" 투표에서 압도적 1위를 지키고 있습니다.',
        realLifeCase: '교류 회로 분석, 양자역학, 신호 처리 등 현대 전기/전자 공학의 핵심적인 계산 도구로 쓰입니다.',
      ),
      EncyclopediaEntry(
        name: 'Logarithm Rules',
        formula: 'log(ab) = log a + log b',
        color: Colors.deepPurpleAccent,
        definition: '로그의 성질',
        explanation:
            '곱셈을 덧셈으로 바꾸어 계산을 단순화할 수 있는 성질입니다. 매우 큰 수나 아주 작은 수를 다룰 때 유용합니다.',
        example: 'log(10 × 100) = log 10 + log 100 = 1 + 2 = 3 입니다.',
        history: '천문학자들의 방대한 계산을 돕기 위해 존 네이피어가 소수점을 도입하며 함께 발명했습니다.',
        realLifeCase:
            '지진의 강도(리히터 규모), 소리의 크기(데시벨), 산성도(pH) 등 폭발적인 변화를 나타내는 척도로 사용됩니다.',
      ),
    ];

    _numberSystemEntries = [
      EncyclopediaEntry(
        name: 'Natural Numbers',
        formula: 'ℕ = {1, 2, 3, ...}',
        color: Colors.lightGreenAccent,
        definition: '자연수',
        explanation:
            '사물의 개수를 셀 때 사용하는 가장 기본적인 수입니다. 1부터 시작하여 1씩 커지는 수들의 집합입니다.',
        example: '1, 2, 100, 1024 등',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: NumberSystemPainter(Colors.lightGreenAccent, 'Natural'),
        ),
      ),
      EncyclopediaEntry(
        name: 'Integers',
        formula: 'ℤ = {..., -1, 0, 1, ...}',
        color: Colors.limeAccent,
        definition: '정수',
        explanation:
            '자연수(양의 정수), 0, 그리고 자연수에 마이너스 부호를 붙인 음의 정수를 모두 통틀어 일컫는 말입니다.',
        example: '-5, 0, 7 등',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: NumberSystemPainter(Colors.limeAccent, 'Integer'),
        ),
      ),
      EncyclopediaEntry(
        name: 'Rational Numbers',
        formula: 'ℚ = {a/b | a,b∈ℤ, b≠0}',
        color: Colors.cyanAccent,
        definition: '유리수',
        explanation:
            '두 정수의 비율(분수)로 나타낼 수 있는 수입니다. 소수로 나타내면 유한소수이거나 순환하는 무한소수가 됩니다.',
        example: '1/2, 0.75, -3, 0.333... 등',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: NumberSystemPainter(Colors.cyanAccent, 'Rational'),
        ),
      ),
      EncyclopediaEntry(
        name: 'Irrational Numbers',
        formula: 'x ∉ ℚ',
        color: Colors.orangeAccent,
        definition: '무리수',
        explanation: '유리수가 아닌 실수로, 분수로 나타낼 수 없는 수입니다. 순환하지 않는 무한소수 형태를 띱니다.',
        example: '√2, π(원주율), e(자연상수) 등',
      ),
      EncyclopediaEntry(
        name: 'Real Numbers',
        formula: 'ℝ = ℚ ∪ 무리수',
        color: Colors.blueAccent,
        definition: '실수',
        explanation:
            '유리수와 무리수를 통틀어 일컫는 말로, 수직선 위의 모든 점에 대응되는 수입니다. 우리가 실제로 사용하는 대부분의 수입니다.',
        example: '-1, 0.5, √3, π 등',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: NumberSystemPainter(Colors.blueAccent, 'Real'),
        ),
      ),
      EncyclopediaEntry(
        name: 'Complex Numbers',
        formula: 'ℂ = {a + bi | a,b∈ℝ}',
        color: Colors.purpleAccent,
        definition: '복소수 / 허수',
        explanation:
            '실수와 허수(i = √-1)를 포함하는 가장 넓은 범위의 수입니다. 허수는 제곱해서 -1이 되는 상상의 수입니다.',
        example: '2 + 3i, 5i (순허수) 등',
        diagram: CustomPaint(
          size: const Size(200, 150),
          painter: NumberSystemPainter(Colors.purpleAccent, 'Complex'),
        ),
      ),
    ];
  }

  static const String _pi100 =
      '3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679';

  bool _isPiExpanded = false;

  void _showEntryDetail(EncyclopediaEntry entry) {
    bool isPi = entry.name == 'Pi (π)';
    _isPiExpanded = false; // Reset on open

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.definition,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: entry.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
                      const SizedBox(height: 32),
                      if (entry.diagram != null) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: entry.diagram,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection(
                            '공식',
                            (isPi && _isPiExpanded)
                                ? 'π ≈ $_pi100'
                                : entry.formula,
                            isFormula: true,
                          ),
                          if (isPi) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _isPiExpanded = !_isPiExpanded;
                                });
                              },
                              icon: Icon(
                                _isPiExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 18,
                                color: entry.color,
                              ),
                              label: Text(
                                _isPiExpanded ? '접기' : '더보기 (100자리)',
                                style: TextStyle(
                                  color: entry.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection('설명', entry.explanation),
                      const SizedBox(height: 24),
                      _buildDetailSection('적용 예시', entry.example),
                      if (entry.history != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          '역사와 유래',
                          entry.history!,
                          accentColor: Colors.amberAccent,
                        ),
                      ],
                      if (entry.realLifeCase != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          '실생활 적용',
                          entry.realLifeCase!,
                          accentColor: Colors.lightGreenAccent,
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String content, {
    bool isFormula = false,
    Color? accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: accentColor?.withOpacity(0.7) ?? Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: isFormula ? 24 : 16,
            fontWeight: isFormula ? FontWeight.w900 : FontWeight.normal,
            color: isFormula
                ? AppColors.accent
                : (accentColor ?? AppColors.textBody),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeId = userProvider.currentTheme;
    final config = AppThemes.configs[themeId] ?? AppThemes.configs['Default']!;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Math Encyclopedia'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Fundamental Constants', accent),
                  const SizedBox(height: 16),
                  _buildPiCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Primary Level (초등 과정)', accent),
                  const SizedBox(height: 16),
                  _buildFormulaGrid(_primaryEntries),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Secondary Level (중등 과정)', accent),
                  const SizedBox(height: 16),
                  _buildFormulaGrid(_secondaryEntries),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Advanced Level (고등 과정)', accent),
                  const SizedBox(height: 16),
                  _buildFormulaGrid(_advancedEntries),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Number Systems (수 체계)', accent),
                  const SizedBox(height: 16),
                  _buildFormulaGrid(_numberSystemEntries),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Interactive Tools', accent),
                  const SizedBox(height: 16),
                  _buildVisualizerCard(),
                  const SizedBox(height: 16),
                  _buildUnitCircleCard(),
                  const SizedBox(height: 16),
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildGeometryCard(),
                  const SizedBox(height: 16),
                  const _buildFactorialCardWidget(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: accent,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildUnitCircleCard() {
    final primary = Colors.pinkAccent;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UnitCirclePage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.architecture_rounded, color: primary, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit Circle Visualizer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '삼각함수(sin, cos, tan)의 원리를 시각화합니다.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    const primary = Colors.cyanAccent;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StatisticsVisualizerPage(),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart_rounded, color: primary, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics Simulator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '주사위 던지기 실험을 통해 확률과 분포를 이해합니다.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeometryCard() {
    final primary = Colors.orangeAccent;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GeometryPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.category_rounded, color: primary, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geometry Shaper',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '도형의 꼭짓점을 드래그하여 넓이 변화를 관찰하세요.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizerCard() {
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VisualizerPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.show_chart_rounded, color: primary, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive Visualizer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '함수의 그래프를 직접 조작하며 관찰해보세요.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: primary.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPiCard() {
    return GestureDetector(
      onTap: () {
        _showEntryDetail(
          EncyclopediaEntry(
            name: 'Pi (π)',
            formula: 'π ≈ 3.14159...',
            color: Colors.orangeAccent,
            definition: '원주율',
            explanation:
                '원의 지름에 대한 원주의 비율입니다. 모든 원에서 일정하며 소수점 아래가 무한히 반복되지 않고 이어지는 무리수입니다.',
            example: '반지름이 5cm인 원의 둘레는 2 × 5 × π = 10π cm 입니다.',
            history: '아르키메데스는 원에 내접/외접하는 다각형을 이용해 π의 값을 매우 정확하게 계산해냈습니다.',
            realLifeCase:
                '바퀴의 회전 거리 계산, 우주비행체 궤도 설계, 소리나 빛의 파동 분석 등 거의 모든 현대 과학 기술에 쓰입니다.',
            diagram: CustomPaint(
              size: const Size(200, 150),
              painter: CirclePainter(Colors.orangeAccent),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color?.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text(
                'π',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archimedes\' Constant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '3.14159...',
                    style: TextStyle(color: AppColors.textBody),
                  ),
                ],
              ),
            ),
            const Icon(Icons.info_outline, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaGrid(List<EncyclopediaEntry> entries) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return GestureDetector(
          onTap: () => _showEntryDetail(entry),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: entry.color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: entry.color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  entry.formula,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _buildFactorialCardWidget extends StatelessWidget {
  const _buildFactorialCardWidget();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high_rounded, color: accent),
              const SizedBox(width: 12),
              Text(
                'Factorial Calculator (n!)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _FactorialMiniCalc(),
        ],
      ),
    );
  }
}

class _FactorialMiniCalc extends StatefulWidget {
  const _FactorialMiniCalc();

  @override
  State<_FactorialMiniCalc> createState() => _FactorialMiniCalcState();
}

class _FactorialMiniCalcState extends State<_FactorialMiniCalc> {
  final TextEditingController _controller = TextEditingController();
  String _result = '?';

  void _calculate() {
    final val = int.tryParse(_controller.text);
    if (val != null && val >= 0 && val <= 20) {
      double res = 1;
      for (int i = 1; i <= val; i++) res *= i;
      setState(() {
        _result = res.toStringAsFixed(0);
      });
    } else if (val != null) {
      MathDialog.show(
        context,
        title: 'Range Error',
        message: 'Enter 0-20 to avoid heavy calculations.',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final accent = Theme.of(context).colorScheme.secondary;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'n = ?',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.3),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _calculate,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('n!'),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _result,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
