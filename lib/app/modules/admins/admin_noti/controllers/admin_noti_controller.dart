import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';
import 'package:frontend/app/widgets/noti_bell.dart';

/// Reactive state owner for [AdminNotiView].
///
/// Reads the signed-in admin's **personal inbox** from `GET /user-noti` — for
/// admins this surfaces incoming `booking_pending` requests fanned out by the
/// room-booking handler. Marks rows read via `PATCH /user-noti/:id/read`. The
/// composed announcement *history* lives in the announcement module, not here.
class AdminNotiController extends GetxController {
  /// Currently selected filter chip index — 0 = All, 1 = Academic,
  /// 2 = Room Booking. Bound to the chip row in the view.
  final RxInt selectedFilterIndex = 0.obs;

  /// `true` while the initial load is in flight.
  final RxBool isLoading = false.obs;

  /// User-facing error message from the last load; empty when there is none.
  final RxString errorMessage = ''.obs;

  /// The current user's inbox rows, newest first.
  final RxList<UserNotiModel> notifications = <UserNotiModel>[].obs;

  Dio get _dio => ApiClient.dio;

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
      final response =
          await _dio.get('/user-noti', queryParameters: {'limit': 100});
      notifications.assignAll(
        _extractList(response.data)
            .map((j) => UserNotiModel.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort(_byNewestFirst),
      );
      notiBadge.setCount(unreadCount);
    } on DioException catch (e) {
      debugPrint('AdminNoti Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      errorMessage.value = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : 'Failed to load notifications.';
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
      await _dio.patch('/user-noti/$userNotiId/read');
    } on DioException catch (e) {
      debugPrint('markAsRead failed for $userNotiId: ${e.message}');
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

    if (isUrgent) {
      return {
        'id': n.id,
        'unread': n.isRead == 0,
        'type': 'Urgent',
        'category': category,
        'title': title,
        'sub': message,
        'status': 'Urgent',
        'time': time,
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
    };
  }

  /// Sort comparator: newest first. Prefers the inbox row's own timestamp,
  /// falls back to the parent notification's, then to row id (monotonic) so
  /// missing timestamps and ties still order deterministically. The backend
  /// is supposed to return rows in this order, but ordering it client-side
  /// keeps the "newest first" guarantee even if it doesn't.
  static int _byNewestFirst(UserNotiModel a, UserNotiModel b) {
    final epoch = DateTime(2000);
    final at = a.createAt ?? a.notification?.createdAt ?? epoch;
    final bt = b.createAt ?? b.notification?.createdAt ?? epoch;
    final cmp = bt.compareTo(at);
    return cmp != 0 ? cmp : b.id.compareTo(a.id);
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
