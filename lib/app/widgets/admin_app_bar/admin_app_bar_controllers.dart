import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/data/data_exporter.dart';
import '../../services/api_client.dart';
import '../app_top_bar/semester_controller.dart';

/// Admin-only state owner for the pending-bookings count.
///
/// The active semester is no longer owned here — it moved to the shared
/// [SemesterController] so teachers and students can reuse the same top bar
/// without triggering this admin-scoped `/room-bookings` fetch. What remains
/// is the count of `status = pending` room bookings, which the admin bottom
/// nav surfaces as a badge on the "ການຢືນຢັນ" tab.
///
/// Each fetch is best-effort — a failure logs and leaves the observable at its
/// last value, so the UI never blocks on networking.
class AdminAppBarControllers extends GetxController {
  /// Count of `status = pending` room bookings.
  final RxInt pendingRequestCount = 0.obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    _fetchPendingRequests();
  }

  /// Refresh the pending count plus the shared semester label.
  ///
  /// Call from screens that need an up-to-date bar after a write — e.g. after
  /// the admin approves a booking (which changes the pending count).
  Future<void> refreshData() {
    return Future.wait([
      _fetchPendingRequests(),
      semesterController.fetchActiveSemester(),
    ]);
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

  /// Normalize the server's two response shapes — raw array or
  /// `{ "data": [...] }` envelope — into a `List<dynamic>`.
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const <dynamic>[];
  }
}
