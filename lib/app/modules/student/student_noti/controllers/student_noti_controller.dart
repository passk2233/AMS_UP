import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class StudentNotiController extends GetxController {
  var selectedFilterIndex = 0.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

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
      final resp = await _dio.get('/notifications', queryParameters: {'limit': 100});
      final items = _extractList(resp.data);
      notifications.assignAll(items.map((j) => NotificationModel.fromJson(j)).toList());
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

  List<Map<String, dynamic>> get filteredNotifications {
    final all = notifications.map(_toViewItem).toList();
    if (selectedFilterIndex.value == 0) return all;

    final category = selectedFilterIndex.value == 1 ? "Academic" : "Room Booking";
    return all.where((n) => n['category'] == category).toList();
  }

  /// Count of items the user hasn't tapped yet. Drives badges.
  int get unreadCount =>
      notifications.where((n) => n.isRead == 0).length;

  /// Optimistically marks an item read in the local list and tells the
  /// backend. Falls back silently — the local list will resync on next
  /// fetch if the PUT fails.
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

  Map<String, dynamic> _toViewItem(NotificationModel n) {
    final typeRaw = (n.type ?? '').toLowerCase();
    final isUrgent = typeRaw == 'urgent';
    final category = typeRaw.contains('booking') ? 'Room Booking' : 'Academic';

    final ts = n.createdAt;
    final time = ts == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(ts.toLocal());

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
    return const [];
  }
}
