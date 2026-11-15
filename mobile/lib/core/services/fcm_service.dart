import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

/// Firebase Cloud Messaging (FCM) Service
/// 100% Free on the Firebase Spark Plan (Unlimited push notifications)
class FcmService {
  static FirebaseMessaging? get _messaging {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  static String? _currentToken;
  static String? get currentToken => _currentToken;

  /// Initialize FCM listeners and request notification permissions
  static Future<void> initialize() async {
    final messaging = _messaging;
    if (messaging == null) {
      debugPrint('[FcmService] FirebaseMessaging not available in this environment.');
      return;
    }

    try {
      // 1. Request notification permissions (required on iOS and Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FcmService] User granted permission: ${settings.authorizationStatus}');

      // 2. Retrieve FCM device token
      _currentToken = await messaging.getToken();
      if (_currentToken != null) {
        debugPrint('[FcmService] Device FCM Token: $_currentToken');
      }

      // 3. Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        debugPrint('[FcmService] FCM Token refreshed: $newToken');
      });

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FcmService] Received foreground message:');
        debugPrint('  Title: ${message.notification?.title}');
        debugPrint('  Body: ${message.notification?.body}');
        debugPrint('  Data: ${message.data}');
      });

      // 5. App opened from background message notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FcmService] Notification opened app with data: ${message.data}');
      });
    } catch (e) {
      debugPrint('[FcmService] FCM initialization notice: $e');
    }
  }

  /// Associate FCM token with user profile in Firestore
  static Future<void> syncTokenWithUserProfile(String userId) async {
    if (_currentToken == null || userId.isEmpty) return;
    try {
      await FirestoreService.usersCol?.doc(userId).set({
        'fcm_token': _currentToken,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('[FcmService] Synced FCM token to user $userId');
    } catch (e) {
      debugPrint('[FcmService] Failed to sync FCM token: $e');
    }
  }

  /// Subscribe to specific topic (e.g. 'vendors', 'admin_alerts', 'orders')
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      debugPrint('[FcmService] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FcmService] subscribeToTopic error: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      debugPrint('[FcmService] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FcmService] unsubscribeFromTopic error: $e');
    }
  }
}
