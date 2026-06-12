import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/data/data_exporter.dart';
import '../services/api_client.dart';
import 'app_shell.dart';

/// App-wide source of truth for the signed-in user's **unread notification
/// count**.
///
/// Reads from the per-user inbox (`GET /user-noti`) — the *same* data the
/// notification screens mark read via `PATCH /user-noti/:id/read`. Sourcing
/// the badge from this endpoint (rather than the global `/notifications`
/// broadcast/history list) is what keeps the red dot in sync: once a row is
/// read, the count drops instead of lingering.
///
/// The notification screens keep this in lockstep by calling [setCount] after
/// every fetch and mark-as-read, so the badge updates live without a refetch.
/// [fetchUnread] is the cold-start / refresh path (init, pull-to-refresh,
/// returning from the notification center).
class NotiBadgeController extends GetxController {
  /// Number of inbox rows with `is_read == 0`. Drives every bell badge.
  final RxInt unreadCount = 0.obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchUnread();
  }

  /// GET `/user-noti` and recompute [unreadCount]. Best-effort — a network
  /// failure leaves the last known value untouched so the badge never flickers
  /// to zero on a transient error.
  Future<void> fetchUnread() async {
    try {
      final resp = await _dio.get(
        '/user-noti',
        queryParameters: {'limit': 200},
      );
      unreadCount.value = _extractList(resp.data)
          .map((j) => UserNotiModel.fromJson(j as Map<String, dynamic>))
          .where((n) => n.isRead == 0)
          .length;
    } on DioException catch (e) {
      debugPrint('NotiBadge fetchUnread error: ${e.message}');
    }
  }

  /// Publish an authoritative count computed elsewhere (the notification
  /// screen already holds the full inbox, so it can update the badge without a
  /// round-trip). Clamped at zero.
  void setCount(int count) => unreadCount.value = count < 0 ? 0 : count;

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}

/// Lazily resolve the shared [NotiBadgeController], registering it (permanent)
/// on first use so every bell across the app reads one count.
NotiBadgeController get notiBadge {
  if (!Get.isRegistered<NotiBadgeController>()) {
    Get.put(NotiBadgeController(), permanent: true);
  }
  return Get.find<NotiBadgeController>();
}

/// Notification-bell bubble with a live unread badge, used in the header of
/// student / teacher screens.
///
/// Renders the standard [AppIconBubble] bell and overlays the shared unread
/// count from [notiBadge]. Tapping routes to [route] (the role's notification
/// center) and refreshes the count on return, so reads made there clear the
/// dot immediately.
class NotiBellButton extends StatelessWidget {
  /// Named route of the role's notification center (e.g. `/student-noti`).
  final String route;

  /// Optional tint for the bell glyph; defaults to the bubble's primary text.
  final Color? color;

  const NotiBellButton({super.key, required this.route, this.color});

  @override
  Widget build(BuildContext context) {
    final badge = notiBadge;
    return Obx(
      () => AppIconBubble(
        icon: Icons.notifications_none_rounded,
        color: color,
        semanticLabel: 'ການແຈ້ງເຕືອນ',
        badgeCount: badge.unreadCount.value,
        onTap: () async {
          await Get.toNamed(route);
          await badge.fetchUnread();
        },
      ),
    );
  }
}
