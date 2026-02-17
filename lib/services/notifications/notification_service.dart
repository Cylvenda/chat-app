import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chatting_app/firebase_options.dart';

const AndroidNotificationChannel _defaultAndroidChannel =
    AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages.',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _chatRoomsSubscription;

  bool _initialized = false;
  String? _lastUserId;
  String? _lastFcmToken;
  bool _isFirstChatSnapshot = true;
  final Set<String> _seenChatUpdates = <String>{};

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestNotificationPermission();
    await _initializeLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened: ${message.messageId}');
    });

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        await _syncTokenForUser(user);
        await _syncChatRoomListener(user);
      },
    );

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      _lastFcmToken = token;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? _lastUserId;
      if (userId == null || token.isEmpty) return;
      await _saveTokenForUser(userId, token);
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    await _syncTokenForUser(currentUser);
    await _syncChatRoomListener(currentUser);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authStateSubscription?.cancel();
    await _chatRoomsSubscription?.cancel();
  }

  Future<void> _requestNotificationPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosInitSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotificationsPlugin.initialize(initSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_defaultAndroidChannel);
  }

  Future<void> _syncTokenForUser(User? user) async {
    if (user == null) {
      if (_lastUserId != null && _lastFcmToken != null) {
        await _removeTokenForUser(_lastUserId!, _lastFcmToken!);
      }
      _lastUserId = null;
      return;
    }

    _lastUserId = user.uid;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    _lastFcmToken = token;
    await _saveTokenForUser(user.uid, token);
  }

  Future<void> _syncChatRoomListener(User? user) async {
    await _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = null;
    _isFirstChatSnapshot = true;
    _seenChatUpdates.clear();

    if (user == null) return;

    _chatRoomsSubscription = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) async {
          for (final doc in snapshot.docs) {
            final data = doc.data();

            final unreadCounts = data['unreadCounts'];
            final unreadForCurrentUser =
                unreadCounts is Map<String, dynamic>
                    ? (unreadCounts[user.uid] as num?)?.toInt() ?? 0
                    : 0;

            final lastSenderId = data['lastSenderID']?.toString();
            final lastMessage = data['lastMessage']?.toString() ?? '';
            final senderEmail =
                data['lastSenderEmail']?.toString() ?? 'New message';
            final timestamp = data['lastMessageTimestamp'];
            if (timestamp is! Timestamp) continue;

            final eventKey = '${doc.id}:${timestamp.millisecondsSinceEpoch}';

            if (_isFirstChatSnapshot) {
              _seenChatUpdates.add(eventKey);
              continue;
            }

            if (_seenChatUpdates.contains(eventKey)) continue;
            _seenChatUpdates.add(eventKey);

            if (unreadForCurrentUser <= 0) continue;
            if (lastSenderId == user.uid) continue;
            if (lastMessage.isEmpty) continue;

            await _localNotificationsPlugin.show(
              eventKey.hashCode,
              senderEmail,
              lastMessage,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _defaultAndroidChannel.id,
                  _defaultAndroidChannel.name,
                  channelDescription: _defaultAndroidChannel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: const DarwinNotificationDetails(),
              ),
            );
          }

          _isFirstChatSnapshot = false;
        });
  }

  Future<void> _saveTokenForUser(String userId, String token) async {
    await FirebaseFirestore.instance.collection('Users').doc(userId).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _removeTokenForUser(String userId, String token) async {
    await FirebaseFirestore.instance.collection('Users').doc(userId).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;

    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'New chat';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'You received a new message.';

    final androidDetails = AndroidNotificationDetails(
      _defaultAndroidChannel.id,
      _defaultAndroidChannel.name,
      channelDescription: _defaultAndroidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      details,
      payload: message.data.toString(),
    );
  }
}
