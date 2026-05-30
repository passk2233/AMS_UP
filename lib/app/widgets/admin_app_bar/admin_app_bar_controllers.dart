import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/data/data_exporter.dart';
import '../../services/api_client.dart';

/// Reactive state owner for [AdminAppBar].
///
/// Loads three independent pieces of state on init:
/// 1. The active [semester] (priority: date-range → status flag → newest).
/// 2. The count of pending room bookings ([pendingRequestCount]).
/// 3. The count of unread notifications ([unreadNotiCount]).
///
/// Each fetch is best-effort — a failure logs and leaves the corresponding
/// observable at its last value, so the UI never blocks on networking.
class AdminAppBarControllers extends GetxController {
  /// Active-semester display label (e.g. `S1 (2025-2026)`).
  final RxString semester = ''.obs;

  /// `true` while [_fetchActiveSemester] is in flight.
  final RxBool semesterLoading = true.obs;

  /// Count of `status = pending` room bookings.
  final RxInt pendingRequestCount = 0.obs;

  /// Count of `is_read = 0` notifications addressed to this user.
  final RxInt unreadNotiCount = 0.obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    _fetchActiveSemester();
    _fetchPendingRequests();
    _fetchUnreadNotifications();
  }

  /// Refresh all three observables in parallel.
  ///
  /// Call from screens that need an up-to-date bar after a write — e.g.
  /// after the admin approves a booking or marks a notification read.
  Future<void> refreshData() {
    return Future.wait([
      _fetchActiveSemester(),
      _fetchPendingRequests(),
      _fetchUnreadNotifications(),
    ]);
  }

  Future<void> _fetchActiveSemester() async {
    semesterLoading.value = true;
    try {
      final response = await _dio.get(
        '/semasters',
        queryParameters: {'limit': 10},
      );
      if (response.statusCode != 200) return;

      final all = _extractList(response.data)
          .map((json) => SemasterModel.fromJson(json))
          .toList();
      semester.value = _pickActiveSemester(all);
    } on DioException catch (e) {
      debugPrint('Failed to fetch semester: ${e.message}');
      semester.value = 'Semester';
    } finally {
      semesterLoading.value = false;
    }
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final response = await _dio.get(
        '/room-bookings',
        queryParameters: {'limit': 100},
      );
      if (response.statusCode != 200) return;

      pendingRequestCount.value = _extractList(response.data)
          .map((json) => RoomBookingModel.fromJson(json))
          .where((b) => b.status == 'pending')
          .length;
    } on DioException catch (e) {
      debugPrint('Failed to fetch pending requests: ${e.message}');
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'limit': 200},
      );
      if (response.statusCode != 200) return;

      unreadNotiCount.value = _extractList(response.data)
          .map((json) => NotificationModel.fromJson(json))
          .where((n) => n.isRead == 0)
          .length;
    } on DioException catch (e) {
      debugPrint('Failed to fetch unread notifications: ${e.message}');
    }
  }

  /// Normalize the server's two response shapes — raw array or
  /// `{ "data": [...] }` envelope — into a `List<dynamic>`.
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const <dynamic>[];
  }

  /// Pick the semester to display from the full list using a three-tier
  /// fallback strategy. Returns the formatted label, or a sentinel when the
  /// list is empty.
  String _pickActiveSemester(List<SemasterModel> all) {
    if (all.isEmpty) return 'No active semester';

    final now = DateTime.now();
    final byDate = all.where((s) {
      final start = s.startDate;
      final end = s.endDate;
      if (start == null || end == null) return false;
      return !now.isBefore(start) && !now.isAfter(end);
    }).toList();
    if (byDate.isNotEmpty) return _format(byDate.first);

    final active = all.where((s) => s.status == 1).toList();
    if (active.isNotEmpty) return _format(active.first);

    return _format(all.first);
  }

  String _format(SemasterModel s) => '${s.semasterCode} (${s.year})';
}
