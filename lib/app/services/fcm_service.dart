import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import '../widgets/app_snackbar.dart';
import 'api_client.dart';
import 'auth_storage.dart';

/// Firebase Cloud Messaging lifecycle for the app.
///
/// Handles permission, foreground banner, token refresh, logout cleanup,
/// role-based topic subscriptions, and deep-link routing for taps from
/// background / terminated state.
///
/// **Backend contract for `data` payloads:**
/// - `category`: one of `announcement` | `booking_approved` |
///   `booking_rejected` | `booking_pending` | `evaluation_due` |
///   `evaluation_result`.
/// - `target_id` (optional): record id the user might want to open.
class FCMService {
  FCMService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Prefix prepended to every role-derived FCM topic
  /// (e.g. `role_admin`, `role_teacher`, `role_student`).
  static const _roleTopicPrefix = 'role_';

  /// Number of APNS poll retries before we give up and skip the token fetch.
  static const _apnsRetryCount = 5;

  /// Delay between APNS polls.
  static const _apnsRetryDelay = Duration(milliseconds: 500);

  /// Bootstrap call invoked from `main()` before `runApp`.
  ///
  /// Wires the foreground / opened-app / token-refresh listeners and asks
  /// the OS for notification permission. Token sync is deferred to
  /// [syncTokenIfNeeded] which the auth flow calls after a valid JWT
  /// exists.
  static Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // iOS: show banner+sound+badge for foreground messages too (defaults to
    // none, which is why iOS users miss notifications when the app is open).
    if (GetPlatform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Defer so GetMaterialApp has finished mounting before we navigate.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleMessageTap(initial),
      );
    }

    _messaging.onTokenRefresh.listen(_syncTokenToBackend);

    // If a JWT is already in storage (warm start with a logged-in user),
    // push the current token now — getToken() may have produced a value
    // after the initial login already POSTed.
    await syncTokenIfNeeded();
  }

  /// Push the current FCM token to the backend if a valid JWT exists.
  /// Safe to call multiple times — idempotent on the backend side.
  static Future<void> syncTokenIfNeeded() async {
    try {
      final token = await _fetchToken();
      if (token == null) return;
      await _syncTokenToBackend(token);
    } catch (e) {
      debugPrint('FCM syncTokenIfNeeded failed: $e');
    }
  }

  /// Subscribe the device to `role_<role>` topics for every recognized
  /// role in [roles]. Unknown roles are silently dropped.
  static Future<void> subscribeRoleTopics(List<String> roles) async {
    for (final r in _normalizeRoles(roles)) {
      try {
        await _messaging.subscribeToTopic('$_roleTopicPrefix$r');
      } catch (e) {
        debugPrint('subscribeToTopic($r) failed: $e');
      }
    }
  }

  /// Inverse of [subscribeRoleTopics]; safe to call with any role list.
  static Future<void> unsubscribeRoleTopics(List<String> roles) async {
    for (final r in _normalizeRoles(roles)) {
      try {
        await _messaging.unsubscribeFromTopic('$_roleTopicPrefix$r');
      } catch (e) {
        debugPrint('unsubscribeFromTopic($r) failed: $e');
      }
    }
  }

  /// Tell the backend to forget this device's token, unsubscribe role
  /// topics, and delete the local FCM token so a fresh one is issued on
  /// the next login.
  ///
  /// **Call this BEFORE clearing the JWT** from storage — the DELETE
  /// request still needs the auth header.
  static Future<void> clearTokenOnLogout() async {
    try {
      final jwt = await AuthStorage.readToken();
      final token = await _messaging.getToken();

      // Unsubscribe role topics for the current user before we lose roles.
      final roles = await AuthStorage.readRoles();
      await unsubscribeRoleTopics(roles);

      if (jwt != null && jwt.isNotEmpty && token != null) {
        try {
          await ApiClient.dio.delete(
            '/users/fcm-token',
            data: {'device_token': token},
          );
        } catch (e) {
          debugPrint('FCM token delete on backend failed: $e');
        }
      }

      // Drop the local token so a different user logging in on the same
      // device gets a fresh registration.
      try {
        await _messaging.deleteToken();
      } catch (e) {
        debugPrint('FCM deleteToken failed: $e');
      }
    } catch (e) {
      debugPrint('clearTokenOnLogout failed: $e');
    }
  }

  // ──────────────────────────────────── foreground / tap routing ──

  /// Foreground messages surface as an [AppSnackbar] tinted by category.
  static void _handleForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    final title = n.title ?? 'ການແຈ້ງເຕືອນໃໝ່';
    final body = n.body ?? '';
    final category = message.data['category']?.toString() ?? '';

    if (category.startsWith('booking_rejected')) {
      AppSnackbar.warning(body, title: title);
    } else if (category.startsWith('booking_approved')) {
      AppSnackbar.success(body, title: title);
    } else {
      AppSnackbar.info(body, title: title);
    }
  }

  /// Tap from background / terminated state — route by category.
  static Future<void> _handleMessageTap(RemoteMessage message) async {
    final category = message.data['category']?.toString() ?? '';
    final route = await _routeForCategory(category);
    if (route == null) return;
    Get.offAndToNamed(route);
  }

  /// Map a payload `category` to a destination route based on the
  /// currently signed-in user's roles. Returns `null` when no role matches.
  static Future<String?> _routeForCategory(String category) async {
    final roles = await AuthStorage.readRoles();
    final isAdmin = roles.any((r) => r == 'admin' || r == 'administrator');
    final isTeacher = roles.contains('teacher');
    final isStudent = roles.contains('student');

    switch (category) {
      case 'booking_approved':
      case 'booking_rejected':
      case 'booking_pending':
        if (isAdmin) return Routes.APPROVE;
        if (isTeacher) return Routes.BOOKING;
        if (isStudent) return Routes.BOOKING_STUDENT;
        return null;
      case 'evaluation_due':
        if (isStudent) return Routes.FACULTY_FEEDBACK;
        return _notiRouteFor(isAdmin, isTeacher, isStudent);
      case 'evaluation_result':
      case 'announcement':
      default:
        return _notiRouteFor(isAdmin, isTeacher, isStudent);
    }
  }

  static String? _notiRouteFor(bool isAdmin, bool isTeacher, bool isStudent) {
    if (isAdmin) return Routes.ADMIN_NOTI;
    if (isTeacher) return Routes.TEACHER_NOTI;
    if (isStudent) return Routes.STUDENT_NOTI;
    return null;
  }

  // ──────────────────────────────────────────────── token plumbing ──

  /// On iOS, the FCM token isn't available until APNS hands one back.
  /// Poll a few times before giving up so we don't silently skip the sync.
  static Future<String?> _fetchToken() async {
    if (GetPlatform.isIOS) {
      var apns = await _messaging.getAPNSToken();
      var tries = 0;
      while (apns == null && tries < _apnsRetryCount) {
        await Future.delayed(_apnsRetryDelay);
        apns = await _messaging.getAPNSToken();
        tries++;
      }
      if (apns == null) {
        debugPrint('APNS token not ready — skipping FCM token fetch');
        return null;
      }
    }
    return _messaging.getToken();
  }

  static Future<void> _syncTokenToBackend(String token) async {
    try {
      final jwt = await AuthStorage.readToken();
      if (jwt == null || jwt.isEmpty) return;

      // ApiClient handles auth header injection.
      await ApiClient.dio.put('/users/fcm-token', data: {
        'device_token': token,
        'platform': _platformId(),
      });
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  /// Short platform identifier sent to the backend so it can fan out FCM
  /// payloads with the correct schema (`apns` vs `gcm`).
  static String _platformId() {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    if (GetPlatform.isWeb) return 'web';
    return 'unknown';
  }

  /// Map free-form role strings to the canonical topic names. Drops any
  /// unrecognized entries.
  static Iterable<String> _normalizeRoles(List<String> roles) {
    final out = <String>{};
    for (final r in roles) {
      final lr = r.toLowerCase();
      if (lr == 'admin' || lr == 'administrator') {
        out.add('admin');
      } else if (lr == 'teacher' || lr == 'student') {
        out.add(lr);
      }
    }
    return out;
  }
}
