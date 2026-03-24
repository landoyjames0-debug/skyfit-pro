import 'package:flutter/material.dart';
import 'dart:math' as math;

/// SkyFitLogo — Animated fitness logo that matches SkyFit Pro's design system.
///
/// Usage:
///   SkyFitLogo()                      // default animated, size 88
///   SkyFitLogo(size: 60)              // smaller variant
///   SkyFitLogo(animated: false)       // static (for performance)
///   SkyFitLogo(showText: true)        // with "SkyFit Pro" wordmark
///   SkyFitLogo(showText: true, showTagline: true)  // full lockup
class SkyFitLogo extends StatefulWidget {
  final double size;
  final bool animated;
  final bool showText;
  final bool showTagline;

  const SkyFitLogo({
    super.key,
    this.size = 88,
    this.animated = true,
    this.showText = false,
    this.showTagline = false,
  });

  @override
  State<SkyFitLogo> createState() => _SkyFitLogoState();
}

class _SkyFitLogoState extends State<SkyFitLogo> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.animated) {
      _pulseController.repeat(reverse: true);
      _rotateController.repeat();
      _shimmerController.repeat(reverse: false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoMark(),
        if (widget.showText) ...[
          SizedBox(height: widget.size * 0.18),
          _buildWordmark(),
        ],
        if (widget.showTagline && widget.showText) ...[
          const SizedBox(height: 6),
          _buildTagline(),
        ],
      ],
    );
  }

  Widget _buildLogoMark() {
    final double padding = widget.size * 0.55;
    final double totalSize = widget.size + padding;

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pulseController, _rotateController, _shimmerController]),
      builder: (context, child) {
        final pulseVal = _pulseAnim.value;
        final glowOpacity = 0.28 + (pulseVal * 0.22);

        return SizedBox(
          width: totalSize,
          height: totalSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Outer glow ring ──────────────────────────────
              Container(
                width: totalSize,
                height: totalSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D4FF).withValues(alpha: glowOpacity),
                      const Color(0xFF7B61FF)
                          .withValues(alpha: glowOpacity * 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // ── Rotating orbit ring ──────────────────────────
              Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 1.15, widget.size * 1.15),
                  painter: _OrbitRingPainter(),
                ),
              ),

              // ── Main circle ──────────────────────────────────
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF)
                          .withValues(alpha: 0.3 + pulseVal * 0.2),
                      blurRadius: 20 + pulseVal * 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7B61FF)
                          .withValues(alpha: 0.2 + pulseVal * 0.15),
                      blurRadius: 30,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shimmer overlay
                    ClipOval(
                      child: AnimatedBuilder(
                        animation: _shimmerAnim,
                        builder: (_, __) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_shimmerAnim.value - 1, -1),
                              end: Alignment(_shimmerAnim.value, 1),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fitness icon
                    Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
                      size: widget.size * 0.46,
                      shadows: const [
                        // FIX: was using Shadow() with non-const — now const-safe
                        Shadow(
                          color: Colors.white,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Floating orbit dots ──────────────────────────
              ...List.generate(6, (i) {
                final angle = (i / 6) * 2 * math.pi +
                    _rotateController.value * 2 * math.pi * 0.3;
                final radius = widget.size * 0.58;
                final x = math.cos(angle) * radius;
                final y = math.sin(angle) * radius;
                final dotOpacity = (0.3 +
                        math.sin(_pulseController.value * math.pi * 2 +
                                i * math.pi / 3) *
                            0.3)
                    .clamp(0.0, 1.0); // FIX: clamp to valid opacity range
                return Positioned(
                  left: totalSize / 2 + x - 3,
                  top: totalSize / 2 + y - 3,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i % 2 == 0
                          ? const Color(0xFF00D4FF)
                              .withValues(alpha: dotOpacity)
                          : const Color(0xFF7B61FF)
                              .withValues(alpha: dotOpacity),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordmark() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
      ).createShader(bounds),
      child: Text(
        'SkyFit Pro',
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.38,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'YOUR PERSONALIZED FITNESS COMPANION',
      style: TextStyle(
        color: const Color(0xFF6B7280),
        fontSize: widget.size * 0.11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.5,
      ),
    );
  }
}

/// Paints a dashed orbit ring with tick marks
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashCount = 32;
    const gapFraction = 0.4;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      const sweepAngle = (1 - gapFraction) / dashCount * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    final tickPaint = Paint()
      ..color = const Color(0xFF7B61FF).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi;
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 5),
        center.dy + math.sin(angle) * (radius + 5),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) => false;
}
