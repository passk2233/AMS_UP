import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Request permissions (required for iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        // Show a snackbar when a notification is received in the foreground
        Get.snackbar(
          message.notification?.title ?? 'New Notification',
          message.notification?.body ?? '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white,
          colorText: Colors.black87,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.notifications_active, color: Colors.blueAccent),
          boxShadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        );
      }
    });

    // 3. Handle background/terminated message taps
    // When the app is in the background and user taps on the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageTap(message);
    });

    // When the app is terminated and user taps on the notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state by notification');
      _handleMessageTap(initialMessage);
    }
  }

  static void _handleMessageTap(RemoteMessage message) {
    // Example: Handle navigation based on notification payload
    // if (message.data['type'] == 'booking_approved') {
    //   Get.toNamed('/approve');
    // }
    debugPrint("Handling notification tap: ${message.data}");
  }
}
