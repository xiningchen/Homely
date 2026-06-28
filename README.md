# Homely

A mobile app for arranging stays with friends. A prototype.

## Getting Started

### Prerequisites

- Visual Studio Code
- Flutter SDK installed
- Android Studio with an Android emulator set up
- Firebase project configured

### Firebase Setup

This project requires Firebase configuration files that are not included in the repository for security reasons. To setup Firebase:

1. Create a Firebase project at firebase.google.com
2. Run `flutterfire configure` to generate `lib/firebase_options.dart`
3. Download `google-services.json` and place it in `android/app/`

### Running the App

1. Start your Android emulator via Android Studio or `Ctrl + Shift + P` → "Flutter: Launch Emulator"
2. Install dependencies
   `flutter pub get`
3. Run the app
   `flutter run`

## Versions

### v0.1.0 — Initial Prototype

- User authentication (signup, login, logout)
- Phone contacts integration
- Friend discovery — detects which contacts are already on Homely
- Friend requests (send, pending state)
- SMS invite for contacts not yet on Homely
- Bottom navigation (Explore, Friends, Chats, Profile)
