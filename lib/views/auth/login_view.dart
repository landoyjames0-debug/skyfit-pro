import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import 'register_view.dart';
import '../home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _showBiometric = false;
  Timer? _errorDismissTimer;

  // FIX: biometric attempt tracking (lab requires lockout after 3 failures)
  int _biometricFailCount = 0;
  static const int _maxBiometricAttempts = 3;

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();
    _bgAnimController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
    _buttonPressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(
            parent: _buttonPressController, curve: Curves.easeInOut));
    _fadeController.forward();
    _slideController.forward();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authVM = context.read<AuthViewModel>();
    final userVM = context.read<UserViewModel>();
    final deviceSupports = await authVM.isBiometricAvailable();
    final userEnabled = await userVM.isBiometricEnabled();
    if (mounted) setState(() => _showBiometric = deviceSupports && userEnabled);
  }

  void _scheduleErrorDismiss() {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) context.read<AuthViewModel>().clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _errorDismissTimer?.cancel();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }

  Future<void> _showLoginSuccessModal(String name) async {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20 : 32,
              vertical: 24,
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 4),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 20)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF00D4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great to see you again, $name.\nYour fitness journey continues!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.5),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B61FF), Color(0xFF00D4FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Let's Go!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }
    setState(() => _isLoading = true);
    final authVM = context.read<AuthViewModel>();
    final userVM = context.read<UserViewModel>();
    final email = _emailCtrl.text.trim();
    final nav = Navigator.of(context);
    final success = await authVM.loginWithEmail(email, _passCtrl.text);
    setState(() => _isLoading = false);
    if (success && mounted) {
      await userVM.loadUser(authVM.currentUser?.uid ?? '');
      final displayName =
          authVM.currentUser?.displayName ?? email.split('@').first;
      await _showLoginSuccessModal(displayName);
      if (mounted) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
      }
    } else {
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    final authVM = context.read<AuthViewModel>();
    final userVM = context.read<UserViewModel>();
    final nav = Navigator.of(context);
    final success = await authVM.signInWithGoogle();
    setState(() => _isLoading = false);
    if (success && mounted) {
      await userVM.loadUser(authVM.currentUser?.uid ?? '');
      // FIX: use currentUser.email as fallback, not the (possibly empty) email field
      final displayName = authVM.currentUser?.displayName ??
          authVM.currentUser?.email?.split('@').first ??
          'Athlete';
      await _showLoginSuccessModal(displayName);
      if (mounted) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
      }
    }
  }

  // FIX: full biometric flow with 3-attempt lockout as required by lab spec
  Future<void> _onBiometricPressed() async {
    // Guard: already locked out
    if (_biometricFailCount >= _maxBiometricAttempts) {
      _showBiometricLockedSnackbar();
      return;
    }

    setState(() => _isBiometricLoading = true);
    final authVM = context.read<AuthViewModel>();
    final nav = Navigator.of(context);
    final success = await authVM.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _isBiometricLoading = false);

    if (success) {
      // Reset counter on success
      _biometricFailCount = 0;
      final displayName = authVM.currentUser?.displayName ??
          authVM.currentUser?.email?.split('@').first ??
          'Athlete';
      await _showLoginSuccessModal(displayName);
      if (mounted) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
      }
    } else {
      _biometricFailCount++;
      final remaining = _maxBiometricAttempts - _biometricFailCount;

      if (_biometricFailCount >= _maxBiometricAttempts) {
        // Lockout: hide the biometric button and force password
        setState(() => _showBiometric = false);
        _showBiometricLockedSnackbar();
      } else {
        // Show remaining attempts warning
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.fingerprint_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Biometric failed. $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ]),
          backgroundColor: const Color(0xFFFF8C42),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  void _showBiometricLockedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.lock_rounded, color: Colors.white, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Too many failed attempts. Please use your password.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ]),
      backgroundColor: const Color(0xFFFF4D6D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // FIX: derive dark from Theme so LoginView respects the app-wide theme
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // FIX: theme-aware background — dark gets animated orbs, light gets subtle version
          isDark
              ? _AnimatedBackground(controller: _bgAnimController, size: size)
              : _LightAnimatedBackground(
                  controller: _bgAnimController, size: size),
          SafeArea(
            child: Consumer<AuthViewModel>(
              builder: (context, authVM, _) {
                if (authVM.errorMessage != null) _scheduleErrorDismiss();
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLogo(size, isDark),
                                  const SizedBox(height: 28),
                                  _buildGlassCard(authVM, isDark),
                                  const SizedBox(height: 20),
                                  _buildRegisterLink(isDark),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Size size, bool isDark) {
    final logoSize = size.height < 700 ? 56.0 : 72.0;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (_, __) => Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                  blurRadius:
                      20 + math.sin(_bgAnimController.value * 2 * math.pi) * 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: logoSize * 0.46),
          ),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text('SkyFit Pro',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(height: 6),
        Text(
          'YOUR PERSONALIZED FITNESS COMPANION',
          style: TextStyle(
              // FIX: adapt subtitle color to theme
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : const Color(0xFF5A6A7A),
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildGlassCard(AuthViewModel authVM, bool isDark) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shake = math.sin(_shakeAnim.value * math.pi * 5) * 8;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          // FIX: theme-aware card background
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.03)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFDDE4ED),
              width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20)),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F1923),
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Sign in to continue your fitness journey',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : const Color(0xFF5A6A7A),
                    fontSize: 13)),
            const SizedBox(height: 24),

            _buildInputField(
              controller: _emailCtrl,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            _buildInputField(
              controller: _passCtrl,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              isDark: isDark,
              obscureText: _obscurePass,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              suffixIcon: IconButton(
                tooltip: _obscurePass ? 'Show password' : 'Hide password',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    key: ValueKey(_obscurePass),
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
            ),

            const SizedBox(height: 16),

            // Error banner
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: authVM.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        onTap: () {
                          _errorDismissTimer?.cancel();
                          authVM.clearError();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFF4D6D)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFFF4D6D), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(authVM.errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFFF4D6D),
                                        fontSize: 12))),
                            const Icon(Icons.close_rounded,
                                color: Color(0xFFFF4D6D), size: 14),
                          ]),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            _buildPrimaryButton(
              label: 'Sign In',
              icon: Icons.arrow_forward_rounded,
              isLoading: _isLoading,
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              glowColor: const Color(0xFF00D4FF),
              onTap: _login,
            ),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : const Color(0xFF9AA5B4),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                  child: Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE2E8F0))),
            ]),
            const SizedBox(height: 16),

            _buildGoogleButton(isDark),

            if (_showBiometric) ...[
              const SizedBox(height: 12),
              _buildBiometricButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required LinearGradient gradient,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (!isLoading) _buttonPressController.forward();
      },
      onTapUp: (_) {
        _buttonPressController.reverse();
        if (!isLoading) onTap();
      },
      onTapCancel: () => _buttonPressController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonScaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _buttonScaleAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isLoading
                ? const LinearGradient(
                    colors: [Color(0xFF374151), Color(0xFF374151)])
                : gradient,
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                        color: glowColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 17),
                  ]),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : _googleSignIn,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // FIX: theme-aware Google button
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF7F9FC),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFDDE4ED),
              width: 1.2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.7),
              ]),
            ),
            child: const Center(
                child: Text('G',
                    style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 13,
                        fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 10),
          Text('Continue with Google',
              style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF0F1923),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildBiometricButton() {
    // FIX: show remaining attempts as a sub-label when failures have occurred
    final remaining = _maxBiometricAttempts - _biometricFailCount;
    final hasFailures = _biometricFailCount > 0;

    return GestureDetector(
      onTap: _isBiometricLoading ? null : _onBiometricPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: hasFailures ? 62 : 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
              color: const Color(0xFF00D4FF)
                  .withValues(alpha: _isBiometricLoading ? 0.15 : 0.35),
              width: 1.2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isBiometricLoading
              ? const Row(
                  key: ValueKey('bio-loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.0, color: Color(0xFF00D4FF))),
                      SizedBox(width: 10),
                      Text('Authenticating...',
                          style: TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ])
              : Column(
                  key: const ValueKey('bio-idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded,
                              color: Color(0xFF00D4FF), size: 24),
                          SizedBox(width: 10),
                          Text('Unlock with Biometrics',
                              style: TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ]),
                    if (hasFailures) ...[
                      const SizedBox(height: 3),
                      Text(
                        '$remaining attempt${remaining == 1 ? '' : 's'} remaining',
                        style: TextStyle(
                          color: const Color(0xFFFF8C42).withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New to SkyFit Pro? ",
            style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : const Color(0xFF5A6A7A),
                fontSize: 13)),
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const RegisterView())),
          child: const Text('Create Account',
              style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    List<String>? autofillHints,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      // FIX: theme-aware text color
      style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F1923), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF8A9BB0),
            fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF00D4FF), size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFDDE4ED))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFDDE4ED))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF4D6D), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}

