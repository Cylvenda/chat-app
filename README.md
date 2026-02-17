# Chatting App

Firebase-powered Flutter chat app with email/password authentication, user discovery, one-to-one real-time messaging and light/dark theme switching.

## Features

- Email/password sign up and login using Firebase Authentication
- Real-time user list from Firestore (`Users` collection)
- One-to-one real-time chat using Firestore subcollections
- Local notifications for new incoming chat updates while app is active
- Firebase Cloud Messaging (FCM) token sync per user/device
- Light and dark mode toggle via `Provider`
- Auth-gated app flow (logged-in users go directly to chat home)

## Tech Stack

- Flutter (Dart)
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Flutter Local Notifications
- Provider (state management for theme)

## Project Structure

```text
lib/
  components/            # Reusable UI widgets (bubble, button, drawer, text field, user tile)
  models/                # Data model(s), e.g. Message
  pages/                 # App screens (login, register, home, chat, settings)
  provider/              # Theme provider
  services/
    auth/                # Auth gate + auth service + login/register switcher
    chats/               # Firestore chat service
    notifications/       # FCM + local notification service
  theme/                 # Light and dark theme definitions
  firebase_options.dart  # FlutterFire generated Firebase config
  main.dart              # App entrypoint + Firebase initialization
```

## Firebase Data Model

### `Users` collection

Each authenticated user is written as:

```json
{
  "uid": "firebase-auth-uid",
  "email": "user@example.com",
  "fcmToken": "latest-device-token",
  "fcmTokens": ["token-1", "token-2"],
  "fcmUpdatedAt": "Firestore Timestamp"
}
```

### `chat_rooms/{sorted_uid1_uid2}/messages` subcollection

Each message document contains:

```json
{
  "senderID": "uid",
  "senderEmail": "sender@example.com",
  "receiverID": "uid",
  "message": "Hello",
  "timestamp": "Firestore Timestamp"
}
```

Chat room IDs are deterministic: the two user IDs are sorted and joined with `_`.

### `chat_rooms/{sorted_uid1_uid2}` document

Each chat room metadata document contains fields such as:

```json
{
  "participants": ["uidA", "uidB"],
  "lastMessage": "Hello",
  "lastMessageTimestamp": "Firestore Timestamp",
  "lastSenderID": "uidA",
  "lastSenderEmail": "sender@example.com",
  "unreadCounts": {
    "uidA": 0,
    "uidB": 1
  }
}
```

## Prerequisites

- Flutter SDK installed and on PATH
- Dart SDK (bundled with Flutter)
- Firebase project with:
  - Authentication (Email/Password) enabled
  - Cloud Firestore enabled
  - Cloud Messaging enabled
- Android Studio / Xcode (for mobile builds), depending on target platform

## Setup

1. Clone and enter the project:

```bash
git clone https://github.com/Cylvenda/chat-app.git
cd chat-app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase for your own project (recommended):

- Run FlutterFire CLI and regenerate `lib/firebase_options.dart`
- Replace platform config files as needed:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Ensure Email/Password auth is enabled in Firebase Console
- For iOS: open Xcode and enable:
  - `Push Notifications` capability
  - `Background Modes` -> `Remote notifications`

4. Notification behavior:

- Foreground/active app notifications are handled locally in `lib/services/notifications/notification_service.dart`.
- Closed/background push notifications require a backend sender (for example Firebase Cloud Functions) that sends FCM messages to tokens in `Users.fcmTokens`.

5. Run the app:

```bash
flutter run
```

## Notes and Current Limitations

- `lib/firebase_options.dart` is checked in and tied to a specific Firebase project; regenerate it for your own environment.
- Linux Firebase options are not configured in `DefaultFirebaseOptions.currentPlatform` (Linux throws `UnsupportedError`).
- `test/widget_test.dart` is still the default Flutter counter test and does not match this app’s UI.
- Push notifications for app background/terminated state are not automatically sent by Firestore writes alone; you must implement/send FCM from backend logic.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Suggested Next Improvements

- Add Firestore security rules and document them in this repository
- Replace default widget test with auth/chat flow tests
- Persist and display usernames from Firestore
- Add message timestamps/readability in UI
- Add a Cloud Function trigger on new messages to send FCM to receiver tokens
