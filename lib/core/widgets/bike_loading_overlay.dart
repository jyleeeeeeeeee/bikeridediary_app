import 'dart:math';
import 'package:flutter/material.dart';

/// API 호출 시 반투명 오버레이 + 도트 바이크 애니메이션
/// 바이크가 위아래로 출렁이며, 바람 선과 배기 연기가 표시된다.
class BikeLoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const BikeLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  State<BikeLoadingOverlay> createState() => _BikeLoadingOverlayState();
}

class _BikeLoadingOverlayState extends State<BikeLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _particleController;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [_bounceController, _particleController]),
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _RidingEffectPainter(
                              particleProgress: _particleController.value,
                            ),
                            child: Transform.translate(
                              offset: Offset(0, _bounceAnim.value),
                              child: child,
                            ),
                          );
                        },
                        child: Center(
                          child: Transform.flip(
                            flipX: true,
                            child: const Text(
                              '🏍️',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '로딩 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RidingEffectPainter extends CustomPainter {
  final double particleProgress;
  final _random = Random(42);

  _RidingEffectPainter({required this.particleProgress});

  @override
  void paint(Canvas canvas, Size size) {
    _drawWindLines(canvas, size);
    _drawExhaustSmoke(canvas, size);
  }

  void _drawWindLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 6; i++) {
      final seed = _random.nextDouble();
      final progress = (particleProgress + seed) % 1.0;
      final opacity = progress < 0.3
          ? progress / 0.3
          : progress > 0.7
              ? (1.0 - progress) / 0.3
              : 1.0;

      paint.color = Colors.white.withValues(alpha: opacity * 0.6);

      final y = size.height * (0.2 + seed * 0.5);
      final startX = size.width * 0.85 - progress * size.width * 1.3;
      final length = 15 + seed * 30;

      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + length, y),
        paint,
      );
    }
  }

  void _drawExhaustSmoke(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final seed = _random.nextDouble();
      final progress = (particleProgress + seed * 0.4) % 1.0;
      final opacity = (1.0 - progress) * 0.45;

      paint.color = Colors.white.withValues(alpha: opacity);

      final radius = 3 + progress * 10;
      final x = size.width * 0.12 - progress * 50;
      final y = size.height * 0.6 + seed * 20 + progress * 12;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RidingEffectPainter oldDelegate) =>
      oldDelegate.particleProgress != particleProgress;
}
