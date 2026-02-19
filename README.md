# Chatting App

A Flutter chat application with Firebase authentication, real-time messaging, unread counters, and notifications.

## Features

- Email/password authentication (register, login, forgot password)
- Real-time 1:1 chat using Cloud Firestore
- Existing chats list and all users list
- Unread message counts per conversation
- Push + local notifications via Firebase Cloud Messaging
- Light/Dark theme toggle (Provider)
- Cross-platform Flutter targets (Android, iOS, Web, Desktop)

## Tech Stack

- Flutter
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- flutter_local_notifications
- Provider

## Prerequisites

- Flutter SDK (matching `environment.sdk: ^3.10.8` in `pubspec.yaml`)
- Firebase project
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- Android Studio / Xcode (for mobile builds)

## Firebase Setup

1. Create a Firebase project.
2. Enable Authentication:
   - Go to **Authentication > Sign-in method**
   - Enable **Email/Password**
3. Create Firestore Database (production/test mode as needed).
4. Configure Cloud Messaging (FCM).
5. Add app platforms in Firebase (Android/iOS/Web as needed).
6. Generate Flutter Firebase options:

```bash
flutterfire configure
```

This updates `lib/firebase_options.dart`.

7. Ensure Android config file exists:
   - `android/app/google-services.json`

For iOS, add the `GoogleService-Info.plist` file in the iOS Runner project if you target iOS.

## Installation

```bash
flutter pub get
```

## Run the App

```bash
flutter run
```

## Project Structure

```text
lib/
  main.dart
  firebase_options.dart
  components/
  models/
  pages/
  provider/
  services/
    auth/
    chats/
    notifications/
  theme/
```

## Firestore Data Model (high-level)

- `Users/{uid}`
  - `uid`, `email`, `username`
  - `fcmToken`, `fcmTokens`, `fcmUpdatedAt`
- `chat_rooms/{sortedUidA_sortedUidB}`
  - `participants`, `lastMessage`, `lastMessageTimestamp`
  - `lastSenderID`, `lastSenderEmail`
  - `unreadCounts.{uid}`
- `chat_rooms/{roomId}/messages/{messageId}`
  - `senderID`, `senderEmail`, `receiverID`, `message`, `timestamp`

## Notifications

- Foreground notifications are shown using `flutter_local_notifications`.
- Background handling is configured through `FirebaseMessaging.onBackgroundMessage`.
- FCM tokens are stored per user in Firestore and synced on auth/token changes.

## Notes

- If Firebase is not configured, app startup will fail at `Firebase.initializeApp(...)`.
- Keep Firebase config files out of public repos when appropriate for your security policy.

## Testing

```bash
flutter test
```
