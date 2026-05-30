import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

/// Reactive state owner for [AdminNotiView].
///
/// Loads the most recent notifications on init, exposes a filtered view
/// driven by [selectedFilterIndex] (0 = All, 1 = Academic, 2 = Room Booking),
/// and optimistically marks notifications as read.
class AdminNotiController extends GetxController {
  /// Currently selected filter chip index — 0 = All, 1 = Academic,
  /// 2 = Room Booking. Bound to the chip row in the view.
  final RxInt selectedFilterIndex = 0.obs;

  /// `true` while the initial load is in flight.
  final RxBool isLoading = false.obs;

  /// User-facing error message from the last load; empty when there is none.
  final RxString errorMessage = ''.obs;

  /// Raw notifications returned by the API.
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  /// GET `/notifications` and populate [notifications]. Errors map to a
  /// localized message in [errorMessage].
  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'limit': 100},
      );
      notifications.assignAll(
        _extractList(response.data)
            .map((j) => NotificationModel.fromJson(j))
            .toList(),
      );
    } on DioException catch (e) {
      debugPrint('AdminNoti Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      errorMessage.value = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : 'Failed to load notifications.';
    } finally {
      isLoading.value = false;
    }
  }

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

  /// Mark a notification read locally first, then sync to the backend.
  ///
  /// No-op if the notification is unknown or already read.
  Future<void> markAsRead(int notiId) async {
    final idx = notifications.indexWhere((n) => n.notiId == notiId);
    if (idx == -1 || notifications[idx].isRead == 1) return;

    notifications[idx].isRead = 1;
    notifications.refresh();

    try {
      await _dio.put('/notifications/$notiId/read');
    } on DioException catch (e) {
      debugPrint('markAsRead failed for $notiId: ${e.message}');
    }
  }

  /// Convert a model into the loose view-model map consumed by the list
  /// items. The shape varies for urgent vs normal entries because urgent
  /// rows render a status pill in addition to the body.
  Map<String, dynamic> _toViewItem(NotificationModel n) {
    final typeRaw = (n.type ?? '').toLowerCase();
    final isUrgent = typeRaw == 'urgent';
    final category = typeRaw.contains('booking') ? 'Room Booking' : 'Academic';
    final ts = n.createdAt;
    final time = ts == null
        ? '-'
        : DateFormat('yyyy-MM-dd HH:mm').format(ts.toLocal());

    if (isUrgent) {
      return {
        'id': n.notiId,
        'unread': n.isRead == 0,
        'type': 'Urgent',
        'category': category,
        'title': n.title,
        'sub': n.message,
        'status': 'Urgent',
        'time': time,
      };
    }
    return {
      'id': n.notiId,
      'unread': n.isRead == 0,
      'type': 'Normal',
      'category': category,
      'title': n.title,
      'desc': n.message,
      'time': time,
    };
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
