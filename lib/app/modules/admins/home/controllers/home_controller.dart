import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/api_client.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/models/room_booking_model.dart';
import '../../../data/models/semaster_model.dart';
import '../../../data/models/user_model.dart';

/// Reactive state owner for [AdminHomeView].
///
/// On init, fans out four parallel requests (current user, bookings, active
/// semester, room-usage %) and aggregates them into observables. Exposes
/// approve / reject mutations that update local state optimistically and
/// reconcile via the backend response.
class AdminHomeController extends GetxController {
  /// Currently signed-in admin user.
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  /// Most recent booking page from the API.
  final RxList<RoomBookingModel> bookings = <RoomBookingModel>[].obs;

  /// `true` while the initial fan-out or refresh is in flight.
  final RxBool isLoading = false.obs;

  /// Last user-facing error message, empty when there is no error.
  final RxString errorMessage = ''.obs;

  /// Count of `pending` bookings in [bookings].
  final RxInt pendingCount = 0.obs;

  /// Count of `approved` bookings in [bookings].
  final RxInt approvedCount = 0.obs;

  /// Percentage of rooms with at least one approved booking today.
  final RxInt roomInUsePercent = 0.obs;

  /// Display label for the active semester (e.g. `S1 (2025-2026)`).
  final RxString semester = ''.obs;

  /// Lao-formatted today's date (e.g. `ວັນຈັນ, ມັງກອນ 5`).
  final RxString todayDate = ''.obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    todayDate.value = _formatToday(DateTime.now());
    fetchDashboardData();
  }

  /// Refresh handler bound to the pull-to-refresh and to tab switches in
  /// [BottomNavController].
  Future<void> refreshData() => fetchDashboardData();

  /// Run all four dashboard fetches in parallel. Always clears the loading
  /// flag, even on failure.
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait([
        _fetchCurrentUser(),
        _fetchBookings(),
        _fetchActiveSemester(),
        _fetchRoomUsage(),
      ]);
    } catch (e) {
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນແດດໂບດໄດ້';
      debugPrint('Dashboard fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// PATCH a booking to `approved` and reconcile local state on success.
  Future<void> approveBooking(int bookingId) =>
      _changeBookingStatus(bookingId, 'approved');

  /// PATCH a booking to `rejected` and reconcile local state on success.
  Future<void> rejectBooking(int bookingId) =>
      _changeBookingStatus(bookingId, 'rejected');

  // ───────────────────────────────────────────────────────────── private ──

  Future<void> _changeBookingStatus(int bookingId, String status) async {
    try {
      final response = await _dio.patch(
        '/room-bookings/$bookingId/status',
        data: {'status': status},
      );
      if (response.statusCode != 200) return;

      final index = bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        bookings[index].status = status;
        bookings.refresh();
        _updateStats();
      }

      if (status == 'approved') {
        AppDialogs.showSuccess(
          title: 'ອະນຸມັດສຳເລັດ',
          message: 'ການຈອງຫ້ອງໄດ້ຮັບການອະນຸມັດແລ້ວ.',
        );
      } else {
        AppDialogs.showWarning(
          title: 'ປະຕິເສດແລ້ວ',
          message: 'ການຈອງຫ້ອງໄດ້ຖືກປະຕິເສດ.',
        );
      }
    } on DioException catch (e) {
      _showErrorDialog(
        status == 'approved'
            ? 'Failed to approve booking'
            : 'Failed to reject booking',
        e,
      );
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        currentUser.value = UserModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch user: ${e.message}');
    }
  }

  Future<void> _fetchBookings() async {
    try {
      final response = await _dio.get(
        '/room-bookings',
        queryParameters: {'limit': 50},
      );
      if (response.statusCode != 200) return;

      bookings.assignAll(
        _extractList(response.data)
            .map((json) => RoomBookingModel.fromJson(json))
            .toList(),
      );
      _updateStats();
    } on DioException catch (e) {
      debugPrint('Failed to fetch bookings: ${e.message}');
    }
  }

  Future<void> _fetchActiveSemester() async {
    try {
      final response = await _dio.get(
        '/semasters',
        queryParameters: {'limit': 10},
      );
      if (response.statusCode != 200) return;

      final items = _extractList(response.data)
          .map((json) => SemasterModel.fromJson(json))
          .toList();
      semester.value = _pickSemesterLabel(items);
    } on DioException catch (e) {
      debugPrint('Failed to fetch semester: ${e.message}');
      semester.value = 'Semester';
    }
  }

  Future<void> _fetchRoomUsage() async {
    try {
      final totalRooms = await _fetchTotalRooms();
      if (totalRooms <= 0) return;

      final response = await _dio.get(
        '/room-bookings',
        queryParameters: {'status': 'approved', 'limit': 100},
      );
      if (response.statusCode != 200) return;

      final today = _isoDate(DateTime.now());
      final roomsInUse = _extractList(response.data)
          .map((b) => RoomBookingModel.fromJson(b))
          .where((b) => _isoDate(b.bookingDate) == today)
          .map((b) => b.roomId)
          .toSet()
          .length;

      roomInUsePercent.value = ((roomsInUse / totalRooms) * 100).round();
    } on DioException catch (e) {
      debugPrint('Failed to compute room usage: ${e.message}');
    }
  }

  Future<int> _fetchTotalRooms() async {
    final response = await _dio.get(
      '/rooms',
      queryParameters: {'limit': 100},
    );
    if (response.statusCode != 200) return 0;

    final raw = response.data;
    if (raw is Map) {
      final metaTotal = raw['meta']?['total'] as int?;
      if (metaTotal != null && metaTotal > 0) return metaTotal;
      if (raw['data'] is List) return (raw['data'] as List).length;
    }
    if (raw is List) return raw.length;
    return 0;
  }

  void _updateStats() {
    pendingCount.value = bookings.where((b) => b.status == 'pending').length;
    approvedCount.value = bookings.where((b) => b.status == 'approved').length;
  }

  void _showErrorDialog(String title, DioException e) {
    String message = 'ມີບັນຫາເກີດຂຶ້ນ, ກະລຸນາລອງໃໝ່.';
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      message = data['error'].toString();
    }
    AppDialogs.showError(
      title: title,
      message: message,
      detail: AppDialogs.buildDioErrorDetail(e),
    );
  }

  /// Pick the semester to display from the full list. Active (`status == 1`)
  /// wins; otherwise the newest (first in the response).
  String _pickSemesterLabel(List<SemasterModel> items) {
    if (items.isEmpty) return 'No active semester';
    final active = items.where((s) => s.status == 1).toList();
    final picked = active.isNotEmpty ? active.first : items.first;
    return '${picked.semasterCode} (${picked.year})';
  }

  /// Normalize the two server response shapes into a `List<dynamic>`.
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }

  /// `2026-05-18`-style date used for same-day comparisons.
  String _isoDate(DateTime d) => d.toIso8601String().split('T').first;

  String _formatToday(DateTime now) {
    const weekdays = <String>[
      'ວັນຈັນ', 'ວັນອັງຄານ', 'ວັນພຸດ', 'ວັນພະຫັດ',
      'ວັນສຸກ', 'ວັນເສົາ', 'ວັນອາທິດ',
    ];
    const months = <String>[
      'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ',
      'ພຶດສະພາ', 'ມິຖຸນາ', 'ກໍລະກົດ', 'ສິງຫາ',
      'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
