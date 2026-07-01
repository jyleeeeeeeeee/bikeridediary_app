import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../banking_theme.dart';

/// 자동차 타코미터 스타일 반원 게이지.
/// -90°(왼쪽) ─ 0°(상단) ─ +90°(오른쪽) 범위, 30° 간격 메이저 눈금.
class TachometerGauge extends StatelessWidget {
  final double angle; // -90 ~ +90 (음수 = 좌측 뱅킹)
  final double maxLeft; // 음수
  final double maxRight; // 양수

  const TachometerGauge({
    super.key,
    required this.angle,
    required this.maxLeft,
    required this.maxRight,
  });

  @override
  Widget build(BuildContext context) {
    final color = bankingZoneColor(angle.abs());

    return Card(
      color: BankingColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2.0,
              child: CustomPaint(
                painter: _TachometerPainter(
                  angle: angle,
                  maxLeft: maxLeft,
                  maxRight: maxRight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  angle.abs().toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '°',
                  style: TextStyle(color: color, fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _TachometerPainter extends CustomPainter {
  final double angle;
  final double maxLeft;
  final double maxRight;

  _TachometerPainter({
    required this.angle,
    required this.maxLeft,
    required this.maxRight,
  });

  /// 게이지 각도(-90~+90) → canvas radian.
  /// -90 → π (왼쪽), 0 → -π/2 (위), +90 → 0 (오른쪽)
  double _toRadian(double deg) => (deg / 90) * (math.pi / 2) - math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = math.min(size.width / 2, size.height) * 0.92;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final needleTipDist = (radius - 28) * 2 / 3;

    _drawZones(canvas, arcRect);
    _drawTicks(canvas, center, radius, needleTipDist);
    _drawMaxMarker(canvas, center, radius, maxLeft, bankingZoneColor(maxLeft.abs()));
    _drawMaxMarker(canvas, center, radius, maxRight, bankingZoneColor(maxRight.abs()));
    _drawNeedle(canvas, center, needleTipDist);
    _drawPivot(canvas, center);
  }

  void _drawZones(Canvas canvas, Rect rect) {
    final bg = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, math.pi, math.pi, false, bg);

    const gradient = SweepGradient(
      startAngle: math.pi,
      endAngle: math.pi * 2,
      colors: [
        BankingColors.danger,
        BankingColors.danger,
        BankingColors.orange,
        BankingColors.yellow,
        BankingColors.success,
        BankingColors.yellow,
        BankingColors.orange,
        BankingColors.danger,
        BankingColors.danger,
      ],
      stops: [0.0, 0.25, 1 / 3, 5 / 12, 0.5, 7 / 12, 2 / 3, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, math.pi, math.pi, false, paint);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius, double needleTipDist) {
    final minor = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2;
    final major = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2;

    for (int deg = -90; deg <= 90; deg += 5) {
      final rad = _toRadian(deg.toDouble());
      final isMajor = deg % 30 == 0;
      final dir = Offset(math.cos(rad), math.sin(rad));
      final outer = center + dir * (radius - 32);
      final inner = center + dir * needleTipDist;
      canvas.drawLine(inner, outer, isMajor ? major : minor);

      if (isMajor) {
        final labelPos = center + dir * (radius - 16);
        final tp = TextPainter(
          text: TextSpan(
            text: deg.abs().toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _drawMaxMarker(
      Canvas canvas, Offset center, double radius, double markerAngle, Color color) {
    if (markerAngle.abs() < 0.5) return;
    final clamped = markerAngle.clamp(-90.0, 90.0);
    final rad = _toRadian(clamped);
    final dir = Offset(math.cos(rad), math.sin(rad));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + dir * (radius - 38),
      center + dir * (radius - 18),
      paint,
    );
  }

  void _drawNeedle(Canvas canvas, Offset center, double tipDistance) {
    final clamped = angle.clamp(-90.0, 90.0);
    final rad = _toRadian(clamped);
    final dir = Offset(math.cos(rad), math.sin(rad));
    final tip = center + dir * tipDistance;

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(center, tip, shadow);

    final needle = Paint()
      ..color = BankingColors.danger
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, needle);
  }

  void _drawPivot(Canvas canvas, Offset center) {
    canvas.drawCircle(
        center, 12, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(center, 6, Paint()..color = BankingColors.bgCard);
  }

  @override
  bool shouldRepaint(covariant _TachometerPainter old) =>
      old.angle != angle ||
      old.maxLeft != maxLeft ||
      old.maxRight != maxRight;
}
