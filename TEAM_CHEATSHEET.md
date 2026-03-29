# SkyFit Pro Team Cheatsheet & Study Guide

## Project Overview

Weather-powered fitness app using Flutter + Firebase + GCP. Features biometric auth, personalized activity suggestions, MVVM architecture.

## Team Roles Matrix

| Member | Name                   | Role                           | Key Responsibilities                           |
| ------ | ---------------------- | ------------------------------ | ---------------------------------------------- |
| M1     | Christian Ville Ranque | **Lead Architect & Auth Core** | MVVM setup, Google Sign-In, AuthViewModel      |
| M2     | Antonio Uy             | **Security & Biometrics**      | local_auth, flutter_secure_storage, encryption |
| M3     | Joemarie Estologa      | **DevOps & Cloud (GCP)**       | Docker, Cloud Run, CI/CD, secrets              |
| M4     | Stephen Pusta          | **Profile & Logic**            | Custom Sign-Up, Activity Engine, Firestore     |
| M5     | Nicole James Landoy    | **UI/UX & Integration**        | Views (Login/Register/Profile), transitions    |

## 🎯 M1: Christian Ville Ranque - Lead Architect & Auth Core

```
📁 Core Files:
├── lib/viewmodels/auth_viewmodel.dart (StreamBuilder + state)
├── lib/views/auth/login_view.dart (Google + Email/Password)
├── lib/views/home_view.dart (Protected route)
└── Routing: Navigator.pushAndRemoveUntil()

🔧 Key Packages:
- firebase_auth: ^4.15.3
- google_sign_in: ^6.1.6
- provider: ^6.1.1

💡 Study Checklist:
- [ ] Provider.of<AuthViewModel>(context, listen: false)
- [ ] FirebaseAuth.instance.authStateChanges()
- [ ] signInWithCredential(GoogleAuthProvider.credential())
```

## 🔐 M2: Antonio Uy - Security & Biometrics

````
📁 Core Implementation:
├── local_auth 2.1.6 - Fingerprint/Face ID
├── flutter_secure_storage 9.0.0 - Token storage
└── ProfileView biometric toggle switch

🔧 Usage:
```dart
final localAuth = LocalAuthentication();
bool authenticated = await localAuth.authenticate(
  localizedReason: 'Unlock your profile',
  options: AuthenticationOptions(biometricOnly: true),
);
````

💡 Study Checklist:

- [ ] CanCheckBiometrics, GetAvailableBiometrics
- [ ] AES encryption for health data
- [ ] Secure token refresh logic

```

## ☁️ M3: Joemarie Estologa - DevOps & Cloud (GCP)
```

📦 Dockerfile (Multi-stage):

```dockerfile
# Stage 1: Build
FROM cirrusci/flutter:3.19.0 AS build
WORKDIR /app
COPY . .
RUN flutter pub get && flutter build web --release

# Stage 2: Production
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

🚀 Deployment Commands:

```bash
gcloud run deploy skyfit-pro \
  --source . \
  --allow-unauthenticated \
  --region us-central1
```

💡 Study Checklist:

- [ ] cloudbuild.yaml triggers
- [ ] Secret Manager → env vars
- [ ] Custom domain + SSL

```

## 🧠 M4: Stephen Pusta - Profile & Logic
```

📁 Activity Engine:
lib/services/activity_engine.dart

```dart
List<ActivitySuggestion> suggest({
  required WeatherModel weather,
  required UserModel user,
}) {
  // BMI calculation + weather-based suggestions
}
```

🔥 Custom Sign-Up Flow:

1. Email OTP verification
2. Firestore UserModel creation
3. Personalized health category

💡 Study Checklist:

- [ ] Firestore transactions for profile creation
- [ ] Weather → Activity mapping logic
- [ ] UserModel schema (age, weightKg, bmiCategory)

```

## 🎨 M5: Nicole James Landoy - UI/UX & Integration
```

📱 Key Views:
├── LoginView → Auth flows
├── RegisterView → Multi-step form + photo picker
├── ProfileView → Edit + biometric toggle
├── HomeView → Weather cards + Activity list
└── Smooth transitions (Hero + PageRouteBuilder)

✨ UI Components:

- Custom gradients (\_T.cyan → \_T.violet)
- Session timeout chip
- Animated backgrounds (\_DarkOrbPainter)

````

💡 Study Checklist:
- [ ] ImagePicker + ImageCropper integration
- [ ] Custom painters for gradients/orbs
- [ ] Responsive layouts (LayoutBuilder)

## 🛠 Quick Commands
```bash
# Analyze
flutter analyze

# Test
flutter test

# Build Web
flutter build web --release

# Deploy GCP
gcloud run deploy

# Local Auth Test
flutter run -d chrome --web-hostname localhost
````

## 📚 Additional Study Resources

1. [Firebase Auth Flutter Codelab](https://firebase.google.com/docs/auth/flutter/start)
2. [local_auth Plugin Docs](https://pub.dev/packages/local_auth)
3. [GCP Cloud Run Flutter](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-flutter-service)
4. [Provider MVVM Pattern](https://pub.dev/packages/provider#if-else-pattern)
5. [Flutter Custom Painters](https://flutter.dev/docs/development/ui/advanced/custom_painters)

**Team Sync Questions:**

- M1: \"How does AuthViewModel handle token refresh?\"
- M2: \"What happens after 3 failed biometric attempts?\"
- M3: \"Walk through the Cloud Build → Cloud Run flow\"
- M4: \"How does rain weather affect activity suggestions?\"
- M5: \"Show me the photo picker UX flow\"
