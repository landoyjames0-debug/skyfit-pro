import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'profile_view.dart';
import 'widgets/activity_card.dart';
import 'widgets/weather_card.dart';
import 'auth/login_view.dart';

// ─── Design System ─────────────────────────────────────────────────────────────
class _DS {
  // Brand
  static const Color brand = Color(0xFF2563EB); // Royal blue
  static const Color brandLight = Color(0xFF3B82F6);
  static const Color brandDim = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF06B6D4); // Cyan teal
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Dark palette
  static const Color darkBg = Color(0xFF0A0F1E);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurface2 = Color(0xFF1C2537);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkBorder2 = Color(0xFF263348);

  // Light palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorder2 = Color(0xFFCBD5E1);

  // Text
  static Color textPrimary(bool dark) =>
      dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color textSecondary(bool dark) =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color textMuted(bool dark) =>
      dark ? const Color(0xFF475569) : const Color(0xFF94A3B8);

  static Color bg(bool dark) => dark ? darkBg : lightBg;
  static Color surface(bool dark) => dark ? darkSurface : lightSurface;
  static Color surface2(bool dark) => dark ? darkSurface2 : lightSurface2;
  static Color border(bool dark) => dark ? darkBorder : lightBorder;
  static Color border2(bool dark) => dark ? darkBorder2 : lightBorder2;

  // Glassmorphism helper
  static Color glass(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.white.withValues(alpha: 0.7);
  static Color glassBorder(bool dark) => dark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.9);

  // Shadows
  static List<BoxShadow> shadow(bool dark,
          {Color? color, double intensity = 1}) =>
      [
        BoxShadow(
          color: (color ?? (dark ? Colors.black : const Color(0xFF64748B)))
              .withValues(alpha: dark ? 0.4 * intensity : 0.08 * intensity),
          blurRadius: 24 * intensity,
          offset: Offset(0, 8 * intensity),
        ),
      ];

  static List<BoxShadow> brandGlow({double alpha = 0.25}) => [
        BoxShadow(
          color: brand.withValues(alpha: alpha),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

// ─── Session Timer Chip ────────────────────────────────────────────────────────
class _SessionTimerChip extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onTimeout;
  final VoidCallback onInteraction;

  const _SessionTimerChip({
    super.key,
    required this.initialSeconds,
    required this.onTimeout,
    required this.onInteraction,
  });

  @override
  State<_SessionTimerChip> createState() => SessionTimerChipState();
}

class SessionTimerChipState extends State<_SessionTimerChip> {
  late int _remaining;
  Timer? _timer;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        widget.onTimeout();
      }
    });
  }

  void resetTimer() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _remaining = widget.initialSeconds);
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _chipColor {
    if (_remaining > 120) return _DS.success;
    if (_remaining > 60) return _DS.warning;
    return _DS.danger;
  }

  @override
  Widget build(BuildContext context) {
    final c = _chipColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, color: c, size: 11),
        const SizedBox(width: 5),
        Text(
          _label,
          style: TextStyle(
            color: c,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }
}

