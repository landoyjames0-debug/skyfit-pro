# 🏋️ SkyFit Pro

> **Your Personalized Fitness Companion** — A Flutter Web App with Secure Identity & Health System

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase)
![GCP](https://img.shields.io/badge/GCP-Cloud%20Run-4285F4?logo=google-cloud)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker)

URL OF OUR WEBAPP: https://skyfit-pro-122281417725.asia-east1.run.app/#/login
---

## 👥 Team Members

| Member | Name | Role | Responsibilities |
|--------|------|------|-----------------|
| M1 | Christian Ville Ranque | Lead Architect & Auth Core | MVVM structure & routing, Google Sign-In via Firebase Auth, AuthViewModel state management |
| M2 | Antonio Uy | Security & Biometrics | local_auth for Fingerprint/FaceID, flutter_secure_storage for tokens, data encryption at rest |
| M3 | Joemarie Estologa | DevOps & Cloud (GCP) | Multi-stage Dockerfile, GCP Cloud Run deployment, CI/CD via Cloud Build, secrets management |
| M4 | Stephen Pusta | Profile & Logic | Custom registration (Email, Password, Age, Weight), personalized health logic, Cloud Firestore |
| M5 | Nicole James Landoy | UI/UX & Integration | LoginView, RegisterView, ProfileView, smooth transitions, weather UI & health suggestions |

---

## 📁 Project Structure (Strict MVVM)

```
lib/
├── main.dart                    # Entry point (Auth Guard & Routes)
├── models/                      # Data Layer
│   ├── user_model.dart          # Profile: Name, Age, Weight, Bio-Auth Status
│   ├── weather_model.dart       # Weather data
│   └── activity_model.dart      # Health activity logic
├── views/                       # UI Layer
│   ├── auth/
│   │   ├── login_view.dart      # Email/Pass & Google Sign-In
│   │   └── register_view.dart   # Custom Registration
│   ├── home_view.dart           # Main Dashboard (Weather + Activities)
│   ├── profile_view.dart        # Edit Profile & Biometric Toggle
│   └── widgets/                 # Reusable Widgets
├── viewmodels/                  # Logic Layer
│   ├── auth_viewmodel.dart      # Login, Register, Google Auth, Biometrics
│   ├── user_viewmodel.dart      # Profile Management
│   └── weather_viewmodel.dart   # Weather & Activity Logic
├── repositories/                # Data Decision Layer
│   ├── auth_repository.dart     # Firebase Auth & Google Sign-In logic
│   └── weather_repository.dart  # API vs Cache logic
├── services/                    # External Services
│   ├── api_service.dart         # OpenWeatherMap
│   ├── local_auth_service.dart  # Biometrics (Fingerprint/Face)
│   ├── storage_service.dart     # Secure Storage (Tokens/Prefs)
│   └── firestore_service.dart   # User Profile Database
└── utils/
    └── env_config.dart          # Secure Keys
Dockerfile                       # Container Config
cloudbuild.yaml                  # GCP CI/CD Config
```

---

## 🚀 Features

- ✅ **Custom Registration** — Email, Password, Full Name, Age, Weight, Profile Picture
- ✅ **Google SSO** — Sign in with Google via Firebase Auth
- ✅ **Biometric Authentication** — Fingerprint/FaceID with 3-attempt fallback
- ✅ **Session Manager** — Auto-logout after 5 minutes of inactivity
- ✅ **Personalized Health Logic** — Activity suggestions based on Age + Weight + Weather
- ✅ **OpenWeatherMap Integration** — Real-time weather data
- ✅ **Dark Mode** — Toggle between light and dark theme
- ✅ **GCP Cloud Run Deployment** — Containerized with Docker, CI/CD via Cloud Build

---

## 🧠 Health Logic Algorithm

| Weather | Age Group | Weight Category | Suggested Activity |
|---------|-----------|-----------------|-------------------|
| Clear/Sunny | < 18 (Youth) | Any | Sprint Intervals / HIIT / Outdoor Circuit |
| Clear/Sunny | 18–34 (Young) | Normal/Athletic | Outdoor Running / HIIT / Cycling |
| Clear/Sunny | 35–49 (Middle) | Normal | Moderate Jog / Bodyweight Strength |
| Clear/Sunny | 50–64 (Senior) | Any | Morning Walk / Tai Chi / Balance Drills |
| Clear/Sunny | 65+ (Elderly) | Any | Slow Walk / Seated Tai Chi / Chair Yoga |
| Clear/Sunny | Any | Overweight | Brisk Walking / Light Cycling / Water Aerobics |
| Cloudy | Young/Middle | Normal | Jogging / Outdoor Cycling / Calisthenics |
| Cloudy | Senior/Elderly | Any | Light Walk / Chair Yoga / Gentle Stretching |
| Rain/Snow | Any | Any | Indoor Yoga / Bodyweight Circuit / Dance Workout |
| Extreme Heat | Any | Overweight/Senior | Swimming / Hydrated Light Stretching / Water Aerobics |
| Thunderstorm | Any | Any | Meditation / Home Pilates / Foam Rolling |
| Mist/Fog | Any | Any | Indoor Treadmill / Stationary Bike / Indoor Rowing |

---

## 🛠️ Running Locally

### Prerequisites
- Flutter SDK (≥ 3.0)
- Firebase CLI
- Docker (optional)
- Node.js

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/landoyjames0-debug/skyfit-pro.git
cd skyfit-pro

# 2. Install dependencies
flutter pub get

# 3. Create .env file with your keys
OPENWEATHER_API_KEY=your_openweather_key_here

# 4. Run the app
flutter run -d chrome
```

### Run with Docker

```bash
docker build -t skyfit-pro .
docker run -p 8080:8080 skyfit-pro
```

---

## ☁️ Deployment

- **Platform:** GCP Cloud Run
- **CI/CD:** Google Cloud Build (auto-triggered on push to `main`)
- **Container:** Docker multi-stage build (Flutter build → nginx serve)
- **Live URL:** *(Add your Cloud Run URL here)*

---

## 🔐 Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENWEATHER_API_KEY` | OpenWeatherMap API key |
| `FIREBASE_API_KEY` | Firebase Web API key |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase messaging sender ID |
| `FIREBASE_APP_ID` | Firebase app ID |

> ⚠️ Never commit `.env` or `firebase_options.dart` to the repository.

---

## 📚 Course Information

- **Subject:** ITMSD5
- **Laboratory:** T7/T8 — Flutter WebApp Secure Identity & Health System
- **Institution:** *(Your School Name)*
- **Academic Year:** 2025–2026
