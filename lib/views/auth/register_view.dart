import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../models/user_model.dart';
import '../../services/email_service.dart';
import 'otp_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _scrollController = ScrollController();

  String? _gender;
  String? _fitnessGoal;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String _passwordText = '';

  // ── Profile photo state ──────────────────────────────────────────────────
  Uint8List? _profileImageBytes;
  String? _profileImagePath; // non-web only
  bool _isPickingPhoto = false;

  late AnimationController _bgAnimController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonPressController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _buttonScaleAnim;

  static final _passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  void _onPasswordChanged() {
    if (mounted) setState(() => _passwordText = _passCtrl.text);
  }

  @override
  void initState() {
    super.initState();
    _bgAnimController =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _buttonPressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(
            parent: _buttonPressController, curve: Curves.easeInOut));
    _fadeController.forward();
    _slideController.forward();
    _passCtrl.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passCtrl.removeListener(_onPasswordChanged);
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _passCtrl,
      _confirmCtrl,
      _ageCtrl,
      _weightCtrl
    ]) {
      c.dispose();
    }
    _scrollController.dispose();
    _bgAnimController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }

  double _passwordStrength(String p) {
    if (p.isEmpty) return 0.0;
    double s = 0.0;
    if (p.length >= 8) s += 0.2;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.2;
    if (p.contains(RegExp(r'[a-z]'))) s += 0.2;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.2;
    if (p.contains(RegExp(r'[^a-zA-Z0-9]'))) s += 0.2;
    return s.clamp(0.0, 1.0);
  }

  Color _strengthColor(double s) {
    if (s < 0.4) return const Color(0xFFFF4D6D);
    if (s < 0.7) return const Color(0xFFFFB547);
    return const Color(0xFF4ADE80);
  }

  String _strengthLabel(double s) {
    if (s < 0.4) return 'Weak';
    if (s < 0.7) return 'Moderate';
    return 'Strong';
  }

  // ── PHOTO PICKER ─────────────────────────────────────────────────────────
  Future<void> _showPhotoSourceSheet() async {
    if (_isPickingPhoto) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, -8)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 14),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 1)
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          const Text('Add Profile Photo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Optional — you can add one later',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              if (!kIsWeb)
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
                    child: Container(
                      height: 88,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color:
                              const Color(0xFF00D4FF).withValues(alpha: 0.08),
                          border: Border.all(
                              color: const Color(0xFF00D4FF)
                                  .withValues(alpha: 0.3),
                              width: 1.2)),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF00D4FF)
                                      .withValues(alpha: 0.15)),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Color(0xFF00D4FF), size: 24),
                            ),
                            const SizedBox(height: 6),
                            const Text('Camera',
                                style: TextStyle(
                                    color: Color(0xFF00D4FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  ),
                ),
              if (!kIsWeb) const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                        border: Border.all(
                            color:
                                const Color(0xFF7B61FF).withValues(alpha: 0.3),
                            width: 1.2)),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7B61FF)
                                    .withValues(alpha: 0.15)),
                            child: const Icon(Icons.photo_library_rounded,
                                color: Color(0xFF7B61FF), size: 24),
                          ),
                          const SizedBox(height: 6),
                          const Text('Gallery',
                              style: TextStyle(
                                  color: Color(0xFF7B61FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(sheetCtx).pop(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.05),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Center(
                    child: Text('Skip for Now',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600))),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );

    if (source == null || !mounted) return;
    await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 1024, maxHeight: 1024);
      if (picked == null || !mounted) return;

      Uint8List? finalBytes;
      String? finalPath;

      if (kIsWeb) {
        finalBytes = await picked.readAsBytes();
      } else {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 85,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: const Color(0xFF050810),
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: const Color(0xFF00D4FF),
              backgroundColor: const Color(0xFF050810),
              lockAspectRatio: true,
            ),
            IOSUiSettings(
                title: 'Crop Photo',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false),
          ],
        );
        if (cropped == null || !mounted) return;
        finalPath = cropped.path;
        finalBytes = await cropped.readAsBytes();
      }

      if (!mounted) return;
      setState(() {
        _profileImageBytes = finalBytes;
        _profileImagePath = finalPath;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. Check permissions.'),
        backgroundColor: const Color(0xFF1A1F35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _register() async {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final name = _nameCtrl.text.trim();
    final age = int.parse(_ageCtrl.text);
    final weight = double.parse(_weightCtrl.text);
    final gender = _gender;
    final fitnessGoal = _fitnessGoal;

    final otpCode = EmailService.generateOTP();
    final sent = await EmailService.sendOTP(
      toName: name,
      toEmail: email,
      otpCode: otpCode,
    );
    if (mounted) setState(() => _isLoading = false);

    if (!sent || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Failed to send OTP. Please try again.'),
          ]),
          backgroundColor: const Color(0xFF1A1F35),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
      return;
    }

    if (mounted) {
      final ctx = context;
      if (!ctx.mounted) return;
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => OtpView(
            email: email,
            name: name,
            generatedOtp: otpCode,
            onVerified: () async {
              final authVM = ctx.read<AuthViewModel>();
              final userVM = ctx.read<UserViewModel>();

              final success = await authVM.registerWithEmail(
                email,
                password,
                name: name,
              );
              if (!success) return;

              final uid = authVM.currentUser!.uid;
              final newUser = UserModel(
                uid: uid,
                email: email,
                fullName: name,
                age: age,
                weightKg: weight,
                gender: gender,
                fitnessGoal: fitnessGoal,
              );
              await userVM.createProfile(newUser);
            },
          ),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authVM = context.read<AuthViewModel>();
    final nav = Navigator.of(context);
    final success = await authVM.signInWithGoogle();
    if (mounted) setState(() => _isLoading = false);
    if (success && mounted) nav.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgAnimController, size: size),
          SafeArea(
            child: Consumer<AuthViewModel>(
              builder: (context, authVM, _) => FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Center(
                    child: AutofillGroup(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 20),
                                _buildForm(authVM),
                                const SizedBox(height: 16),
                                _buildLoginLink(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            AnimatedBuilder(
              animation: _bgAnimController,
              builder: (_, __) => Container(
                width: 64,
                height: 64,
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
                      blurRadius: 18 +
                          math.sin(_bgAnimController.value * 2 * math.pi) * 5,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text('SkyFit Pro',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 4),
            Text('CREATE YOUR ACCOUNT',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
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
        ),
      ],
    );
  }

  Widget _buildForm(AuthViewModel authVM) {
    final strength = _passwordStrength(_passwordText);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.03)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Badge ────────────────────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                      width: 1),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF00D4FF), size: 12),
                  SizedBox(width: 6),
                  Text('Personalized · Weather-Powered · Smart',
                      style: TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // ── Profile Photo Picker ─────────────────────────────────────
            _buildPhotoPickerRow(),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 18),

            // ── Fields ───────────────────────────────────────────────────
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              if (isWide) {
                return Column(children: [
                  Row(children: [
                    Expanded(
                        child: _field(_nameCtrl, 'Full Name',
                            Icons.person_outline_rounded,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) =>
                                v!.isEmpty ? 'Name is required' : null)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_emailCtrl, 'Email Address',
                            Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) =>
                                !v!.contains('@') ? 'Invalid email' : null)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _field(_ageCtrl, 'Age', Icons.cake_outlined,
                            keyboardType: TextInputType.number, validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 1 || n > 120)
                          ? 'Invalid age'
                          : null;
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_weightCtrl, 'Weight (kg)',
                            Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number, validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n < 1) ? 'Invalid weight' : null;
                    })),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _buildDropdown(
                            'Gender',
                            Icons.person_2_outlined,
                            _gender,
                            [
                              'Male',
                              'Female',
                              'Non-binary',
                              'Prefer not to say'
                            ],
                            (v) => setState(() => _gender = v))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildDropdown(
                            'Fitness Goal',
                            Icons.flag_outlined,
                            _fitnessGoal,
                            [
                              'Lose Weight',
                              'Build Muscle',
                              'Stay Active',
                              'Improve Endurance'
                            ],
                            (v) => setState(() => _fitnessGoal = v))),
                  ]),
                ]);
              }
              return Column(children: [
                _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) => v!.isEmpty ? 'Name is required' : null),
                const SizedBox(height: 12),
                _field(
                    _emailCtrl, 'Email Address', Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) =>
                        !v!.contains('@') ? 'Invalid email' : null),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _field(_ageCtrl, 'Age', Icons.cake_outlined,
                          keyboardType: TextInputType.number, validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 1 || n > 120)
                        ? 'Invalid age'
                        : null;
                  })),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_weightCtrl, 'Weight (kg)',
                          Icons.monitor_weight_outlined,
                          keyboardType: TextInputType.number, validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n < 1) ? 'Invalid weight' : null;
                  })),
                ]),
                const SizedBox(height: 12),
                _buildDropdown(
                    'Gender',
                    Icons.person_2_outlined,
                    _gender,
                    ['Male', 'Female', 'Non-binary', 'Prefer not to say'],
                    (v) => setState(() => _gender = v)),
                const SizedBox(height: 12),
                _buildDropdown(
                    'Fitness Goal',
                    Icons.flag_outlined,
                    _fitnessGoal,
                    [
                      'Lose Weight',
                      'Build Muscle',
                      'Stay Active',
                      'Improve Endurance'
                    ],
                    (v) => setState(() => _fitnessGoal = v)),
              ]);
            }),
            const SizedBox(height: 12),

            // ── Password ─────────────────────────────────────────────────
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDeco('Password', Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  )),
              validator: (v) => !_passwordRegex.hasMatch(v ?? '')
                  ? 'Min 8 chars, upper, lower, number, special char'
                  : null,
            ),
            const SizedBox(height: 10),
            _buildStrengthBar(strength),
            const SizedBox(height: 12),

            // ── Confirm Password ─────────────────────────────────────────
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration:
                  _inputDeco('Confirm Password', Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF6B7280),
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      )),
              validator: (v) =>
                  v != _passwordText ? 'Passwords do not match' : null,
            ),

            if (authVM.errorMessage != null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: authVM.clearError,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFF4D6D).withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFFF4D6D), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(authVM.errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFFFF4D6D), fontSize: 12))),
                    const Icon(Icons.close_rounded,
                        color: Color(0xFFFF4D6D), size: 14),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Create Account button ─────────────────────────────────────
            GestureDetector(
              onTapDown: (_) {
                if (!_isLoading) _buttonPressController.forward();
              },
              onTapUp: (_) {
                _buttonPressController.reverse();
                if (!_isLoading) _register();
              },
              onTapCancel: () => _buttonPressController.reverse(),
              child: AnimatedBuilder(
                animation: _buttonScaleAnim,
                builder: (_, child) => Transform.scale(
                    scale: _buttonScaleAnim.value, child: child),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _isLoading
                        ? const LinearGradient(
                            colors: [Color(0xFF374151), Color(0xFF374151)])
                        : const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight),
                    boxShadow: _isLoading
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
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Create Account',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 17),
                          ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Google Sign Up ────────────────────────────────────────────
            GestureDetector(
              onTap: _isLoading ? null : _signInWithGoogle,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1.2),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9)),
                      child: const Center(
                          child: Text('G',
                              style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 10),
                  Text('Sign up with Google',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo Picker Row ────────────────────────────────────────────────────
  Widget _buildPhotoPickerRow() {
    final nameText = _nameCtrl.text;
    final initials = nameText.isNotEmpty ? _getInitials(nameText) : '?';
    final hasPhoto = _profileImageBytes != null;

    return GestureDetector(
      onTap: _isPickingPhoto ? null : _showPhotoSourceSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.2), width: 1),
        ),
        child: Row(children: [
          Stack(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                      blurRadius: 14,
                      spreadRadius: 1)
                ],
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: Image.memory(
                        _profileImageBytes!,
                        fit: BoxFit.cover,
                        width: 72,
                        height: 72,
                      ),
                    )
                  : Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800))),
            ),
            if (_isPickingPhoto)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5)),
                  child: const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white)),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPickingPhoto
                        ? Colors.white.withValues(alpha: 0.3)
                        : const Color(0xFF00D4FF),
                    border:
                        Border.all(color: const Color(0xFF0D1117), width: 2)),
                child: Icon(
                    _isPickingPhoto
                        ? Icons.hourglass_top_rounded
                        : (hasPhoto ? Icons.edit_rounded : Icons.add_rounded),
                    color: Colors.white,
                    size: 11),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                hasPhoto ? 'Photo Selected' : 'Profile Photo',
                style: TextStyle(
                    color: hasPhoto ? const Color(0xFF4ADE80) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                hasPhoto ? 'Tap to change it' : 'Optional — tap to add a photo',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4ADE80), size: 12),
                  const SizedBox(width: 4),
                  Text('Ready to upload',
                      style: TextStyle(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ]),
          ),
          if (!_isPickingPhoto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: hasPhoto
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.1)
                      : const Color(0xFF00D4FF).withValues(alpha: 0.1),
                  border: Border.all(
                      color: hasPhoto
                          ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                          : const Color(0xFF00D4FF).withValues(alpha: 0.3))),
              child: Text(
                hasPhoto ? 'Change' : 'Add',
                style: TextStyle(
                    color: hasPhoto
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF00D4FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
    );
  }

  // FIX: value: → initialValue: (deprecated after Flutter 3.33)
  Widget _buildDropdown(String label, IconData icon, String? value,
      List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF0D1117),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: Colors.white.withValues(alpha: 0.4)),
      decoration: _inputDeco(label, icon),
      items:
          items.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildStrengthBar(double strength) {
    final reqs = [
      {'label': '8+ chars', 'met': _passwordText.length >= 8},
      {'label': 'Uppercase', 'met': _passwordText.contains(RegExp(r'[A-Z]'))},
      {'label': 'Number', 'met': _passwordText.contains(RegExp(r'[0-9]'))},
      {
        'label': 'Special',
        'met': _passwordText.contains(RegExp(r'[^a-zA-Z0-9]'))
      },
    ];
    final isEmpty = _passwordText.isEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isEmpty ? 0.0 : strength,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isEmpty ? Colors.transparent : _strengthColor(strength)),
                  minHeight: 5,
                ))),
        const SizedBox(width: 10),
        SizedBox(
            width: 60,
            child: Text(isEmpty ? '' : _strengthLabel(strength),
                textAlign: TextAlign.right,
                style: TextStyle(
                    color:
                        isEmpty ? Colors.transparent : _strengthColor(strength),
                    fontSize: 11,
                    fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 5,
        children: reqs.map((r) {
          final met = r['met'] as bool;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 11,
                color: met
                    ? const Color(0xFF4ADE80)
                    : Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 3),
            Text(r['label'] as String,
                style: TextStyle(
                    fontSize: 10,
                    color: met
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.25),
                    fontWeight: met ? FontWeight.w600 : FontWeight.w400)),
          ]);
        }).toList(),
      ),
    ]);
  }

  InputDecoration _inputDeco(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF00D4FF), size: 18)),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType,
      List<String>? autofillHints,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDeco(label, icon),
      validator: validator,
      onChanged: label == 'Full Name' ? (_) => setState(() {}) : null,
    );
  }

  Widget _buildLoginLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Already have an account? ',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text('Sign In',
            style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ),
    ]);
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
    final c1 = Offset(size.width * 0.85 + math.cos(a1) * 60,
        size.height * 0.15 + math.sin(a1) * 40);
    canvas.drawCircle(
        c1,
        260,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.2),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c1, radius: 260)));
    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.15 + math.cos(a2) * 60,
        size.height * 0.8 + math.sin(a2) * 40);
    canvas.drawCircle(
        c2,
        280,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.18),
            Colors.transparent
          ]).createShader(Rect.fromCircle(center: c2, radius: 280)));
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t;
}
