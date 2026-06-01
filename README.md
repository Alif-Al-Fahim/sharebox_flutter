# ShareBox Mobile — Setup Guide

## 🚀 Bangladesh Tool Sharing Platform

A production-ready Flutter app for renting and sharing tools across Bangladesh.

---

## 📋 Prerequisites

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Firebase account
- Android Studio / VS Code
- A physical Android device or emulator (API 21+)

---

## 🔥 Firebase Setup (REQUIRED)

### Step 1 — Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click "Add Project" → Name it `ShareBox`
3. Enable Google Analytics (optional)

### Step 2 — Enable Authentication

1. Firebase Console → Build → Authentication → Get Started
2. Enable **Email/Password**
3. Enable **Google** sign-in
   - Add your SHA-1 fingerprint (for Android):
     ```bash
     cd android && ./gradlew signingReport
     ```

### Step 3 — Set Up Firestore

1. Firebase Console → Build → Firestore Database → Create Database
2. Choose **Production mode** (rules are provided)
3. Select region: `asia-south1` (Mumbai — closest to Bangladesh)

### Step 4 — Set Up Firebase Storage

1. Firebase Console → Build → Storage → Get Started
2. Choose production mode
3. Select same region as Firestore

### Step 5 — Add Android App

1. Firebase Console → Project Settings → Add App → Android
2. Package name: `com.sharebox.bd`
3. App nickname: `ShareBox`
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### Step 6 — Add iOS App (optional)

1. Firebase Console → Project Settings → Add App → iOS
2. Bundle ID: `com.sharebox.bd`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`
5. In Xcode, add the file to the Runner target

### Step 7 — Update Firebase Config

Open `lib/config/firebase_config.dart` and replace all placeholder values with your actual Firebase config:

```dart
// Get these from: Firebase Console → Project Settings → Your Apps → SDK setup and configuration
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_ANDROID_API_KEY',
  appId: 'YOUR_ACTUAL_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
);
```

> **Tip:** Use the FlutterFire CLI to auto-generate this file:
> ```bash
> dart pub global activate flutterfire_cli
> flutterfire configure
> ```

### Step 8 — Deploy Security Rules

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools
firebase login

# Initialize (select Firestore + Storage)
firebase init

# Deploy rules
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## 📦 Install Dependencies

```bash
flutter pub get
```

---

## 🏃 Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d <device_id>
```

---

## 📁 Project Structure

```
lib/
├─ main.dart                    # App entry point, Firebase init, MultiProvider
├─ config/
│   └─ firebase_config.dart     # Firebase platform options ← REPLACE WITH YOURS
├─ theme/
│   └─ app_theme.dart           # Material 3 theme, colors, spacing
├─ models/
│   ├─ user_model.dart          # User data model
│   ├─ tool_model.dart          # Tool data model + categories
│   ├─ rental_model.dart        # Rental data model + status
│   └─ message_model.dart       # Message + ChatRoom models
├─ services/
│   ├─ auth_service.dart        # Firebase Auth operations
│   ├─ firestore_service.dart   # Firestore CRUD operations
│   ├─ storage_service.dart     # Firebase Storage + image picker
│   ├─ chat_service.dart        # Real-time chat operations
│   └─ recommendation_service.dart # AI-ready recommendation engine
├─ providers/
│   ├─ auth_provider.dart       # Auth state management
│   ├─ tool_provider.dart       # Tool state management
│   ├─ chat_provider.dart       # Chat state management
│   └─ rental_provider.dart     # Rental state management
├─ screens/
│   ├─ splash/splash_screen.dart
│   ├─ auth/
│   │   ├─ login_screen.dart
│   │   ├─ signup_screen.dart
│   │   └─ forgot_password_screen.dart
│   ├─ home/
│   │   ├─ main_screen.dart     # Bottom nav host
│   │   └─ home_screen.dart     # Tool feed + search + categories
│   ├─ tool_detail/tool_detail_screen.dart
│   ├─ add_tool/add_tool_screen.dart
│   ├─ chat/
│   │   ├─ chat_list_screen.dart
│   │   └─ chat_screen.dart
│   └─ profile/
│       ├─ profile_screen.dart
│       ├─ edit_profile_screen.dart
│       └─ my_rentals_screen.dart
└─ widgets/
    ├─ tool_card.dart           # Tool display card (grid + horizontal)
    ├─ gradient_button.dart     # Gradient CTA buttons
    ├─ custom_app_bar.dart      # Branded app bars
    └─ loading_indicator.dart   # Loaders, skeletons, empty states
```

---

## 🗄️ Firestore Collections

| Collection    | Purpose                        |
|---------------|-------------------------------|
| `/users`      | User profiles                 |
| `/tools`      | Tool listings                 |
| `/rentals`    | Rental requests & history     |
| `/chatRooms`  | Chat room metadata            |
| `/chatRooms/{id}/messages` | Real-time messages |

---

## 🤖 AI Recommendation System

The `RecommendationService` is fully AI-ready. To upgrade to real ML:

1. Replace `_computeRecommendations()` with an API call to your ML model
2. Suggested integrations:
   - **Google Vertex AI** (Recommendations AI)
   - **OpenAI Embeddings** + cosine similarity
   - **Firebase ML Kit**
   - Custom Python FastAPI model on Cloud Run

---

## 🎨 Brand Colors

| Token     | Hex       | Usage              |
|-----------|-----------|--------------------|
| Primary   | `#0A84FF` | Buttons, links     |
| Secondary | `#0FB9B1` | Accents, chips     |
| Success   | `#34C759` | Available status   |
| Error     | `#FF3B30` | Errors, cancel     |
| Warning   | `#FF9500` | Pending status     |

---

## 🌐 Supported Locations in Bangladesh

Dhaka, Gazipur, Savar, Narayanganj, Tongi, Narsingdi, Chittagong, Sylhet, Rajshahi, Khulna, Barisal, Rangpur, Mymensingh, Comilla, and more.

---

## 📜 License

MIT License — Made with ❤️ for Bangladesh
