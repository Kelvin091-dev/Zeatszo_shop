import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'orders_channel',
      'Order Notifications',
      channelDescription: 'Notifications for new orders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Order',
      message.notification?.body ?? '',
      details,
    );
  }

  static Future<void> registerShopDeviceToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}
