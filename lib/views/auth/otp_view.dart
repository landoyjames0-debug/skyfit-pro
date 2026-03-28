import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../home_view.dart';
import '../../services/email_service.dart';

class OtpView extends StatefulWidget {
  final String email;
  final String name;
  final String? generatedOtp;
  final Future<void> Function()? onVerified;

  const OtpView({
    super.key,
    required this.email,
    required this.name,
    this.generatedOtp,
    this.onVerified,
  });

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // ─── OTP Security ──────────────────────────────────────────────────────────
  // On web: store only the SHA-256 hash of the OTP, never the plaintext.
  // This prevents the OTP from being visible in Flutter's widget state
  // inspector or browser dev tools memory snapshots.
  // On mobile: plaintext is fine since there's no browser dev tools exposure.
  String? _otpHash; // web: SHA-256 hash of OTP
  String? _currentOtp; // mobile only: plaintext OTP (null on web)

  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  int _secondsRemaining = 300;
  Timer? _timer;

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shakeAnim;

  // ─── Hash helper ───────────────────────────────────────────────────────────
  static String _hashOtp(String otp) {
    final bytes = utf8.encode(otp);
    return sha256.convert(bytes).toString();
  }

  void _storeOtp(String otp) {
    if (kIsWeb) {
      _otpHash = _hashOtp(otp);
      _currentOtp = null; // never store plaintext on web
    } else {
      _currentOtp = otp;
      _otpHash = null;
    }
  }

  bool _verifyOtp(String entered) {
    if (kIsWeb) {
      return _otpHash != null && _hashOtp(entered) == _otpHash;
    }
    return _currentOtp != null && entered == _currentOtp;
  }

