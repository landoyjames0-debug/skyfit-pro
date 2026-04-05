# Fix Error - Flutter Compile Issues ✅

## Plan Progress (Step-by-Step)

### Step 1: Fix primary compile error [✅ DONE]

- [x] Added `import 'dart:io';` to `lib/viewmodels/user_viewmodel.dart`
  - Fixed `File(filePath)` undefined method (mobile profile photo upload)

### Step 2: Fix deprecation warnings [✅ DONE]

- [x] Updated `DropdownButtonFormField.value → initialValue` in:
  - `lib/views/profile_view.dart`
  - `lib/views/register_view.dart`
- [x] Suppressed dart:js deprecation in `lib/services/biometric_web_service.dart`
- [x] Removed unused import `shared_preferences` in `lib/views/auth/login_view.dart`
- [x] Added `// ignore: avoid_print` to print calls

### Step 3: Verify fixes [IN PROGRESS]

- [ ] Run `flutter analyze`
- [ ] Run `flutter run -d chrome`

### Step 4: Test

- [ ] Test profile photo upload (mobile simulation + web)
- [ ] Test dropdowns in profile/register
- [ ] Test biometrics toggle

**Next**: Run `flutter analyze` to confirm 0 issues → test app → complete!
