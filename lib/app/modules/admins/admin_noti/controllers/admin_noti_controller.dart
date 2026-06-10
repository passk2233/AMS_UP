import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';
import 'package:frontend/app/widgets/noti_bell.dart';

/// Reactive state owner for [AdminNotiView].
///
/// Reads the signed-in admin's **personal inbox** from `GET /user-noti` — for
/// admins this surfaces incoming `booking_pending` requests fanned out by the
/// room-booking handler. Marks rows read via `PATCH /user-noti/:id/read`. The
/// composed announcement *history* lives in the announcement module, not here.
class AdminNotiController extends GetxController {
  AdminNotiController({NotificationProvider? provider})
      : _noti = provider ?? NotificationProvider();

  /// Data-access seam for notifications.
  final NotificationProvider _noti;

  /// Currently selected filter chip index — 0 = All, 1 = Academic,
  /// 2 = Room Booking. Bound to the chip row in the view.
  final RxInt selectedFilterIndex = 0.obs;

  /// `true` while the initial load is in flight.
  final RxBool isLoading = false.obs;

  /// User-facing error message from the last load; empty when there is none.
  final RxString errorMessage = ''.obs;

  /// The current user's inbox rows, newest first.
  final RxList<UserNotiModel> notifications = <UserNotiModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// GET `/user-noti` and populate [notifications]. Errors map to a
  /// localized message in [errorMessage].
  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      notifications.assignAll(await _noti.fetchInbox());
      notiBadge.setCount(unreadCount);
    } on DioException catch (e) {
      debugPrint('AdminNoti Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບຫມົດອາຍຸ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.'
          : 'ບໍ່ສາມາດໂຫຼດການແຈ້ງເຕືອນໄດ້.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh / tab-activation hook.
  Future<void> refreshData() => fetchNotifications();

  /// Notifications projected to view-model maps, filtered by
  /// [selectedFilterIndex].
  List<Map<String, dynamic>> get filteredNotifications {
    final all = notifications.map(_toViewItem).toList();
    if (selectedFilterIndex.value == 0) return all;
    final category =
        selectedFilterIndex.value == 1 ? 'Academic' : 'Room Booking';
    return all.where((n) => n['category'] == category).toList();
  }

  /// Number of unread notifications.
  int get unreadCount => notifications.where((n) => n.isRead == 0).length;

  /// Optimistically marks an inbox row read locally and tells the backend.
  /// [userNotiId] is the `user_noti` row id (not the notification id).
  Future<void> markAsRead(int userNotiId) async {
    final idx = notifications.indexWhere((n) => n.id == userNotiId);
    if (idx == -1 || notifications[idx].isRead == 1) return;

    notifications[idx].isRead = 1;
    notifications.refresh();
    notiBadge.setCount(unreadCount);

    try {
      await _noti.markRead(userNotiId);
    } on DioException catch (e) {
      debugPrint('markAsRead failed for $userNotiId: ${e.message}');
    }
  }

  /// Marks the whole inbox read: optimistic local flip + badge clear, then
  /// one bulk `PATCH /user-noti/read-all`. On failure the list is re-fetched
  /// so the optimistic flip cannot drift from the server.
  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    for (final n in notifications) {
      n.isRead = 1;
    }
    notifications.refresh();
    notiBadge.setCount(0);

    try {
      await _noti.markAllRead();
    } on DioException catch (e) {
      debugPrint('markAllAsRead failed: ${e.message}');
      await fetchNotifications();
    }
  }

  /// Convert an inbox row into the loose view-model map consumed by the list
  /// items. The shape varies for urgent vs normal entries because urgent
  /// rows render a status pill in addition to the body.
  Map<String, dynamic> _toViewItem(UserNotiModel n) {
    final noti = n.notification;
    final typeRaw = (noti?.type ?? '').toLowerCase();
    final isUrgent = typeRaw == 'urgent';
    final category = typeRaw.contains('booking') ? 'Room Booking' : 'Academic';

    final ts = n.createAt ?? noti?.createdAt;
    final time =
        ts == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(ts.toLocal());
    final title = noti?.title ?? '';
    final message = noti?.message ?? '';

    // The full notification handed to NotificationDetailView on tap. Synthesize
    // a minimal stand-in if the row arrived without its parent preloaded, so a
    // tap still opens a readable (if sparse) detail instead of doing nothing.
    final model = noti ??
        NotificationModel(
          notiId: n.notiId,
          title: title,
          message: message,
          isRead: n.isRead,
          createdAt: ts,
        );

    if (isUrgent) {
      return {
        'id': n.id,
        'unread': n.isRead == 0,
        'type': 'Urgent',
        'category': category,
        'title': title,
        'sub': message,
        'status': 'ດ່ວນ',
        'time': time,
        'model': model,
        'timestamp': ts,
      };
    }
    return {
      'id': n.id,
      'unread': n.isRead == 0,
      'type': 'Normal',
      'category': category,
      'title': title,
      'desc': message,
      'time': time,
      'files': noti?.files,
      'model': model,
      'timestamp': ts,
    };
  }

}
