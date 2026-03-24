import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'skyfit_logo.dart';

/// SkyFitSplashScreen — Full-screen animated loading screen for SkyFit Pro.
///
/// Already wired in your main.dart as the initial route.
/// Just make sure your routes include:
///
///   '/splash': (_) => const SkyFitSplashScreen(nextRoute: '/login'),
///   '/login':  (_) => const LoginView(),
///   '/home':   (_) => const HomeView(),
///
/// Or with the existing AppConstants:
///   SkyFitSplashScreen(nextRoute: AppConstants.loginRoute)
class SkyFitSplashScreen extends StatefulWidget {
  final String nextRoute;
  final Duration duration;

  const SkyFitSplashScreen({
    super.key,
    required this.nextRoute,
    this.duration = const Duration(milliseconds: 3200),
  });

  @override
  State<SkyFitSplashScreen> createState() => _SkyFitSplashScreenState();
}

class _SkyFitSplashScreenState extends State<SkyFitSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoEntranceController;
  late AnimationController _textRevealController;
  late AnimationController _progressController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _progress;
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  // SkyFit Pro boot sequence lines
  final List<String> _bootLines = [
    'INITIALIZING FITNESS ENGINE...',
    'LOADING WEATHER MODULE...',
    'CALIBRATING ACTIVITY PROFILES...',
    'SYNCING USER DATA...',
    'READY. LET\'S MOVE.',
  ];
  int _visibleLines = 0;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _startSequence();
  }

  void _setupControllers() {
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _logoEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoEntranceController, curve: Curves.elasticOut),
    );
    _logoFade =
        CurvedAnimation(parent: _logoEntranceController, curve: Curves.easeOut);

    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade =
        CurvedAnimation(parent: _textRevealController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _textRevealController, curve: Curves.easeOut));
    _taglineFade = CurvedAnimation(
      parent: _textRevealController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progress =
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut);

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return; // FIX: guard after every await

    _logoEntranceController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textRevealController.forward();

    for (int i = 0; i < _bootLines.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return; // FIX: guard inside loop too
      setState(() => _visibleLines = i + 1);
    }

    if (!mounted) return;
    _progressController.forward();

    // FIX: clamp duration subtraction so it never goes negative
    final waitDuration = widget.duration > const Duration(milliseconds: 700)
        ? widget.duration - const Duration(milliseconds: 700)
        : Duration.zero;

    await Future.delayed(waitDuration);
    if (!mounted) return;

    _exitController.forward();

    await Future.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;

    // FIX: guard against empty or invalid route
    if (widget.nextRoute.isNotEmpty) {
      Navigator.pushReplacementNamed(context, widget.nextRoute);
    } else {
      debugPrint('[SkyFitSplashScreen] ERROR: nextRoute is empty! '
          'Pass a valid route like "/login" or "/home".');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoEntranceController.dispose();
    _textRevealController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgController, _exitController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _exitFade,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Stack(
                children: [
                  // Animated orb background
                  CustomPaint(
                    size: size,
                    painter: _SplashOrbPainter(_bgController.value),
                  ),
                  // Grid overlay
                  _buildGridOverlay(),
                  // Main content
                  SafeArea(child: child!),
                ],
              ),
            ),
          );
        },
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Logo
        FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: const SkyFitLogo(size: 100, animated: true),
          ),
        ),

        const SizedBox(height: 32),

        // Wordmark + tagline
        FadeTransition(
          opacity: _textFade,
          child: SlideTransition(
            position: _textSlide,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                  ).createShader(bounds),
                  child: const Text(
                    'SkyFit Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _taglineFade,
                  child: const Text(
                    'YOUR PERSONALIZED FITNESS COMPANION',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(flex: 2),

        // Boot terminal
        _buildBootTerminal(),
        const SizedBox(height: 24),

        // Progress bar
        _buildProgressBar(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBootTerminal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terminal header
            Row(
              children: [
                _terminalDot(const Color(0xFFFF4D6D)),
                const SizedBox(width: 6),
                _terminalDot(const Color(0xFFFFB547)),
                const SizedBox(width: 6),
                _terminalDot(const Color(0xFF4ADE80)),
                const SizedBox(width: 10),
                Text(
                  'skyfit_boot_sequence',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Boot lines
            ...List.generate(_visibleLines, (i) {
              final isLast = i == _visibleLines - 1;
              final isSuccess = _bootLines[i].contains('READY');
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '> ',
                      style: TextStyle(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      _bootLines[i],
                      style: TextStyle(
                        color: isSuccess
                            ? const Color(0xFF4ADE80)
                            : Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight:
                            isSuccess ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    if (isLast && !isSuccess) ...[
                      const SizedBox(width: 2),
                      const _BlinkingCursor(), // FIX: added const
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, __) {
          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _progress.value,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00D4FF).withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress.value * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _terminalDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ── Blinking cursor ──────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor(); // FIX: added const constructor

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(width: 6, height: 12, color: const Color(0xFF00D4FF)),
    );
  }
}

// ── Grid overlay painter ─────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ── Orb background painter ───────────────────────────────────────────
class _SplashOrbPainter extends CustomPainter {
  final double t;
  const _SplashOrbPainter(this.t); // FIX: added const

  @override
  void paint(Canvas canvas, Size size) {
    void drawOrb(double cx, double cy, double r, Color color, double alpha) {
      final center = Offset(size.width * cx, size.height * cy);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    final a1 = t * 2 * math.pi;
    drawOrb(0.2 + math.cos(a1) * 0.05, 0.2 + math.sin(a1) * 0.04,
        size.width * 0.55, const Color(0xFF00D4FF), 0.18);

    final a2 = t * 2 * math.pi + math.pi;
    drawOrb(0.85 + math.cos(a2) * 0.05, 0.75 + math.sin(a2) * 0.05,
        size.width * 0.6, const Color(0xFF7B61FF), 0.16);

    final a3 = t * 2 * math.pi * 0.7;
    drawOrb(0.55 + math.cos(a3) * 0.04, 0.45 + math.sin(a3) * 0.04,
        size.width * 0.4, const Color(0xFF4ADE80), 0.10);
  }

  @override
  bool shouldRepaint(_SplashOrbPainter old) => old.t != t;
}
