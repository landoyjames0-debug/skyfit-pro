import 'package:flutter/material.dart';
import 'dart:math' as math;

// ════════════════════════════════════════════════════════════════════
//  SkyFitAnimations — Reusable micro-animation widgets for SkyFit Pro
//  Drop these in anywhere across LoginView, RegisterView, HomeView
// ════════════════════════════════════════════════════════════════════

// ── 1. Animated Gradient Button ──────────────────────────────────────
/// Press-to-scale gradient button matching SkyFit Pro's Sign In / Register.
///
/// Usage:
///   SkyFitAnimatedButton(
///     label: 'Sign In',
///     onTap: _onLoginPressed,
///     isLoading: authVM.isLoading,
///     gradientColors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
///   )
class SkyFitAnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final List<Color> gradientColors;
  final double height;
  final double borderRadius;
  final Widget? leadingIcon;

  const SkyFitAnimatedButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.gradientColors = const [Color(0xFF00D4FF), Color(0xFF7B61FF)],
    this.height = 54,
    this.borderRadius = 16,
    this.leadingIcon,
  });

  @override
  State<SkyFitAnimatedButton> createState() => _SkyFitAnimatedButtonState();
}

class _SkyFitAnimatedButtonState extends State<SkyFitAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  bool get _isInactive => widget.isDisabled || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isInactive) _pressCtrl.forward();
      },
      onTapUp: (_) {
        _pressCtrl.reverse();
        if (!_isInactive) widget.onTap?.call();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: _isInactive
                ? const LinearGradient(
                    colors: [Color(0xFF374151), Color(0xFF374151)])
                : LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: _isInactive
                ? []
                : [
                    BoxShadow(
                      color: widget.gradientColors.first.withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!_isInactive)
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_shimmer.value - 0.5, 0),
                          end: Alignment(_shimmer.value + 0.5, 0),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.leadingIcon != null) ...[
                          widget.leadingIcon!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2. Staggered List Item ────────────────────────────────────────────
/// Wraps any widget with a staggered fade+slide entrance.
/// Use on activity cards or lists in HomeView.
///
/// Usage:
///   StaggeredListItem(index: index, child: ActivityCard(...))
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 60),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.baseDelay * (widget.index % 8), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── 3. Pulse Badge ────────────────────────────────────────────────────
/// Fitness/weather badge with a gentle breathing glow.
///
/// Usage:
///   SkyFitPulseBadge(label: 'Weather-Powered', icon: Icons.bolt_rounded)
///   SkyFitPulseBadge(label: 'AES-256', icon: Icons.lock_rounded, color: Color(0xFF7B61FF))
class SkyFitPulseBadge extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;

  const SkyFitPulseBadge({
    super.key,
    required this.label,
    this.icon = Icons.bolt_rounded,
    this.color = const Color(0xFF00D4FF),
  });

  @override
  State<SkyFitPulseBadge> createState() => _SkyFitPulseBadgeState();
}

class _SkyFitPulseBadgeState extends State<SkyFitPulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08 + _glow.value * 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.25 + _glow.value * 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.08 + _glow.value * 0.1),
              blurRadius: 8 + _glow.value * 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: 12),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4. Animated Counter ───────────────────────────────────────────────
/// Counts up from 0 to [value] with a smooth tween.
/// Use in HomeView stats bar to animate Age / Weight / etc.
///
/// Usage:
///   AnimatedCounter(value: user.age, color: Color(0xFF00D4FF))
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Color color;
  final double fontSize;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.color,
    this.fontSize = 20,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _countAnim;
  int _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _countAnim = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prevValue = old.value;
      _countAnim = Tween<double>(
        begin: _prevValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _countAnim,
      builder: (_, __) => Text(
        _countAnim.value.toInt().toString(),
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── 5. Typewriter Text ────────────────────────────────────────────────
/// Reveals text character by character.
/// Use for "Welcome Back", "Your Fitness Journey", headers etc.
///
/// Usage:
///   TypewriterText('Welcome Back', style: TextStyle(color: Colors.white, ...))
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration charDuration;
  final Duration startDelay;

  const TypewriterText(
    this.text, {
    super.key,
    required this.style,
    this.charDuration = const Duration(milliseconds: 40),
    this.startDelay = Duration.zero,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    final totalDuration = widget.charDuration * widget.text.length;
    _ctrl = AnimationController(vsync: this, duration: totalDuration);
    _charCount = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
    Future.delayed(widget.startDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (_, __) => Text(
        widget.text.substring(0, _charCount.value),
        style: widget.style,
      ),
    );
  }
}

// ── 6. Shake Widget ───────────────────────────────────────────────────
/// Wraps a child with a horizontal shake on form errors.
///
/// Usage:
///   ShakeWidget(
///     shake: authVM.errorMessage != null,
///     child: _buildGlassCard(...),
///   )
class ShakeWidget extends StatefulWidget {
  final bool shake;
  final Widget child;

  const ShakeWidget({
    super.key,
    required this.shake,
    required this.child,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(ShakeWidget old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final offset = math.sin(_anim.value * math.pi * 5) * 8;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ── 7. Reveal On Mount ────────────────────────────────────────────────
/// Fade + slide entrance animation that plays once when widget mounts.
///
/// Usage:
///   RevealOnMount(
///     delay: Duration(milliseconds: 200),
///     child: _buildGlassCard(...),
///   )
class RevealOnMount extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const RevealOnMount({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.beginOffset = const Offset(0, 0.12),
  });

  @override
  State<RevealOnMount> createState() => _RevealOnMountState();
}

class _RevealOnMountState extends State<RevealOnMount>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
