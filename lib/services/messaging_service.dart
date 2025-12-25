import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles FCM device token registration and basic foreground handling.
class MessagingService {
  MessagingService._();

  /// Singleton instance.
  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Request notification permissions and register the device token
  /// under `users/{userId}.fcmToken`.
  ///
  /// Call this after a user successfully signs in.
  Future<void> initForUser(String userId) async {
    // Request permission (mainly for iOS / web).
    await _fcm.requestPermission();

    final token = await _fcm.getToken();
    if (token == null) return;

    await _db.collection('users').doc(userId).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}



