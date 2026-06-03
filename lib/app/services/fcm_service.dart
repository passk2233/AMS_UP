import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/noti_bell.dart';
import 'api_client.dart';
import 'auth_storage.dart';

/// Firebase Cloud Messaging lifecycle for the app.
///
/// Guarantees an **OS-visible** notification (one that pops and stays in the
/// system notification panel) in all three app states:
///
/// - **Foreground:** FCM does *not* auto-display on Android while the app is
///   open, so [_showForegroundSystemNotification] posts a local notification
///   on the same high-importance channel. iOS relies on the foreground
///   presentation options set in [init].
/// - **Background / terminated:** the OS builds the notification itself from
///   the backend's `notification` payload. Channel + icon defaults come from
///   `AndroidManifest.xml`. Taps route via [onMessageOpenedApp] /
///   [getInitialMessage].
///
/// Also owns permission, token sync/refresh, logout cleanup, role-based topic
/// subscriptions, and deep-link routing.
///
/// **Backend contract for `data` payloads:**
/// - `category`: one of `announcement` | `booking_approved` |
///   `booking_rejected` | `booking_pending` | `evaluation_due` |
///   `evaluation_result`.
/// - `target_id` (optional): record id the user might want to open.
/// - `noti_id` (optional): MySQL `notifications.noti_id`, used as a stable
///   local-notification id so re-delivery replaces instead of stacking.
class FCMService {
  FCMService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Posts OS notifications from inside the running app. This is the bridge
  /// that satisfies the "show in the system panel while foreground" rule on
  /// Android, where FCM will not display automatically.
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// High-importance Android channel. This id MUST stay in sync with:
  /// - `default_notification_channel_id` in `AndroidManifest.xml`
  /// - the backend Android payload `ChannelID` (`fcm.AMSAndroidChannelID`).
  /// A mismatch makes Android fall back to a low-importance channel that never
  /// produces a heads-up banner.
  static const _androidChannelId = 'ams_high_importance';
  static const _androidChannelName = 'AMS Alerts';
  static const _androidChannelDesc = 'Important AMS notifications';

  /// Prefix prepended to every role-derived FCM topic
  /// (e.g. `role_admin`, `role_teacher`, `role_student`).
  static const _roleTopicPrefix = 'role_';

  /// Number of APNS poll retries before we give up and skip the token fetch.
  static const _apnsRetryCount = 5;

  /// Delay between APNS polls.
  static const _apnsRetryDelay = Duration(milliseconds: 500);

  /// Bootstrap call invoked from `main()` before `runApp`.
  ///
  /// Wires the foreground / opened-app / token-refresh listeners, creates the
  /// Android high-importance channel, and asks the OS for notification
  /// permission. Token sync is deferred to [syncTokenIfNeeded] which the auth
  /// flow calls after a valid JWT exists.
  static Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Create the channel and wire local-notification taps before any message
    // can arrive.
    await _initLocalNotifications();

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

  /// Initialise [_localNotifications], create the Android high-importance
  /// channel, request the Android 13+ runtime grant, and replay any tap that
  /// launched the app from a local notification we posted earlier.
  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('ic_stat_ams');
    // firebase_messaging already prompts for permission, so don't double-ask
    // here — request flags are false on purpose.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      // Belt-and-braces with firebase_messaging's prompt for POST_NOTIFICATIONS.
      await androidImpl.requestNotificationsPermission();
    }

    // Cold start from tapping a local notification we posted in a previous
    // foreground session: route once the first frame is up.
    final launch =
        await _localNotifications.getNotificationAppLaunchDetails();
    final launchPayload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) &&
        launchPayload != null &&
        launchPayload.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _routeFromPayload(launchPayload),
      );
    }
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

  /// Foreground messages must still reach the system panel.
  ///
  /// On Android we post a local notification on the high-importance channel
  /// (FCM does not auto-display in foreground). On iOS the OS already presents
  /// the banner via the foreground presentation options from [init], so we do
  /// not post a duplicate. The category-tinted [AppSnackbar] is kept as a
  /// secondary in-app hint only.
  static void _handleForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title']?.toString();
    final body = n?.body ?? message.data['body']?.toString();

    // Data-only sync message with nothing to show — leave it to other handlers.
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    // A new notification just landed in this user's inbox — re-sync the unread
    // badge so the red-dot count goes up live without waiting for a navigation.
    notiBadge.fetchUnread();

    if (GetPlatform.isAndroid) {
      _showForegroundSystemNotification(message, title ?? 'AMS', body ?? '');
    }

    final category = message.data['category']?.toString() ?? '';
    final hintTitle = title ?? 'ການແຈ້ງເຕືອນໃໝ່';
    final hintBody = body ?? '';
    if (category.startsWith('booking_rejected')) {
      AppSnackbar.warning(hintBody, title: hintTitle);
    } else if (category.startsWith('booking_approved')) {
      AppSnackbar.success(hintBody, title: hintTitle);
    } else {
      AppSnackbar.info(hintBody, title: hintTitle);
    }
  }

  /// Post an OS notification from within the app (Android foreground bridge).
  /// The payload carries the full `data` map so a tap routes identically to a
  /// background/terminated FCM tap.
  static Future<void> _showForegroundSystemNotification(
    RemoteMessage message,
    String title,
    String body,
  ) {
    return _localNotifications.show(
      id: _stableNotificationId(message),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: 'ic_stat_ams',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// A 31-bit notification id. Prefers `noti_id` so re-delivery of the same
  /// notification replaces rather than stacks; falls back to the FCM message
  /// id, then the wall clock.
  static int _stableNotificationId(RemoteMessage message) {
    final notiId = int.tryParse(message.data['noti_id']?.toString() ?? '');
    if (notiId != null) return notiId & 0x7fffffff;
    final mid = message.messageId;
    if (mid != null) return mid.hashCode & 0x7fffffff;
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }

  /// Tap on a foreground/launch local notification — decode the JSON payload
  /// and route by category.
  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    _routeFromPayload(payload);
  }

  /// Decode a JSON-encoded `data` payload and route by its `category`.
  static Future<void> _routeFromPayload(String payload) async {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      await _routeToCategory(data['category']?.toString() ?? '');
    } catch (e) {
      debugPrint('FCM local payload route failed: $e');
    }
  }

  /// Tap from background / terminated state — route by category.
  static Future<void> _handleMessageTap(RemoteMessage message) async {
    await _routeToCategory(message.data['category']?.toString() ?? '');
  }

  /// Resolve [category] to a role-aware route and navigate there.
  static Future<void> _routeToCategory(String category) async {
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
