# NeuroSocial App

A social network for neurodivergent people, built with Flutter and Firebase.

## Setup Instructions

### 1. Flutter Project
The project files are generated in the `neuro_social` directory. 
Since automation tools for `flutter create` were limited, you should run the following commands to complete the platform setup:

```bash
cd neuro_social
flutter pub get
```

**Important**: 
- If you see errors about missing android/ios folders, run `flutter create .` inside the `neuro_social` directory to generate them.
- Ensure you have the `firebase_core` configuration.

### 2. Firebase Configuration
1. Create a project in [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password).
3. Enable **Firestore Database**.
4. Enable **Storage**.
5. Install `firebase-tools` if you haven't: `npm install -g firebase-tools`.
6. Login: `firebase login`.
7. Configure Flutter apps:
   - **Android**: Download `google-services.json` and place in `android/app/`.
   - **iOS**: Download `GoogleService-Info.plist` and place in `ios/Runner/`.
   - Or use `flutterfire configure`.

### 3. Deploy Backend
Navigate to the root and deploy rules and functions:

```bash
firebase init
# Select Firestore, Storage, Functions, Emulators
# Use existing files when prompted (firestore.rules, etc.)

cd functions
npm install
npm run deploy
```

## Architecture
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Pattern**: Clean Architecture (Layered)
  - `domain`: Entities & Interfaces
  - `data`: Repositories & DTOs
  - `presentation`: Widgets & Providers

## Features
- **Discovery**: Custom swipe deck implementation.
- **Chat**: Real-time messaging with Firestore and Cloud Functions.
- **Events**: RSVP system and group chats.
- **Low Stimulation Mode**: Global theme toggle for accessibility.

## Performance Notes
- Lists are paginated using Firestore `limit` and `startAfter`.
- Images use `cached_network_image`.
