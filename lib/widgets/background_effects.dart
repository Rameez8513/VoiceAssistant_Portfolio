import 'dart:math' as math;
import 'package:flutter/material.dart';

class BackgroundEffects extends StatelessWidget {
  final bool isDark;
  final AnimationController controller;

  const BackgroundEffects({
    super.key,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPainter(
              progress: controller.value,
              color: colorScheme.primary,
              isDark: isDark,
            ),
            size: size,
          );
        },
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _BackgroundPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(isDark ? 0.03 : 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final center1 = Offset(
      size.width * 0.8 + math.sin(progress * math.pi * 2) * 30,
      size.height * 0.2 + math.cos(progress * math.pi * 2) * 20,
    );

    final center2 = Offset(
      size.width * 0.2 + math.cos(progress * math.pi * 2) * 20,
      size.height * 0.8 + math.sin(progress * math.pi * 2) * 30,
    );

    canvas.drawCircle(center1, size.width * 0.4, paint);
    canvas.drawCircle(center2, size.width * 0.3, paint);
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}
