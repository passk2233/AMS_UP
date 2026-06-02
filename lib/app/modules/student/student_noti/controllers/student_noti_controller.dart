import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

/// Reactive state for [StudentNotiView].
///
/// Reads the signed-in student's **personal inbox** from `GET /user-noti`
/// (rows scoped to the current user, each with its parent notification
/// preloaded) and marks rows read via `PATCH /user-noti/:id/read`. The view
/// item's `id` is the `user_noti` row id, which is what mark-as-read needs.
class StudentNotiController extends GetxController {
  var selectedFilterIndex = 0.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// The current user's inbox rows, newest first.
  final RxList<UserNotiModel> notifications = <UserNotiModel>[].obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp =
          await _dio.get('/user-noti', queryParameters: {'limit': 100});
      notifications.assignAll(
        _extractList(resp.data)
            .map((j) => UserNotiModel.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      debugPrint('StudentNoti Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      errorMessage.value = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : 'Failed to load notifications.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Pull-to-refresh / tab-activation hook.
  Future<void> refreshData() => fetchNotifications();

  List<Map<String, dynamic>> get filteredNotifications {
    final all = notifications.map(_toViewItem).toList();
    if (selectedFilterIndex.value == 0) return all;

    final category =
        selectedFilterIndex.value == 1 ? "Academic" : "Room Booking";
    return all.where((n) => n['category'] == category).toList();
  }

  /// Count of items the user hasn't tapped yet. Drives badges.
  int get unreadCount => notifications.where((n) => n.isRead == 0).length;

  /// Optimistically marks an inbox row read locally and tells the backend.
  /// [userNotiId] is the `user_noti` row id (not the notification id). Falls
  /// back silently — the list resyncs on the next fetch if the PATCH fails.
  Future<void> markAsRead(int userNotiId) async {
    final idx = notifications.indexWhere((n) => n.id == userNotiId);
    if (idx == -1 || notifications[idx].isRead == 1) return;

    notifications[idx].isRead = 1;
    notifications.refresh();

    try {
      await _dio.patch('/user-noti/$userNotiId/read');
    } on DioException catch (e) {
      debugPrint('markAsRead failed for $userNotiId: ${e.message}');
    }
  }

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
    };
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
