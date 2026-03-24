import 'package:flutter/material.dart';
import 'dart:math' as math;

/// SkyFitTransitions — Drop-in page transitions for SkyFit Pro.
///
/// HOW TO USE:
///
/// Option A — Direct push:
///   Navigator.push(context, SkyFitPageRoute(page: const LoginView()));
///   Navigator.push(context, SkyFitPageRoute(page: const HomeView(),
///       style: SkyFitTransitionStyle.fadeScale));
///
/// Option B — Navigator extension (cleanest):
///   Navigator.of(context).pushSkyFit(const HomeView());
///   Navigator.of(context).pushReplacementSkyFit(const LoginView());
///
/// Option C — In your MaterialApp onGenerateRoute:
///   onGenerateRoute: SkyFitRouteFactory.generate,
///   // Then register routes in main():
///   SkyFitRouteFactory.register('/home', (_) => const HomeView());
///   SkyFitRouteFactory.register('/login', (_) => const LoginView(),
///       style: SkyFitTransitionStyle.fadeScale);

// ── Transition styles ────────────────────────────────────────────────
enum SkyFitTransitionStyle {
  /// Slides up with a sky-blue shimmer flash — main transition
  shimmerSlideUp,

  /// Fades + scales in — for modals and profile
  fadeScale,

  /// Slides in from the right with a cyan leading edge
  shimmerSlideRight,

  /// Reveals from center with expanding circle clip — for post-login
  circularReveal,
}

// ── Custom PageRoute ─────────────────────────────────────────────────
class SkyFitPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SkyFitTransitionStyle style;

  SkyFitPageRoute({
    required this.page,
    this.style = SkyFitTransitionStyle.shimmerSlideUp,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
                style, animation, secondaryAnimation, child);
          },
        );

  static Widget _buildTransition(
    SkyFitTransitionStyle style,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (style) {
      case SkyFitTransitionStyle.shimmerSlideUp:
        return _ShimmerSlideUpTransition(animation: animation, child: child);
      case SkyFitTransitionStyle.fadeScale:
        return _FadeScaleTransition(animation: animation, child: child);
      case SkyFitTransitionStyle.shimmerSlideRight:
        return _ShimmerSlideRightTransition(animation: animation, child: child);
      case SkyFitTransitionStyle.circularReveal:
        return _CircularRevealTransition(animation: animation, child: child);
    }
  }
}

// ── Shimmer Slide Up ─────────────────────────────────────────────────
class _ShimmerSlideUpTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerSlideUpTransition(
      {required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));

    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    final shimmerOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    return Stack(
      children: [
        FadeTransition(
          opacity: shimmerOpacity,
          child: Container(
            color: const Color(0xFF050810),
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => CustomPaint(
                painter: _SkyShimmerPainter(animation.value),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        ),
      ],
    );
  }
}

// ── Fade Scale ───────────────────────────────────────────────────────
class _FadeScaleTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeScaleTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

// ── Shimmer Slide Right ──────────────────────────────────────────────
class _ShimmerSlideRightTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerSlideRightTransition(
      {required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final shimmerOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
    );

    return Stack(
      children: [
        FadeTransition(
          opacity: shimmerOpacity,
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + animation.value * 3, 0),
                  end: Alignment(-0.5 + animation.value * 3, 0),
                  colors: [
                    const Color(0xFF00D4FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        ),
      ],
    );
  }
}

// ── Circular Reveal ──────────────────────────────────────────────────
class _CircularRevealTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _CircularRevealTransition(
      {required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => ClipPath(
        clipper: _CircleRevealClipper(animation.value),
        child: child,
      ),
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final double progress;
  _CircleRevealClipper(this.progress);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final curve = Curves.easeOutCubic.transform(progress);
    final radius = maxRadius * curve;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper old) => old.progress != progress;
}

// ── Sky shimmer painter ──────────────────────────────────────────────
class _SkyShimmerPainter extends CustomPainter {
  final double t;
  _SkyShimmerPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t > 0.25) return;
    final intensity = (1.0 - (t / 0.25)).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.04 * intensity);

    final rand = math.Random(42);
    for (int i = 0; i < 8; i++) {
      final y = rand.nextDouble() * size.height;
      final h = 1.0 + rand.nextDouble() * 3;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), paint);
    }

    final barPaint = Paint()
      ..color = const Color(0xFF7B61FF).withValues(alpha: 0.06 * intensity);
    for (int i = 0; i < 3; i++) {
      final x = rand.nextDouble() * size.width;
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), barPaint);
    }
  }

  @override
  bool shouldRepaint(_SkyShimmerPainter old) => old.t != t;
}

// ── Navigator extension ──────────────────────────────────────────────
extension SkyFitNavigator on NavigatorState {
  Future<T?> pushSkyFit<T>(
    Widget page, {
    SkyFitTransitionStyle style = SkyFitTransitionStyle.shimmerSlideUp,
  }) {
    return push(SkyFitPageRoute<T>(page: page, style: style));
  }

  Future<T?> pushReplacementSkyFit<T, TO>(
    Widget page, {
    SkyFitTransitionStyle style = SkyFitTransitionStyle.shimmerSlideUp,
    TO? result,
  }) {
    return pushReplacement(
      SkyFitPageRoute<T>(page: page, style: style),
      result: result,
    );
  }
}

// ── Route factory for onGenerateRoute ───────────────────────────────
class SkyFitRouteFactory {
  static final _routes = <String, (WidgetBuilder, SkyFitTransitionStyle)>{};

  static void register(
    String name,
    WidgetBuilder builder, {
    SkyFitTransitionStyle style = SkyFitTransitionStyle.shimmerSlideUp,
  }) {
    _routes[name] = (builder, style);
  }

  static Route<dynamic> generate(RouteSettings settings) {
    final routeName = (settings.name == null || settings.name == '/')
        ? '/splash'
        : settings.name!;

    final entry = _routes[routeName];

    if (entry == null) {
      debugPrint(
          '[SkyFitRouteFactory] Unknown route: "${settings.name}" — fallback');
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          backgroundColor: Color(0xFF050810),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4FF))),
        ),
        settings: settings,
      );
    }

    final (builder, style) = entry;
    return SkyFitPageRoute(
      page: Builder(builder: builder),
      style: style,
      settings: RouteSettings(name: routeName, arguments: settings.arguments),
    );
  }

  /// Returns the first registered route name as the root fallback,
  /// or '/splash' if nothing is registered yet.
  static String _resolveRootRoute() => '/splash';
}
