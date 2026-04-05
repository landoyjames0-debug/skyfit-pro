import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import 'auth/login_view.dart';
import '../services/local_auth_service.dart';

// ─── Theme helpers ────────────────────────────────────────────────────────────
class _T {
  _T._();

  static bool isDark(BuildContext ctx) {
    final authVM = ctx.read<AuthViewModel>();
    return authVM.themeMode == ThemeMode.dark ||
        (authVM.themeMode == ThemeMode.system &&
            MediaQuery.of(ctx).platformBrightness == Brightness.dark);
  }

  static Color textPrimary(bool dark) =>
      dark ? Colors.white : const Color(0xFF0F1923);
  static Color textSecondary(bool dark) =>
      dark ? const Color(0xFF8A9BB0) : const Color(0xFF5A6A7A);
  static Color textMuted(bool dark) =>
      dark ? const Color(0xFF4A5568) : const Color(0xFF9AA5B4);

  static Color scaffoldBg(bool dark) =>
      dark ? const Color(0xFF050810) : const Color(0xFFF0F4F8);
  static Color cardBg(bool dark) =>
      dark ? const Color(0xFF0D1117) : Colors.white;
  static Color cardBorder(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.09) : const Color(0xFFDDE4ED);
  static Color inputFill(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F9FC);
  static Color inputBorder(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.09) : const Color(0xFFCDD5DF);
  static Color divider(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);

  static const Color cyan = Color(0xFF00D4FF);
  static const Color violet = Color(0xFF7B61FF);
  static const Color green = Color(0xFF4ADE80);
  static const Color red = Color(0xFFFF4D6D);
  static const Color amber = Color(0xFFFFB547);
}

// ─── Session Timer Chip ───────────────────────────────────────────────────────
class _SessionTimerChip extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onTimeout;

  const _SessionTimerChip({
    super.key,
    required this.initialSeconds,
    required this.onTimeout,
  });

  @override
  State<_SessionTimerChip> createState() => _SessionTimerChipState();
}

