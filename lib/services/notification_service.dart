import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Sends push notifications via Firebase Cloud Messaging HTTP API.
///
/// IMPORTANT: Using the FCM server key directly from a client app is not
/// secure for production. The recommended approach is to send notifications
/// from a trusted backend or Cloud Functions. This implementation follows
/// your constraint of "no Cloud Functions" and demonstrates using the
/// HTTP API directly.
class NotificationService {
  NotificationService._();

  /// Singleton instance.
  static final NotificationService instance = NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Your Firebase server key for the legacy FCM HTTP API.
  ///
  /// Replace this with your actual key from the Firebase console.
  /// Consider loading this from a secure source, not hard-coding.
  static const String _fcmServerKey = 'YOUR_SERVER_KEY_HERE';

  /// Endpoint for the legacy FCM HTTP API.
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  /// Send a "order completed" notification to the user who owns [userId].
  ///
  /// - Looks up `users/{userId}.fcmToken`.
  /// - Sends a notification using the Firebase HTTP API if a token exists.
  Future<void> sendOrderCompletedNotification({
    required String userId,
    required String orderId,
  }) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) return;

    final token = data['fcmToken'] as String?;
    if (token == null || token.isEmpty) return;

    final payload = <String, dynamic>{
      'to': token,
      'notification': {
        'title': 'Order completed',
        'body': 'Your order $orderId has been marked as completed.',
      },
      'data': {
        'type': 'order_completed',
        'orderId': orderId,
      },
    };

    final response = await http.post(
      Uri.parse(_fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$_fcmServerKey',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      // In a real app, route this to logging/monitoring.
      // ignore: avoid_print
      print('FCM error: ${response.statusCode} ${response.body}');
    }
  }
}



