import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool isActive;

  const ConfettiOverlay({super.key, required this.isActive});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _pieces = [];
  final Random _random = Random();

  static const _confettiColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
    AppColors.skyBlue,
    AppColors.pinkAccent,
    AppColors.star,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.addListener(() {
      setState(() {
        for (final piece in _pieces) {
          piece.update(_controller.value);
        }
      });
    });

    if (widget.isActive) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _pieces.clear();
    for (int i = 0; i < 60; i++) {
      _pieces.add(_ConfettiPiece(
        color: _confettiColors[_random.nextInt(_confettiColors.length)],
        startX: _random.nextDouble(),
        startDelay: _random.nextDouble() * 0.4,
        speed: 0.4 + _random.nextDouble() * 0.6,
        size: 6 + _random.nextDouble() * 8,
        isCircle: _random.nextBool(),
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        driftX: (_random.nextDouble() - 0.5) * 0.2,
      ));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_pieces, _controller.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ConfettiPiece {
  final Color color;
  final double startX;
  final double startDelay;
  final double speed;
  final double size;
  final bool isCircle;
  final double rotationSpeed;
  final double driftX;

  double currentY = -0.05;
  double currentX = 0;
  double rotation = 0;
  double opacity = 1.0;

  _ConfettiPiece({
    required this.color,
    required this.startX,
    required this.startDelay,
    required this.speed,
    required this.size,
    required this.isCircle,
    required this.rotationSpeed,
    required this.driftX,
  }) {
    currentX = startX;
  }

  void update(double t) {
    final adjustedT = (t - startDelay).clamp(0.0, 1.0);
    currentY = adjustedT * speed;
    currentX = startX + driftX * adjustedT;
    rotation = adjustedT * rotationSpeed * 3.14159;
    opacity = adjustedT > 0.7 ? 1.0 - (adjustedT - 0.7) / 0.3 : 1.0;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  const _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      if (piece.opacity <= 0 || piece.currentY < 0) continue;

      final paint = Paint()
        ..color = piece.color.withOpacity(piece.opacity)
        ..style = PaintingStyle.fill;

      final x = piece.currentX * size.width;
      final y = piece.currentY * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation);

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.6,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
