import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({this.compact = false, super.key});

  final bool compact;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: widget.compact ? 124 : 164,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _PulseHalo(value: value),
                  Transform.rotate(
                    angle: value * math.pi * 2,
                    child: CustomPaint(
                      size: Size.square(widget.compact ? 104 : 136),
                      painter: _RingPainter(progress: value),
                    ),
                  ),
                  _LogoBadge(value: value),
                ],
              ),
            ),
            SizedBox(height: widget.compact ? 18 : 26),
            Text(
              context.tr('Preparing HRU ATMS'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.surface,
                fontSize: widget.compact ? 18 : 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Loading your academic workspace'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: widget.compact ? 12.5 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            _LoadingDots(value: value),
          ],
        );
      },
    );

    if (widget.compact) {
      return Center(child: content);
    }

    return ColoredBox(
      color: const Color(0xFF020617),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _GridBackdrop(),
          Center(
            child: Padding(padding: const EdgeInsets.all(24), child: content),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final scale = 1 + math.sin(value * math.pi * 2) * 0.035;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandTeal.withValues(alpha: 0.34),
              blurRadius: 34,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: AppColors.brandBlue.withValues(alpha: 0.32),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'HRU',
            style: TextStyle(
              color: AppColors.brandBlue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseHalo extends StatelessWidget {
  const _PulseHalo({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + math.sin(value * math.pi * 2) * 0.5;
    return Container(
      width: 150 + (pulse * 18),
      height: 150 + (pulse * 18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.brandBlue.withValues(alpha: 0.28),
            AppColors.brandTeal.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final phase = (value + index * 0.18) % 1;
        final opacity = 0.35 + (math.sin(phase * math.pi * 2) + 1) * 0.32;
        final lift = math.sin(phase * math.pi * 2) * 4;
        return Transform.translate(
          offset: Offset(0, -lift),
          child: Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Color.lerp(
                AppColors.brandBlue,
                AppColors.brandTeal,
                index / 2,
              )!.withValues(alpha: opacity.clamp(0.3, 1)),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _GridBackdrop extends StatelessWidget {
  const _GridBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackdropPainter());
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - 7;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: const [
          AppColors.brandBlue,
          AppColors.brandTeal,
          Colors.white,
          AppColors.brandBlue,
        ],
        stops: const [0, 0.42, 0.72, 1],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.38,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 34.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.brandBlue.withValues(alpha: 0.22),
              AppColors.brandTeal.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.42),
              radius: size.shortestSide * 0.72,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