class _SessionTimerChipState extends State<_SessionTimerChip> {
  late int _remaining;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _startTimer();
  }

  void resetTimer() {
    if (!mounted) return;
    setState(() => _remaining = widget.initialSeconds);
  }

  void _startTimer() {
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _chipColor {
    if (_remaining > 120) return _T.green;
    if (_remaining > 60) return _T.amber;
    return _T.red;
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

// ─── Reusable confirmation modal ──────────────────────────────────────────────
Future<bool> _showConfirmModal(
  BuildContext context, {
  required bool dark,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required String confirmLabel,
  required Color confirmColor,
  String cancelLabel = 'Cancel',
  Widget? extraContent,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
    pageBuilder: (ctx, _, __) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _T.cardBg(dark),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: iconColor.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 2),
              BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.55 : 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: dark ? 0.12 : 0.08),
                  border: Border.all(
                      color: iconColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _T.textPrimary(dark),
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _T.textSecondary(dark),
                      fontSize: 13,
                      height: 1.5)),
              if (extraContent != null) ...[
                const SizedBox(height: 16),
                extraContent,
              ],
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _T.inputFill(dark),
                          border: Border.all(color: _T.inputBorder(dark))),
                      child: Center(
                          child: Text(cancelLabel,
                              style: TextStyle(
                                  color: _T.textSecondary(dark),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [
                            confirmColor,
                            confirmColor.withValues(alpha: 0.75),
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: confirmColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: Center(
                          child: Text(confirmLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

// ─── ProfileView ──────────────────────────────────────────────────────────────
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isSaving = false;
  bool _biometricLoading = false;
  bool _isUploadingPhoto = false;

  Uint8List? _localImageBytes;

  String? _gender;
  String? _fitnessGoal;

  int _biometricFailCount = 0;
  static const int _maxBiometricAttempts = 3;
  static const int _sessionSeconds = 300;

  final _sessionTimerKey = GlobalKey<_SessionTimerChipState>();

  late final AnimationController _bgAnimController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserViewModel>().user;

    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _ageCtrl = TextEditingController(text: user?.age.toString() ?? '');
    _weightCtrl = TextEditingController(
      text: user?.weightKg != null
          ? (user!.weightKg == user.weightKg.truncateToDouble()
              ? user.weightKg.toInt().toString()
              : user.weightKg.toString())
          : '',
    );
    _gender = user?.gender;
    _fitnessGoal = user?.fitnessGoal;

    _bgAnimController =
        AnimationController(vsync: this, duration: const Duration(seconds: 16))
          ..repeat();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _loadBiometricState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _bgAnimController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSessionTimeout() {
    if (!mounted) return;
    final dark = _T.isDark(context);
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
              color: _T.cardBg(dark),
              borderRadius: BorderRadius.circular(26),
              border:
                  Border.all(color: _T.red.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: _T.red.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 2),
                BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.55 : 0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 20)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _T.red.withValues(alpha: 0.1),
                      border: Border.all(
                          color: _T.red.withValues(alpha: 0.3), width: 1.5)),
                  child: const Icon(Icons.lock_clock_rounded,
                      color: _T.red, size: 32)),
              const SizedBox(height: 20),
              Text('Session Expired',
                  style: TextStyle(
                      color: _T.textPrimary(dark),
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  'You were inactive for 5 minutes.\nYour session has been locked for security.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _T.textSecondary(dark),
                      fontSize: 13,
                      height: 1.6)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _T.red,
                      boxShadow: [
                        BoxShadow(
                            color: _T.red.withValues(alpha: 0.3),
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
                                  fontWeight: FontWeight.w700)),
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

  Future<void> _loadBiometricState() async {
    if (!mounted) return;
    final authVM = context.read<AuthViewModel>();
    final userVM = context.read<UserViewModel>();

    final available = await authVM.isBiometricAvailable();
    final enabled = await userVM.isBiometricEnabled();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    final dark = _T.isDark(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: isError ? _T.red : _T.green, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg, style: TextStyle(color: _T.textPrimary(dark)))),
      ]),
      backgroundColor: _T.cardBg(dark),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _showPhotoSourceSheet() async {
    if (_isUploadingPhoto) return;
    final dark = _T.isDark(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetCtx) => _PhotoSourceSheet(dark: dark, sheetCtx: sheetCtx),
    );
    if (source == null || !mounted) return;
    await _pickProfilePhoto(source);
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
          source: source, imageQuality: 90, maxWidth: 1024, maxHeight: 1024);
    } catch (_) {
      _showSnack(
          'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. Check permissions.',
          isError: true);
      return;
    }
    if (picked == null || !mounted) return;

    Uint8List? finalBytes;
    String? finalPath;

    if (kIsWeb) {
      try {
        finalBytes = await picked.readAsBytes();
      } catch (_) {
        _showSnack('Could not read image. Please try again.', isError: true);
        return;
      }
    } else {
      CroppedFile? cropped;
      try {
        cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 85,
          compressFormat: ImageCompressFormat.jpg,
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Crop Photo',
                toolbarColor: const Color(0xFF050810),
                toolbarWidgetColor: Colors.white,
                activeControlsWidgetColor: _T.cyan,
                backgroundColor: const Color(0xFF050810),
                lockAspectRatio: true),
            IOSUiSettings(
                title: 'Crop Photo',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false),
          ],
        );
      } catch (_) {
        _showSnack('Could not crop image. Please try again.', isError: true);
        return;
      }
      if (cropped == null || !mounted) return;
      finalBytes = await cropped.readAsBytes();
      finalPath = cropped.path;
    }

    if (!mounted) return;
    setState(() {
      _localImageBytes = finalBytes;
      _isUploadingPhoto = true;
    });

    final userVM = context.read<UserViewModel>();
    try {
      if (kIsWeb) {
        await userVM.updateProfilePictureFromBytes(finalBytes);
      } else {
        await userVM.updateProfilePicture(finalPath!);
      }
      if (!mounted) return;
      _showSnack('Profile photo updated!', isError: false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _localImageBytes = null);
      _showSnack('Upload failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _confirmSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final dark = _T.isDark(context);
    final confirmed = await _showConfirmModal(context,
        dark: dark,
        icon: Icons.save_outlined,
        iconColor: _T.cyan,
        title: 'Save Changes?',
        subtitle:
            "Your profile information will be updated with the new details you've entered.",
        confirmLabel: 'Save Changes',
        confirmColor: _T.cyan,
        extraContent: _buildChangeSummary(dark));
    if (!confirmed || !mounted) return;
    await _saveProfile();
  }

  Widget _buildChangeSummary(bool dark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _T.cyan.withValues(alpha: dark ? 0.06 : 0.04),
          border: Border.all(color: _T.cyan.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Changes to be saved',
            style: TextStyle(
                color: _T.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        _summaryRow(
            Icons.person_outline_rounded, 'Name', _nameCtrl.text.trim(), dark),
        _summaryRow(Icons.cake_outlined, 'Age', '${_ageCtrl.text} yrs', dark),
        _summaryRow(Icons.monitor_weight_outlined, 'Weight',
            '${_weightCtrl.text} kg', dark),
        if (_gender != null)
          _summaryRow(Icons.person_2_outlined, 'Gender', _gender!, dark),
        if (_fitnessGoal != null)
          _summaryRow(Icons.flag_outlined, 'Goal', _fitnessGoal!, dark),
      ]),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, color: _T.textMuted(dark), size: 13),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(color: _T.textSecondary(dark), fontSize: 12)),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: _T.textPrimary(dark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userVM = context.read<UserViewModel>();
      final weatherVM = context.read<WeatherViewModel>();
      await userVM.updateProfile({
        'fullName': _nameCtrl.text.trim(),
        'age': int.parse(_ageCtrl.text),
        'weightKg': double.parse(_weightCtrl.text),
        if (_gender != null) 'gender': _gender,
        if (_fitnessGoal != null) 'fitnessGoal': _fitnessGoal,
      });
      await weatherVM.fetchWeather(userVM.user);
      if (!mounted) return;
      final u = userVM.user;
      if (u != null) {
        _nameCtrl.text = u.fullName;
        _ageCtrl.text = u.age.toString();
        _weightCtrl.text = u.weightKg == u.weightKg.truncateToDouble()
            ? u.weightKg.toInt().toString()
            : u.weightKg.toString();
        _gender = u.gender;
        _fitnessGoal = u.fitnessGoal;
      }
      _showSnack('Profile updated successfully!', isError: false);
    } catch (_) {
      _showSnack('Failed to save profile. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmToggleBiometric(bool value) async {
    if (_biometricLoading) return;

    if (!_biometricAvailable) {
      _showSnack('Biometrics not available on this device.', isError: true);
      return;
    }

    final dark = _T.isDark(context);
    final confirmed = await _showConfirmModal(context,
        dark: dark,
        icon: Icons.fingerprint_rounded,
        iconColor: value ? _T.cyan : _T.amber,
        title: value
            ? (kIsWeb ? 'Register a Passkey?' : 'Enable Biometric Login?')
            : 'Disable Biometric Login?',
        subtitle: value
            ? (kIsWeb
                ? "Your browser will prompt you to create a passkey. You'll use it to sign in next time."
                : "You'll be able to sign in using your fingerprint or face ID.")
            : 'You will no longer be able to use biometrics to sign in.',
        confirmLabel: value ? (kIsWeb ? 'Register' : 'Enable') : 'Disable',
        confirmColor: value ? _T.cyan : _T.amber);
    if (!confirmed || !mounted) return;
    await _toggleBiometric(value);
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _biometricLoading = true);
    try {
      if (value) {
        if (kIsWeb) {
          // Web: register a new passkey via WebAuthn
          final uid = context.read<AuthViewModel>().currentUser?.uid;
          if (uid == null) {
            _showSnack('Could not identify user. Please sign in again.',
                isError: true);
            return;
          }
          final credId = await context
              .read<AuthViewModel>()
              .registerWebBiometric(uid, context.read<UserViewModel>());
          if (!mounted) return;
          if (credId == null) {
            _showSnack(
                'Passkey registration cancelled or failed. Please try again.',
                isError: true);
            return;
          }

          // Save biometric enabled to Firestore + local storage
          await context.read<UserViewModel>().toggleBiometric(true);
          if (!mounted) return;

          // FIX: Save last_user_uid to SharedPreferences so the login screen
          // can find it after logout and show the biometric button
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_user_uid', uid);
          if (!mounted) return;

          // Re-read from source of truth to confirm saved
          final confirmed =
              await context.read<UserViewModel>().isBiometricEnabled();
          if (!mounted) return;

          setState(() => _biometricEnabled = confirmed);
          _showSnack('Passkey registered! Use it to sign in next time.',
              isError: false);
        } else {
          // Mobile: verify biometric before enabling
          _biometricFailCount = 0;
          bool authenticated = false;

          // REPLACE WITH (new code)
          while (_biometricFailCount < _maxBiometricAttempts) {
            final result = await context
                .read<AuthViewModel>()
                .authenticateWithBiometrics();
            if (!mounted) return;

            if (result == BiometricResult.success) {
              authenticated = true;
              break;
            }

            if (result == BiometricResult.cancelled) {
              // User dismissed the prompt — exit silently, no count change
              return;
            }

            if (result == BiometricResult.locked) {
              _showSnack('Biometric locked. Please use your password.',
                  isError: true);
              return;
            }

            // BiometricResult.failed — real fingerprint rejection
            _biometricFailCount++;
            if (_biometricFailCount >= _maxBiometricAttempts) {
              _showSnack(
                  'Biometric failed $_maxBiometricAttempts times. Please use your password.',
                  isError: true);
              return;
            }
            final remaining = _maxBiometricAttempts - _biometricFailCount;
            _showSnack(
                'Biometric failed. $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
                isError: true);
          }

          if (!authenticated) return;

          // Save biometric enabled to Firestore + local storage
          await context.read<UserViewModel>().toggleBiometric(true);
          if (!mounted) return;

          // FIX: Save last_user_uid so login screen can show biometric button
          final uid = context.read<AuthViewModel>().currentUser?.uid;
          if (uid != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_user_uid', uid);
          }
          if (!mounted) return;

          final confirmed =
              await context.read<UserViewModel>().isBiometricEnabled();
          if (!mounted) return;

          setState(() => _biometricEnabled = confirmed);
          _showSnack('Biometric login enabled!', isError: false);
        }
      } else {
        // Disabling biometrics
        await context.read<UserViewModel>().updateProfile(
            {'biometricEnabled': false, 'webCredentialId': null});
        if (!mounted) return;

        // Also clear local storage
        await context.read<UserViewModel>().toggleBiometric(false);
        if (!mounted) return;

        final confirmed =
            await context.read<UserViewModel>().isBiometricEnabled();
        if (!mounted) return;

        setState(() => _biometricEnabled = confirmed);
        _showSnack('Biometric login disabled.', isError: false);
      }
    } catch (_) {
      await _loadBiometricState();
      _showSnack('Failed to update biometric setting.', isError: true);
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final dark = _T.isDark(context);
    final confirmed = await _showConfirmModal(context,
        dark: dark,
        icon: Icons.logout_rounded,
        iconColor: _T.red,
        title: 'Sign Out?',
        subtitle:
            "Your session will be securely ended. You'll need to sign in again.",
        confirmLabel: 'Yes, Sign Out',
        confirmColor: _T.red);
    if (!confirmed || !mounted) return;
    await _doLogout();
  }

  Future<void> _doLogout() async {
    final authVM = context.read<AuthViewModel>();
    final nav = Navigator.of(context);
    await authVM.signOut();
    if (!mounted) return;
    nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userVM = context.watch<UserViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final dark = authVM.themeMode == ThemeMode.dark ||
        (authVM.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final user = userVM.user;
    final isWide = size.width >= 800;

    return Scaffold(
      backgroundColor: _T.scaffoldBg(dark),
      body: Stack(children: [
        if (dark)
          _AnimatedBackground(controller: _bgAnimController, size: size)
        else
          _LightBackground(size: size),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: isWide
                  ? _buildWebLayout(context, user, authVM, dark, size)
                  : _buildMobileLayout(context, user, authVM, dark),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildWebLayout(
      BuildContext context, user, AuthViewModel authVM, bool dark, Size size) {
    return Column(children: [
      _buildTopBar(context, authVM, dark, isWeb: true),
      Expanded(
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _sessionTimerKey.currentState?.resetTimer(),
          onPointerMove: (_) => _sessionTimerKey.currentState?.resetTimer(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWebHero(user, dark),
                      const SizedBox(height: 24),
                      IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: _buildEditCard(dark)),
                              const SizedBox(width: 20),
                              Expanded(
                                  flex: 4,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildStatsCard(user, dark),
                                        const SizedBox(height: 16),
                                        _buildAccountCard(user, dark),
                                        const SizedBox(height: 16),
                                        _buildSecurityCard(dark),
                                        const SizedBox(height: 16),
                                        _buildPreferencesCard(authVM, dark),
                                      ])),
                            ]),
                      ),
                      const SizedBox(height: 20),
                      _buildSignOutButton(dark),
                    ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildMobileLayout(
      BuildContext context, user, AuthViewModel authVM, bool dark) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _sessionTimerKey.currentState?.resetTimer(),
      onPointerMove: (_) => _sessionTimerKey.currentState?.resetTimer(),
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
              child: _buildTopBar(context, authVM, dark, isWeb: false)),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildMobileHero(user, dark))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildStatsRow(user, dark))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildEditCard(dark))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildSecurityCard(dark))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildPreferencesCard(authVM, dark))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: _buildSignOutButton(dark))),
          SliverToBoxAdapter(
              child:
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthViewModel authVM, bool dark,
      {required bool isWeb}) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWeb ? 32 : 20, 0, isWeb ? 32 : 20, 0),
      height: 68,
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: _T.divider(dark), width: 1)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: _T.inputFill(dark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.inputBorder(dark))),
            child: Icon(Icons.arrow_back_rounded,
                color: _T.textSecondary(dark), size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [_T.cyan, _T.violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: const Icon(Icons.fitness_center_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShaderMask(
            shaderCallback: (b) =>
                const LinearGradient(colors: [_T.cyan, _T.violet])
                    .createShader(b),
            child: Text(
              isWeb ? 'SkyFit Pro — My Profile' : 'My Profile',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        _SessionTimerChip(
          key: _sessionTimerKey,
          initialSeconds: _sessionSeconds,
          onTimeout: _onSessionTimeout,
        ),
      ]),
    );
  }

  Widget _buildWebHero(user, bool dark) {
    final initials = _getInitials(user?.fullName);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _T.cardBg(dark),
        border: Border.all(color: _T.cardBorder(dark)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: _showPhotoSourceSheet,
          child: Stack(children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_T.cyan, _T.violet]),
                  boxShadow: [
                    BoxShadow(
                        color: _T.cyan.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ]),
              child: _photoWidget(88, initials),
            ),
            Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _T.cyan,
                        border: Border.all(color: _T.cardBg(dark), width: 2.5)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 13))),
          ]),
        ),
        const SizedBox(width: 22),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.fullName ?? 'Athlete',
              style: TextStyle(
                  color: _T.textPrimary(dark),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15)),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: TextStyle(color: _T.textSecondary(dark), fontSize: 13)),
          if (user?.fitnessGoal != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: _T.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.green.withValues(alpha: 0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flag_outlined, color: _T.green, size: 12),
                const SizedBox(width: 5),
                Text(user!.fitnessGoal!,
                    style: const TextStyle(
                        color: _T.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ])),
        const SizedBox(width: 16),
        Row(children: [
          _webStatChip(_formatAge(user?.age), 'Age', _T.cyan, dark),
          const SizedBox(width: 10),
          _webStatChip(_formatWeight(user?.weightKg), 'Weight', _T.amber, dark),
          const SizedBox(width: 10),
          _webStatChip(user?.gender ?? '—', 'Gender', _T.violet, dark),
        ]),
      ]),
    );
  }

  Widget _webStatChip(String value, String label, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: dark ? 0.08 : 0.06),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: _T.textMuted(dark),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildMobileHero(user, bool dark) {
    final initials = _getInitials(user?.fullName);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _T.cardBg(dark),
          border: Border.all(color: _T.cardBorder(dark)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ]),
      child: Row(children: [
        GestureDetector(
          onTap: _showPhotoSourceSheet,
          child: Stack(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_T.cyan, _T.violet]),
                  boxShadow: [
                    BoxShadow(
                        color: _T.cyan.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1)
                  ]),
              child: _photoWidget(72, initials),
            ),
            Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _T.cyan,
                        border: Border.all(color: _T.cardBg(dark), width: 2)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 11))),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.fullName ?? 'Athlete',
              style: TextStyle(
                  color: _T.textPrimary(dark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(user?.email ?? '',
              style: TextStyle(color: _T.textSecondary(dark), fontSize: 12),
              overflow: TextOverflow.ellipsis),
          if (user?.fitnessGoal != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _T.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.green.withValues(alpha: 0.25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flag_outlined, color: _T.green, size: 11),
                const SizedBox(width: 4),
                Text(user!.fitnessGoal!,
                    style: const TextStyle(
                        color: _T.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ])),
      ]),
    );
  }

  Widget _photoWidget(double size, String initials) {
    if (_localImageBytes != null) {
      return ClipOval(
          child: Image.memory(_localImageBytes!,
              fit: BoxFit.cover, width: size, height: size));
    }
    final url = context.read<UserViewModel>().user?.profilePictureUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
          child: Image.network(url,
              fit: BoxFit.cover,
              width: size,
              height: size,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(
                    child: SizedBox(
                        width: size * 0.35,
                        height: size * 0.35,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.6))));
              },
              errorBuilder: (_, __, ___) => _initialsWidget(size, initials)));
    }
    return _initialsWidget(size, initials);
  }

  Widget _initialsWidget(double size, String initials) {
    return Center(
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.28,
                fontWeight: FontWeight.w800)));
  }

  String _formatAge(int? age) => age != null ? '$age yrs' : '—';
  String _formatWeight(double? kg) {
    if (kg == null) return '—';
    return kg == kg.truncateToDouble() ? '${kg.toInt()} kg' : '$kg kg';
  }

  Widget _buildStatsRow(user, bool dark) {
    final stats = [
      {'label': 'Age', 'value': _formatAge(user?.age), 'color': _T.cyan},
      {
        'label': 'Weight',
        'value': _formatWeight(user?.weightKg),
        'color': _T.amber
      },
      {'label': 'Gender', 'value': user?.gender ?? '—', 'color': _T.violet},
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final color = e.value['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _T.cardBg(dark),
                border: Border.all(color: _T.cardBorder(dark)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]),
            child: Column(children: [
              Text(e.value['value'] as String,
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(e.value['label'] as String,
                  style: TextStyle(
                      color: _T.textMuted(dark),
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCard(user, bool dark) {
    return _card(dark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardHeader('Stats Overview', Icons.bar_chart_rounded, _T.cyan, dark),
          const SizedBox(height: 12),
          _statRow('Age', _formatAge(user?.age), _T.cyan, dark),
          _divider(dark),
          _statRow('Weight', _formatWeight(user?.weightKg), _T.amber, dark),
          _divider(dark),
          _statRow('Gender', user?.gender ?? '—', _T.violet, dark),
          _divider(dark),
          _statRow('Category', user?.weightCategory ?? '—', _T.green, dark),
        ]));
  }

  Widget _buildAccountCard(user, bool dark) {
    return _card(dark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardHeader(
              'Account Info', Icons.account_circle_outlined, _T.violet, dark),
          const SizedBox(height: 12),
          _statRow('Email', user?.email ?? '—', _T.cyan, dark),
          _divider(dark),
          _statRow('Goal', user?.fitnessGoal ?? 'Not set', _T.green, dark),
        ]));
  }

  Widget _statRow(String label, String value, Color color, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(color: _T.textSecondary(dark), fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _divider(bool dark) => Container(height: 1, color: _T.divider(dark));

  Widget _buildEditCard(bool dark) {
    return _card(dark,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _cardHeader('Edit Profile', Icons.edit_outlined, _T.cyan, dark),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _isUploadingPhoto ? null : _showPhotoSourceSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _T.cyan.withValues(alpha: dark ? 0.04 : 0.03),
                      border: Border.all(
                          color: _T.cyan.withValues(alpha: 0.15), width: 1)),
                  child: Row(children: [
                    Stack(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [_T.cyan, _T.violet],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            boxShadow: [
                              BoxShadow(
                                  color: _T.cyan.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1)
                            ]),
                        child: _photoWidget(
                            52,
                            _getInitials(
                                context.read<UserViewModel>().user?.fullName)),
                      ),
                      if (_isUploadingPhoto)
                        Positioned.fill(
                            child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Colors.black.withValues(alpha: 0.45)),
                                child: const Center(
                                    child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white))))),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isUploadingPhoto
                                      ? _T.textMuted(dark)
                                      : _T.cyan,
                                  border: Border.all(
                                      color: _T.cardBg(dark), width: 1.5)),
                              child: Icon(
                                  _isUploadingPhoto
                                      ? Icons.hourglass_top_rounded
                                      : Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 9))),
                    ]),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              _isUploadingPhoto
                                  ? 'Uploading photo…'
                                  : 'Profile Photo',
                              style: TextStyle(
                                  color: _isUploadingPhoto
                                      ? _T.textMuted(dark)
                                      : _T.textPrimary(dark),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                              _isUploadingPhoto
                                  ? 'Please wait'
                                  : 'Tap to change your photo',
                              style: TextStyle(
                                  color: _T.textSecondary(dark), fontSize: 11)),
                        ])),
                    if (!_isUploadingPhoto)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _T.cyan.withValues(alpha: 0.1),
                            border: Border.all(
                                color: _T.cyan.withValues(alpha: 0.3))),
                        child: const Text('Change',
                            style: TextStyle(
                                color: _T.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Container(height: 1, color: _T.divider(dark))),
              _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded, dark,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Name is required' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(_ageCtrl, 'Age', Icons.cake_outlined, dark,
                        keyboardType: TextInputType.number, validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 120) ? 'Invalid age' : null;
                })),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_weightCtrl, 'Weight (kg)',
                        Icons.monitor_weight_outlined, dark,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true), validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 500)
                      ? 'Invalid weight'
                      : null;
                })),
              ]),
              const SizedBox(height: 12),
              _buildDropdown(dark,
                  label: 'Gender',
                  icon: Icons.person_2_outlined,
                  value: _gender,
                  items: ['Male', 'Female', 'Non-binary', 'Prefer not to say'],
                  onChanged: (v) => setState(() => _gender = v)),
              const SizedBox(height: 12),
              _buildDropdown(dark,
                  label: 'Fitness Goal',
                  icon: Icons.flag_outlined,
                  value: _fitnessGoal,
                  items: [
                    'Lose Weight',
                    'Build Muscle',
                    'Stay Active',
                    'Improve Endurance',
                  ],
                  onChanged: (v) => setState(() => _fitnessGoal = v)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _isSaving ? null : _confirmSaveProfile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _isSaving
                          ? LinearGradient(colors: [
                              _T.textMuted(dark),
                              _T.textMuted(dark),
                            ])
                          : const LinearGradient(colors: [_T.cyan, _T.violet]),
                      boxShadow: _isSaving
                          ? []
                          : [
                              BoxShadow(
                                  color: _T.cyan.withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5))
                            ]),
                  child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  Icon(Icons.save_outlined,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('Save Changes',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ])),
                ),
              ),
            ]));
  }

  Widget _buildDropdown(
    bool dark, {
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      style: TextStyle(color: _T.textPrimary(dark), fontSize: 14),
      dropdownColor: _T.cardBg(dark),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: _T.textMuted(dark).withValues(alpha: 0.6)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _T.textSecondary(dark), fontSize: 13),
        prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: _T.cyan, size: 17)),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: _T.inputFill(dark),
        isDense: false,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _T.inputBorder(dark))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _T.inputBorder(dark))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.cyan, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.red, width: 1.5)),
        errorStyle: const TextStyle(color: _T.red, fontSize: 10),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      items:
          items.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSecurityCard(bool dark) {
    final biometricActive = _biometricAvailable && _biometricEnabled;
    final biometricDisabled = !_biometricAvailable;

    String biometricSubtitle;
    if (!_biometricAvailable) {
      biometricSubtitle = kIsWeb
          ? 'Your browser does not support passkeys'
          : 'Not available on this device';
    } else if (kIsWeb) {
      biometricSubtitle = _biometricEnabled
          ? 'Passkey registered — used on login'
          : 'Tap to register a passkey for this browser';
    } else {
      biometricSubtitle = _biometricEnabled
          ? 'Enabled — shown on login screen'
          : 'Tap to enable fingerprint login';
    }

    return _card(dark,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _cardHeader('Security', Icons.security_rounded, _T.violet, dark),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _biometricLoading || biometricDisabled
                ? null
                : () => _confirmToggleBiometric(!_biometricEnabled),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: biometricActive
                      ? _T.cyan.withValues(alpha: dark ? 0.07 : 0.05)
                      : _T.inputFill(dark),
                  border: Border.all(
                      color: biometricActive
                          ? _T.cyan.withValues(alpha: 0.25)
                          : _T.inputBorder(dark))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: (biometricActive ? _T.cyan : _T.textMuted(dark))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    kIsWeb ? Icons.key_rounded : Icons.fingerprint_rounded,
                    color: biometricDisabled
                        ? _T.textMuted(dark)
                        : biometricActive
                            ? _T.cyan
                            : _T.textSecondary(dark),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        kIsWeb ? 'Passkey Login' : 'Biometric Login',
                        style: TextStyle(
                            color: biometricDisabled
                                ? _T.textMuted(dark)
                                : _T.textPrimary(dark),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        biometricSubtitle,
                        style: TextStyle(
                            color: biometricDisabled
                                ? _T.textMuted(dark)
                                : biometricActive
                                    ? _T.cyan.withValues(alpha: 0.8)
                                    : _T.textSecondary(dark),
                            fontSize: 11),
                      ),
                    ])),
                const SizedBox(width: 12),
                if (_biometricLoading)
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _T.cyan))
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 46,
                    height: 26,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: biometricActive ? _T.cyan : _T.inputBorder(dark),
                        boxShadow: biometricActive
                            ? [
                                BoxShadow(
                                    color: _T.cyan.withValues(alpha: 0.35),
                                    blurRadius: 8)
                              ]
                            : []),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: biometricActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4)
                              ])),
                    ),
                  ),
              ]),
            ),
          ),
        ]));
  }

  Widget _buildPreferencesCard(AuthViewModel authVM, bool dark) {
    return _card(dark,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _cardHeader('Preferences', Icons.tune_rounded, _T.violet, dark),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: authVM.toggleTheme,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: dark
                      ? _T.cyan.withValues(alpha: 0.07)
                      : _T.inputFill(dark),
                  border: Border.all(
                      color: dark
                          ? _T.cyan.withValues(alpha: 0.25)
                          : _T.inputBorder(dark))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: _T.violet.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: _T.violet,
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(dark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                              color: _T.textPrimary(dark),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                          dark
                              ? 'Switch to light theme'
                              : 'Switch to dark theme',
                          style: TextStyle(
                              color: _T.textSecondary(dark), fontSize: 11)),
                    ])),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 46,
                  height: 26,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: dark ? _T.violet : _T.inputBorder(dark),
                      boxShadow: dark
                          ? [
                              BoxShadow(
                                  color: _T.violet.withValues(alpha: 0.35),
                                  blurRadius: 8)
                            ]
                          : []),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment:
                        dark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4)
                            ])),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _T.inputFill(dark),
                border: Border.all(color: _T.inputBorder(dark))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: _T.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.info_outline_rounded,
                      color: _T.green, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('SkyFit Pro',
                        style: TextStyle(
                            color: _T.textPrimary(dark),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Version 1.0.0 · Weather-Powered Fitness',
                        style: TextStyle(
                            color: _T.textSecondary(dark), fontSize: 11)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _T.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _T.green.withValues(alpha: 0.25))),
                child: const Text('Latest',
                    style: TextStyle(
                        color: _T.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ]));
  }

  Widget _buildSignOutButton(bool dark) {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _T.red.withValues(alpha: dark ? 0.08 : 0.05),
            border:
                Border.all(color: _T.red.withValues(alpha: 0.35), width: 1.5)),
        child:
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout_rounded, color: _T.red, size: 18),
          SizedBox(width: 8),
          Text('Sign Out',
              style: TextStyle(
                  color: _T.red, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _card(bool dark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _T.cardBg(dark),
          border: Border.all(color: _T.cardBorder(dark)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.25 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ]),
      child: child,
    );
  }

  Widget _cardHeader(String title, IconData icon, Color color, bool dark) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              color: _T.textPrimary(dark),
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData icon, bool dark,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: _T.textPrimary(dark), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _T.textSecondary(dark), fontSize: 13),
        prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: _T.cyan, size: 17)),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: _T.inputFill(dark),
        isDense: false,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _T.inputBorder(dark))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _T.inputBorder(dark))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.cyan, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.red, width: 1.5)),
        errorStyle: const TextStyle(color: _T.red, fontSize: 10),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      validator: validator,
    );
  }
}