// ── Dark animated background (original) ──────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _AnimatedBackground({required this.controller, required this.size});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          CustomPaint(size: size, painter: _OrbPainter(controller.value)),
    );
  }
}

// FIX: light mode background for LoginView (matches HomeView's _LightBackground)
class _LightAnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _LightAnimatedBackground(
      {required this.controller, required this.size});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          CustomPaint(size: size, painter: _LightOrbPainter(controller.value)),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  const _OrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.2 + math.cos(a1) * 60,
        size.height * 0.2 + math.sin(a1) * 40);
    canvas.drawCircle(
        c1,
        260,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.22),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 260)));
    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.85 + math.cos(a2) * 60,
        size.height * 0.8 + math.sin(a2) * 40);
    canvas.drawCircle(
        c2,
        280,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.2),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 280)));
    final a3 = t * 2 * math.pi * 0.7 + math.pi * 0.5;
    final c3 = Offset(size.width * 0.5 + math.cos(a3) * 40,
        size.height * 0.5 + math.sin(a3) * 40);
    canvas.drawCircle(
        c3,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF4ADE80).withValues(alpha: 0.08),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c3, radius: 200)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}

class _LightOrbPainter extends CustomPainter {
  final double t;
  const _LightOrbPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.2 + math.cos(a1) * 40,
        size.height * 0.15 + math.sin(a1) * 30);
    canvas.drawCircle(
        c1,
        220,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.07),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 220)));
    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.85 + math.cos(a2) * 40,
        size.height * 0.75 + math.sin(a2) * 30);
    canvas.drawCircle(
        c2,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.05),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 200)));
  }

  @override
  bool shouldRepaint(_LightOrbPainter old) => old.t != t;
}
