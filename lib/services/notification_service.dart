import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static GlobalKey<ScaffoldMessengerState>? _messengerKey;
  static RemoteMessage? _pendingMessage;

  static Future<void> initialize(
    GlobalKey<ScaffoldMessengerState> messengerKey,
  ) async {
    _messengerKey = messengerKey;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    try {
      final token = await _messaging.getToken();
      debugPrint('Firebase Messaging token: $token');
    } catch (error) {
      debugPrint('Unable to get Firebase Messaging token: $error');
    }
    _messaging.onTokenRefresh.listen((refreshedToken) {
      debugPrint('Firebase Messaging token refreshed: $refreshedToken');
    });

    // Render foreground notifications in the app instead of showing a second
    // native notification banner on iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    _pendingMessage = await _messaging.getInitialMessage();
  }

  static void showPendingMessage() {
    final message = _pendingMessage;
    _pendingMessage = null;
    if (message != null) {
      _showForegroundMessage(message);
    }
  }

  static void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    final text = [
      title,
      body,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join('\n');

    if (text.isEmpty) return;

    final messenger = _messengerKey?.currentState;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static void _handleOpenedMessage(RemoteMessage message) {
    // The payload is available here for routing to a job or process screen.
    // Keep the notification visible until that route is implemented.
    _showForegroundMessage(message);
  }
}