// ─── Photo source bottom sheet ────────────────────────────────────────────────
class _PhotoSourceSheet extends StatelessWidget {
  final bool dark;
  final BuildContext sheetCtx;
  const _PhotoSourceSheet({required this.dark, required this.sheetCtx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
          color: _T.cardBg(dark),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _T.cardBorder(dark), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.5 : 0.1),
                blurRadius: 40,
                offset: const Offset(0, -8))
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 14),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _T.textMuted(dark).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [_T.cyan, _T.violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          child: const Icon(Icons.camera_alt_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        Text('Update Profile Photo',
            style: TextStyle(
                color: _T.textPrimary(dark),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Choose a source to update your picture',
            style: TextStyle(color: _T.textSecondary(dark), fontSize: 12)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            if (!kIsWeb) ...[
              Expanded(
                  child: _sourceButton(
                      label: 'Camera',
                      icon: Icons.camera_alt_rounded,
                      color: _T.cyan,
                      dark: dark,
                      onTap: () =>
                          Navigator.of(sheetCtx).pop(ImageSource.camera))),
              const SizedBox(width: 12),
            ],
            Expanded(
                child: _sourceButton(
                    label: 'Gallery',
                    icon: Icons.photo_library_rounded,
                    color: _T.violet,
                    dark: dark,
                    onTap: () =>
                        Navigator.of(sheetCtx).pop(ImageSource.gallery))),
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
                  color: _T.inputFill(dark),
                  border: Border.all(color: _T.inputBorder(dark))),
              child: Center(
                  child: Text('Cancel',
                      style: TextStyle(
                          color: _T.textSecondary(dark),
                          fontSize: 14,
                          fontWeight: FontWeight.w600))),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _sourceButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: color.withValues(alpha: dark ? 0.08 : 0.06),
            border:
                Border.all(color: color.withValues(alpha: 0.3), width: 1.2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ─── Animated dark background ─────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _AnimatedBackground({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
            size: size, painter: _DarkOrbPainter(controller.value)));
  }
}

class _DarkOrbPainter extends CustomPainter {
  final double t;
  _DarkOrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final a1 = t * 2 * math.pi;
    final c1 = Offset(size.width * 0.85 + math.cos(a1) * 35,
        size.height * 0.1 + math.sin(a1) * 25);
    canvas.drawCircle(
        c1,
        180,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.2),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c1, radius: 180)));
    final a2 = t * 2 * math.pi + math.pi;
    final c2 = Offset(size.width * 0.1 + math.cos(a2) * 40,
        size.height * 0.7 + math.sin(a2) * 35);
    canvas.drawCircle(
        c2,
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.15),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: c2, radius: 200)));
  }

  @override
  bool shouldRepaint(_DarkOrbPainter old) => old.t != t;
}

// ─── Light mode background ────────────────────────────────────────────────────
class _LightBackground extends StatelessWidget {
  final Size size;
  const _LightBackground({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: size, painter: _LightBgPainter());
}

class _LightBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.05),
        220,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF00D4FF).withValues(alpha: 0.06),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(
              center: Offset(size.width * 0.9, size.height * 0.05),
              radius: 220)));
    canvas.drawCircle(
        Offset(size.width * 0.05, size.height * 0.85),
        200,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF7B61FF).withValues(alpha: 0.05),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(
              center: Offset(size.width * 0.05, size.height * 0.85),
              radius: 200)));
  }

  @override
  bool shouldRepaint(_) => false;
}
