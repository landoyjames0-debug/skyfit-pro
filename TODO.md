# SkyFit Pro Bug Fixes & Lints - Analysis Complete

## flutter analyze Results (14 issues - all info/warnings, no errors):

- 1 warning: override_on_non_overriding_member (lib/main.dart:126)
- 13 info: const prefs, curly braces, build_context_sync, naming, unused_element

## Status: Ready for fixes

### 1. [ ] Fix compile error in main.dart

- Add missing import for SkyFitRouteFactory/SkyFitTransitionStyle

### 2. [ ] Fix NPE in WeatherViewModel.fetchWeather

- Guard ActivityEngine.suggest with user != null

### 3. [ ] Fix inconsistent Firebase usage in UserViewModel.updateProfilePicture

- Use injected services instead of raw Firebase

### 4. [ ] Document iOS Firebase config issue in firebase_options.dart

- Add comment; user to provide correct iOS values

### 5. [ ] Run flutter analyze & test

- Execute `flutter analyze`
- `flutter run`

### 6. [ ] Cleanup

- Close phantom VSCode tabs (skyfitpro MainActivity, duplicate google-services)

**Notes:** No new files created. Only precise edits to existing files.