  @override
  void initState() {
    super.initState();

    _bgAnimController =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();

    if (widget.generatedOtp != null) {
      _storeOtp(widget.generatedOtp!);
      _startTimer();
    } else {
      _sendOtp();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    final otp = EmailService.generateOTP();
    _storeOtp(otp); // store hash on web, plaintext on mobile
    final sent = await EmailService.sendOTP(
        toName: widget.name, toEmail: widget.email, otpCode: otp);
    setState(() => _isSending = false);
    if (sent) {
      _startTimer();
    } else {
      setState(() => _errorMessage = 'Failed to send OTP. Please try again.');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining == 0) {
        t.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _timerText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _clearOtpFields() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) {
      setState(() {});
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _showSuccessModal() async {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;
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
              horizontal: isSmall ? 20 : 32,
              vertical: 24,
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.all(isSmall ? 24 : 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
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
                      colors: [Color(0xFF00D4FF), Color(0xFF4ADE80)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verified!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your identity has been confirmed successfully.',
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
                      colors: [Color(0xFF00D4FF), Color(0xFF4ADE80)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Continue',
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

  Future<void> _verify() async {
    final entered = _controllers.map((c) => c.text).join();
    if (entered.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      _shakeController.forward(from: 0);
      return;
    }
    if (_secondsRemaining == 0) {
      setState(
          () => _errorMessage = 'OTP has expired. Please request a new one.');
      _shakeController.forward(from: 0);
      return;
    }
    if (_verifyOtp(entered)) {
      _timer?.cancel();
      setState(() => _isLoading = true);
      try {
        if (widget.onVerified != null) await widget.onVerified!();
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          await _showSuccessModal();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeView()),
              (route) => false,
            );
          }
        }
      }
    } else {
      setState(() => _errorMessage = 'Incorrect OTP. Please try again.');
      _shakeController.forward(from: 0);
      _clearOtpFields();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgAnimController, size: size),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: isSmall ? 12 : 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBackButton(),
                          SizedBox(height: isSmall ? 16 : 24),
                          _buildHeader(),
                          SizedBox(height: isSmall ? 20 : 32),
                          _buildOtpCard(isSmall),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 1.2),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF6B7280), size: 18),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _bgAnimController,
          builder: (_, __) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF4ADE80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  blurRadius:
                      20 + math.sin(_bgAnimController.value * 2 * math.pi) * 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Verify Your Account',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2)),
        const SizedBox(height: 8),
        Text(
            _isSending
                ? 'Sending code...'
                : 'We sent a 6-digit code to your email',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
      ],
    );
  }

  Widget _buildOtpCard(bool isSmall) {
    final allFilled = _controllers.every((c) => c.text.isNotEmpty);
    final isDisabled = _isLoading || _isSending || !allFilled;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final shake = math.sin(_shakeAnim.value * math.pi * 6) *
            10 *
            (1 - _shakeAnim.value);
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.07),
              Colors.white.withValues(alpha: 0.03)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20))
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.alternate_email_rounded,
                    color: Color(0xFF00D4FF), size: 16),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(widget.email,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600))),
              ]),
            ),
            SizedBox(height: isSmall ? 20 : 28),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (_secondsRemaining > 0
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFFFF4D6D))
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_secondsRemaining > 0
                            ? const Color(0xFF00D4FF)
                            : const Color(0xFFFF4D6D))
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      _secondsRemaining > 0
                          ? Icons.timer_outlined
                          : Icons.timer_off_outlined,
                      color: _secondsRemaining > 0
                          ? const Color(0xFF00D4FF)
                          : const Color(0xFFFF4D6D),
                      size: 15),
                  const SizedBox(width: 6),
                  Text(
                    _secondsRemaining > 0
                        ? 'Expires in $_timerText'
                        : 'Code expired',
                    style: TextStyle(
                        color: _secondsRemaining > 0
                            ? const Color(0xFF00D4FF)
                            : const Color(0xFFFF4D6D),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Enter 6-Digit Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            _buildOtpInputRow(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _errorMessage = null),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFF4D6D).withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFFF4D6D), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFFF4D6D), fontSize: 13))),
                    const Icon(Icons.close_rounded,
                        color: Color(0xFFFF4D6D), size: 16),
                  ]),
                ),
              ),
            ],
            SizedBox(height: isSmall ? 16 : 24),
            GestureDetector(
              onTap: isDisabled ? null : _verify,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isDisabled
                      ? const LinearGradient(
                          colors: [Color(0xFF374151), Color(0xFF374151)])
                      : const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                  boxShadow: isDisabled
                      ? []
                      : [
                          BoxShadow(
                              color: const Color(0xFF00D4FF)
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ],
                ),
                child: Center(
                  child: (_isLoading || _isSending)
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Verify Account',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ]),
                ),
              ),
            ),
            SizedBox(height: isSmall ? 16 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Didn't receive it? ",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14)),
                _secondsRemaining == 0 && !_isSending
                    ? GestureDetector(
                        onTap: () {
                          _sendOtp();
                          _clearOtpFields();
                        },
                        child: const Text('Resend',
                            style: TextStyle(
                                color: Color(0xFF00D4FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w700)))
                    : _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF00D4FF)))
                        : Text('in $_timerText',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInputRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemSize =
            ((constraints.maxWidth - spacing * 5) / 6).clamp(36.0, 52.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (index) => Padding(
              padding: EdgeInsets.only(right: index < 5 ? spacing : 0),
              child: SizedBox(
                width: itemSize,
                height: itemSize + 8,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _controllers[index].text.isNotEmpty
                        ? const Color(0xFF00D4FF).withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.2)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? const Color(0xFF00D4FF).withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.15),
                            width: _controllers[index].text.isNotEmpty
                                ? 1.5
                                : 1.0)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF00D4FF), width: 2)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    } else if (value.isNotEmpty && index == 5) {
                      FocusScope.of(context).unfocus();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted &&
                            _controllers.every((c) => c.text.isNotEmpty)) {
                          _verify();
                        }
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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

class _OrbPainter extends CustomPainter {
  final double t;
  _OrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.85 + math.cos(a1) * 40,
        size.height * 0.15 + math.sin(a1) * 30);
    canvas.drawCircle(
        c1,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.22),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 200)));
    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.15 + math.cos(a2) * 50,
        size.height * 0.8 + math.sin(a2) * 40);
    canvas.drawCircle(
        c2,
        220,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.18),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 220)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
