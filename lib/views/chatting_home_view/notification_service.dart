import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission for notifications
    await _messaging.requestPermission();

    // Configure local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    _showNotification(message);
  }

  static void _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data['userId'],
      );
    }
  }

  static Future<void> subscribeToUserTopic(String userId) async {
    await _messaging.subscribeToTopic(userId);
  }
}