// ─── HomeView ──────────────────────────────────────────────────────────────────
class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTop = false;

  OverlayEntry? _menuOverlay;
  bool _menuOpen = false;

  static const int _sessionSeconds = 300;

  final GlobalKey<SessionTimerChipState> _timerKey =
      GlobalKey<SessionTimerChipState>();
  final GlobalKey _avatarKey = GlobalKey();
  bool _darkAtMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _bgAnimController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 200;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
      _onUserInteraction();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherVM = context.read<WeatherViewModel>();
      final userVM = context.read<UserViewModel>();
      weatherVM.fetchWeather(userVM.user);
    });
  }

  void _onUserInteraction() => _timerKey.currentState?.resetTimer();

  void _onSessionTimeout() {
    if (!mounted) return;
    _closeMenu();
    HapticFeedback.heavyImpact();
    final dark = _resolveDark(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, _, child) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child)),
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _DS.surface(dark),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _DS.danger.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                    color: _DS.danger.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 2),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 60,
                    offset: const Offset(0, 24)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _DS.danger.withValues(alpha: 0.1),
                      border: Border.all(
                          color: _DS.danger.withValues(alpha: 0.3),
                          width: 1.5)),
                  child: const Icon(Icons.lock_clock_rounded,
                      color: _DS.danger, size: 32)),
              const SizedBox(height: 20),
              Text('Session Expired',
                  style: TextStyle(
                      color: _DS.textPrimary(dark),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Text(
                  'You were inactive for 5 minutes.\nYour session has been locked for security.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _DS.textSecondary(dark),
                      fontSize: 13,
                      height: 1.6)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _DS.danger,
                      boxShadow: [
                        BoxShadow(
                            color: _DS.danger.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ]),
                  child: TextButton(
                    onPressed: () async {
                      Navigator.of(context, rootNavigator: true).pop();
                      await _doLogout();
                    },
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Back to Login',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeMenu();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _resolveDark(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    return authVM.themeMode == ThemeMode.dark ||
        (authVM.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
  }

  void _toggleMenu() {
    _onUserInteraction();
    _menuOpen ? _closeMenu() : _openMenu();
  }

  void _openMenu() {
    final RenderBox renderBox =
        _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final Offset pos = renderBox.localToGlobal(Offset.zero);
    final Size sz = renderBox.size;
    _darkAtMenuOpen = _resolveDark(context);

    _menuOverlay = OverlayEntry(
        builder: (ctx) => _MiniMenuOverlay(
              avatarBottom: pos.dy + sz.height + 8,
              avatarRight: MediaQuery.of(ctx).size.width - pos.dx - sz.width,
              isDark: _darkAtMenuOpen,
              onSettings: () {
                _closeMenu();
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileView()));
              },
              onLogout: () {
                _closeMenu();
                Future.microtask(() {
                  if (mounted) _showLogoutConfirmation();
                });
              },
              onDismiss: _closeMenu,
            ));

    Overlay.of(context).insert(_menuOverlay!);
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    if (mounted) setState(() => _menuOpen = false);
  }

  void _showLogoutConfirmation() {
    if (!mounted) return;
    final dark = _resolveDark(context);

    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child)),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _DS.surface(dark),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _DS.border(dark)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 48,
                    offset: const Offset(0, 20)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _DS.danger.withValues(alpha: 0.08),
                      border: Border.all(
                          color: _DS.danger.withValues(alpha: 0.25),
                          width: 1.5)),
                  child: const Icon(Icons.logout_rounded,
                      color: _DS.danger, size: 26)),
              const SizedBox(height: 16),
              Text('Sign Out?',
                  style: TextStyle(
                      color: _DS.textPrimary(dark),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2)),
              const SizedBox(height: 6),
              Text('Your session will be securely ended.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _DS.textSecondary(dark),
                      fontSize: 13,
                      height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(false),
                        child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                                color: _DS.surface2(dark),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _DS.border(dark))),
                            child: Center(
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: _DS.textSecondary(dark),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)))))),
                const SizedBox(width: 10),
                Expanded(
                    child: GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop(true);
                          Future.microtask(() {
                            if (mounted) _doLogout();
                          });
                        },
                        child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                                color: _DS.danger,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: _DS.danger.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]),
                            child: const Center(
                                child: Text('Sign Out',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)))))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _doLogout() async {
    if (!mounted) return;
    final authVM = context.read<AuthViewModel>();
    await authVM.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authVM = context.watch<AuthViewModel>();
    final dark = authVM.themeMode == ThemeMode.dark ||
        (authVM.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return GestureDetector(
      onTap: () {
        if (_menuOpen) _closeMenu();
        _onUserInteraction();
      },
      onScaleUpdate: (_) => _onUserInteraction(),
      child: Scaffold(
        backgroundColor: _DS.bg(dark),
        body: Stack(children: [
          // Subtle ambient background
          _AmbientBackground(
              controller: _bgAnimController, size: size, dark: dark),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [
                _buildAppBar(context, dark),
                Expanded(child: _buildBody(context, dark)),
              ]),
            ),
          ),
          // Scroll-to-top FAB
          Positioned(
            bottom: 24,
            right: 20,
            child: AnimatedOpacity(
                opacity: _showScrollTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedSlide(
                    offset: _showScrollTop ? Offset.zero : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showScrollTop,
                      child: GestureDetector(
                          onTap: () {
                            _onUserInteraction();
                            _scrollController.animateTo(0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut);
                          },
                          child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _DS.brand,
                                  boxShadow: _DS.brandGlow()),
                              child: const Icon(Icons.keyboard_arrow_up_rounded,
                                  color: Colors.white, size: 20))),
                    ))),
          ),
        ]),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, bool dark) {
    final userVM = context.watch<UserViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final user = userVM.user;
    final initials = _getInitials(user?.fullName);
    final firstName = user?.fullName.split(' ').first ?? 'Athlete';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: dark
            ? _DS.darkSurface.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: _DS.border(dark), width: 1)),
      ),
      child: Row(children: [
        // Brand icon
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _DS.brand,
                boxShadow: _DS.brandGlow(alpha: 0.2)),
            child: const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 16)),
        const SizedBox(width: 10),
        // Brand name + greeting
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SkyFit Pro',
                style: TextStyle(
                    color: _DS.textPrimary(dark),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2)),
            Text('$greeting, $firstName',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: _DS.textMuted(dark),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
        // Session timer
        _SessionTimerChip(
          key: _timerKey,
          initialSeconds: _sessionSeconds,
          onTimeout: _onSessionTimeout,
          onInteraction: _onUserInteraction,
        ),
        const SizedBox(width: 8),
        // Theme toggle
        GestureDetector(
            onTap: () {
              authVM.toggleTheme();
              _onUserInteraction();
            },
            child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: _DS.surface2(dark),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _DS.border(dark))),
                child: Icon(
                    dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: _DS.textSecondary(dark),
                    size: 15))),
        const SizedBox(width: 8),
        // Avatar
        GestureDetector(
            key: _avatarKey,
            onTap: _toggleMenu,
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _DS.brand,
                    border: Border.all(
                        color: _menuOpen
                            ? _DS.brand.withValues(alpha: 0.6)
                            : Colors.transparent,
                        width: 2),
                    boxShadow: _menuOpen ? _DS.brandGlow(alpha: 0.35) : null),
                child: user?.profilePictureUrl != null
                    ? ClipOval(
                        child: Image.network(user!.profilePictureUrl!,
                            fit: BoxFit.cover, width: 34, height: 34))
                    : Center(
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3))))),
      ]),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, bool dark) {
    final weatherVM = context.watch<WeatherViewModel>();
    final userVM = context.watch<UserViewModel>();

    if (weatherVM.isLoading) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
                color: _DS.brand,
                backgroundColor: _DS.brand.withValues(alpha: 0.1),
                strokeWidth: 3)),
        const SizedBox(height: 16),
        Text('Loading your dashboard...',
            style: TextStyle(color: _DS.textMuted(dark), fontSize: 13)),
      ]));
    }

    if (weatherVM.errorMessage != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _DS.danger.withValues(alpha: 0.08),
                            border: Border.all(
                                color: _DS.danger.withValues(alpha: 0.25))),
                        child: const Icon(Icons.cloud_off_rounded,
                            color: _DS.danger, size: 36)),
                    const SizedBox(height: 16),
                    Text('Weather Unavailable',
                        style: TextStyle(
                            color: _DS.textPrimary(dark),
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(weatherVM.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _DS.textSecondary(dark), fontSize: 13)),
                    const SizedBox(height: 20),
                    GestureDetector(
                        onTap: () {
                          _onUserInteraction();
                          weatherVM.fetchWeather(userVM.user);
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                                color: _DS.brand,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _DS.brandGlow()),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Try Again',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13))
                                ]))),
                  ])));
    }

    return RefreshIndicator(
      color: _DS.brand,
      backgroundColor: _DS.surface(dark),
      onRefresh: () {
        _onUserInteraction();
        return weatherVM.fetchWeather(userVM.user);
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Weather Card ──
              if (weatherVM.weather != null) ...[
                Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _DS.surface(dark),
                        border: Border.all(color: _DS.border(dark)),
                        boxShadow: _DS.shadow(dark)),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: WeatherCard(weather: weatherVM.weather!))),
                const SizedBox(height: 12),
              ],

              // ── Stats Bar ──
              if (userVM.user != null) ...[
                _buildStatsBar(userVM, dark),
                const SizedBox(height: 20),
              ],

              // ── Section Header ──
              Row(children: [
                Text("Today's Activities",
                    style: TextStyle(
                        color: _DS.textPrimary(dark),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2)),
                const Spacer(),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: _DS.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('${weatherVM.activities.length} activities',
                        style: TextStyle(
                            color: _DS.brand,
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),

              // ── Activity Cards ──
              ...weatherVM.activities.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: _DS.surface(dark),
                          border: Border.all(color: _DS.border(dark)),
                          boxShadow: _DS.shadow(dark, intensity: 0.7)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ActivityCard(activity: a),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Bar ────────────────────────────────────────────────────────────────
  Widget _buildStatsBar(UserViewModel userVM, bool dark) {
    final user = userVM.user!;
    final weightLabel = user.weightKg == user.weightKg.truncateToDouble()
        ? '${user.weightKg.toInt()} kg'
        : '${user.weightKg} kg';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _DS.surface(dark),
        border: Border.all(color: _DS.border(dark)),
        boxShadow: _DS.shadow(dark, intensity: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Three stat tiles ──
          IntrinsicHeight(
            child: Row(
              children: [
                _statTile(
                  value: user.age.toString(),
                  label: 'Age',
                  color: _DS.brand,
                  icon: Icons.cake_outlined,
                  dark: dark,
                ),
                _statVerticalDivider(dark),
                _statTile(
                  value: weightLabel,
                  label: 'Weight',
                  color: _DS.warning,
                  icon: Icons.monitor_weight_outlined,
                  dark: dark,
                ),
                _statVerticalDivider(dark),
                _statTile(
                  value: user.weightCategory,
                  label: 'Category',
                  color: _DS.success,
                  icon: Icons.equalizer_rounded,
                  dark: dark,
                  isCategory: true,
                ),
              ],
            ),
          ),

          // ── Fitness goal ──
          if (user.fitnessGoal != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _DS.brand.withValues(alpha: 0.3),
                    _DS.accent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _DS.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _DS.brand.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: _DS.brand, size: 13),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness Goal',
                      style: TextStyle(
                        color: _DS.textMuted(dark),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      user.fitnessGoal!,
                      style: const TextStyle(
                        color: _DS.brand,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required bool dark,
    bool isCategory = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            // Value
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: isCategory ? 15 : 24,
                fontWeight: FontWeight.w800,
                letterSpacing: isCategory ? -0.2 : -0.8,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                color: _DS.textMuted(dark),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statVerticalDivider(bool dark) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              _DS.border2(dark),
              _DS.border2(dark),
              Colors.transparent,
            ],
          ),
        ),
      );
}

// ─── Mini Menu Overlay ─────────────────────────────────────────────────────────
class _MiniMenuOverlay extends StatefulWidget {
  final double avatarBottom;
  final double avatarRight;
  final bool isDark;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback onDismiss;

  const _MiniMenuOverlay({
    required this.avatarBottom,
    required this.avatarRight,
    required this.isDark,
    required this.onSettings,
    required this.onLogout,
    required this.onDismiss,
  });

  @override
  State<_MiniMenuOverlay> createState() => _MiniMenuOverlayState();
}

class _MiniMenuOverlayState extends State<_MiniMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    return Stack(children: [
      Positioned.fill(
          child: GestureDetector(
              onTap: widget.onDismiss,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand())),
      Positioned(
        top: widget.avatarBottom,
        right: widget.avatarRight - 2,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.topRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 168,
                decoration: BoxDecoration(
                    color: _DS.surface(dark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _DS.border(dark)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8)),
                    ]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // My Profile
                    Material(
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: widget.onSettings,
                            splashColor: _DS.brand.withValues(alpha: 0.08),
                            highlightColor: _DS.brand.withValues(alpha: 0.04),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  Icon(Icons.person_outline_rounded,
                                      color: _DS.textSecondary(dark), size: 16),
                                  const SizedBox(width: 10),
                                  Text('My Profile',
                                      style: TextStyle(
                                          color: _DS.textPrimary(dark),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500))
                                ])))),
                    Divider(height: 1, thickness: 1, color: _DS.border(dark)),
                    // Sign Out
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onLogout,
                        splashColor: _DS.danger.withValues(alpha: 0.08),
                        highlightColor: _DS.danger.withValues(alpha: 0.04),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.logout_rounded,
                                color: _DS.danger, size: 16),
                            const SizedBox(width: 10),
                            const Text('Sign Out',
                                style: TextStyle(
                                    color: _DS.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── Ambient Background ───────────────────────────────────────────────────────
class _AmbientBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  final bool dark;
  const _AmbientBackground(
      {required this.controller, required this.size, required this.dark});

  @override
  Widget build(BuildContext context) {
    if (!dark) return const SizedBox.shrink();
    return AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
            size: size, painter: _AmbientPainter(controller.value)));
  }
}

class _AmbientPainter extends CustomPainter {
  final double t;
  _AmbientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.15 + math.cos(a1) * 20,
        size.height * 0.12 + math.sin(a1) * 15);
    canvas.drawCircle(
        c1,
        160,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.12),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 160)));

    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.85 + math.cos(a2) * 25,
        size.height * 0.55 + math.sin(a2) * 20);
    canvas.drawCircle(
        c2,
        180,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF06B6D4).withValues(alpha: 0.08),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 180)));
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.t != t;
}
