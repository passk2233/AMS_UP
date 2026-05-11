import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/room_booking_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/semaster_model.dart';
import '../../../../widgets/app_dialogs.dart';

class AdminHomeController extends GetxController {
  // ── Observable state ──────────────────────────────────────────────────────
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<RoomBookingModel> bookings = <RoomBookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Dashboard stats (computed from real data)
  final RxInt pendingCount = 0.obs;
  final RxInt approvedCount = 0.obs;
  final RxInt roomInUsePercent = 0.obs;

  // Semester display
  final RxString semester = ''.obs;

  // Today's formatted date
  final RxString todayDate = ''.obs;

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    _setTodayDate();
    fetchDashboardData();
  }

  // ── Dio setup ─────────────────────────────────────────────────────────────
  void _initDio() {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ── Today's date ──────────────────────────────────────────────────────────
  void _setTodayDate() {
    final now = DateTime.now();
    const weekdays = [
      'ວັນຈັນ', 'ວັນອັງຄານ', 'ວັນພຸດ', 'ວັນພະຫັດ',
      'ວັນສຸກ', 'ວັນເສົາ', 'ວັນອາທິດ'
    ];
    const months = [
      'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ',
      'ພຶດສະພາ', 'ມິຖຸນາ', 'ກໍລະກົດ', 'ສິງຫາ',
      'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ'
    ];
    todayDate.value =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  // ── Fetch all dashboard data ──────────────────────────────────────────────
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _loadToken();

      // Run all fetches in parallel for speed
      await Future.wait([
        _fetchCurrentUser(),
        _fetchBookings(),
        _fetchActiveSemester(),
        _fetchRoomUsage(),
      ]);
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard data';
      debugPrint('Dashboard fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Fetch current user from /auth/me ──────────────────────────────────────
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

  // ── Fetch room bookings ───────────────────────────────────────────────────
  Future<void> _fetchBookings() async {
    try {
      // Fetch all bookings (pending first, then approved for display)
      final response = await _dio.get('/room-bookings', queryParameters: {
        'limit': 50,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }

        bookings.assignAll(
          items.map((json) => RoomBookingModel.fromJson(json)).toList(),
        );

        // Update computed stats from all fetched bookings
        _updateStats();
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch bookings: ${e.message}');
    }
  }

  // ── Fetch active semester ─────────────────────────────────────────────────
  Future<void> _fetchActiveSemester() async {
    try {
      final response = await _dio.get('/semasters', queryParameters: {
        'limit': 10,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }

        // Find the active semester (status == 1)
        final activeSemesters = items
            .map((json) => SemasterModel.fromJson(json))
            .where((s) => s.status == 1)
            .toList();

        if (activeSemesters.isNotEmpty) {
          final s = activeSemesters.first;
          semester.value = '${s.semasterCode} (${s.year})';
        } else if (items.isNotEmpty) {
          // Fallback to latest semester
          final s = SemasterModel.fromJson(items.first);
          semester.value = '${s.semasterCode} (${s.year})';
        } else {
          semester.value = 'No active semester';
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch semester: ${e.message}');
      semester.value = 'Semester';
    }
  }

  // ── Compute room usage % ──────────────────────────────────────────────────
  Future<void> _fetchRoomUsage() async {
    try {
      // Get total rooms
      final roomResponse = await _dio.get('/rooms', queryParameters: {
        'limit': 100,
      });

      if (roomResponse.statusCode == 200) {
        final roomData = roomResponse.data;
        int totalRooms = 0;
        if (roomData is Map) {
          totalRooms = (roomData['meta']?['total'] as int?) ?? 0;
          if (totalRooms == 0 && roomData['data'] is List) {
            totalRooms = (roomData['data'] as List).length;
          }
        } else if (roomData is List) {
          totalRooms = roomData.length;
        }

        if (totalRooms > 0) {
          // Count rooms with active (approved) bookings today
          final today = DateTime.now().toIso8601String().split('T')[0];
          final bookingResponse = await _dio.get('/room-bookings',
              queryParameters: {
                'status': 'approved',
                'limit': 100,
              });

          if (bookingResponse.statusCode == 200) {
            final bookingData = bookingResponse.data;
            List<dynamic> activeBookings = [];
            if (bookingData is List) {
              activeBookings = bookingData;
            } else if (bookingData is Map && bookingData['data'] != null) {
              activeBookings = bookingData['data'];
            }

            // Count unique rooms booked today
            final roomsInUse = activeBookings
                .map((b) => RoomBookingModel.fromJson(b))
                .where((b) {
                  final bookingDateStr =
                      b.bookingDate.toIso8601String().split('T')[0];
                  return bookingDateStr == today;
                })
                .map((b) => b.roomId)
                .toSet()
                .length;

            roomInUsePercent.value =
                ((roomsInUse / totalRooms) * 100).round();
          }
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to compute room usage: ${e.message}');
    }
  }

  // ── Approve a booking ─────────────────────────────────────────────────────
  Future<void> approveBooking(int bookingId) async {
    try {
      final response = await _dio.patch(
        '/room-bookings/$bookingId/status',
        data: {'status': 'approved'},
      );

      if (response.statusCode == 200) {
        // Update local state
        final index =
            bookings.indexWhere((b) => b.bookingId == bookingId);
        if (index != -1) {
          bookings[index].status = 'approved';
          bookings.refresh();
          _updateStats();
        }

        AppDialogs.showSuccess(
          title: 'ອະນຸມັດສຳເລັດ',
          message: 'ການຈອງຫ້ອງໄດ້ຮັບການອະນຸມັດແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showErrorSnackbar('Failed to approve booking', e);
    }
  }

  // ── Reject a booking ──────────────────────────────────────────────────────
  Future<void> rejectBooking(int bookingId) async {
    try {
      final response = await _dio.patch(
        '/room-bookings/$bookingId/status',
        data: {'status': 'rejected'},
      );

      if (response.statusCode == 200) {
        final index =
            bookings.indexWhere((b) => b.bookingId == bookingId);
        if (index != -1) {
          bookings[index].status = 'rejected';
          bookings.refresh();
          _updateStats();
        }

        AppDialogs.showWarning(
          title: 'ປະຕິເສດແລ້ວ',
          message: 'ການຈອງຫ້ອງໄດ້ຖືກປະຕິເສດ.',
        );
      }
    } on DioException catch (e) {
      _showErrorSnackbar('Failed to reject booking', e);
    }
  }

  // ── Stats helper ──────────────────────────────────────────────────────────
  void _updateStats() {
    pendingCount.value =
        bookings.where((b) => b.status == 'pending').length;
    approvedCount.value =
        bookings.where((b) => b.status == 'approved').length;
  }

  // ── Error helper ──────────────────────────────────────────────────────────
  void _showErrorSnackbar(String title, DioException e) {
    String message = 'ມີບັນຫາເກີດຂຶ້ນ, ກະລຸນາລອງໃໝ່.';
    if (e.response?.data is Map<String, dynamic>) {
      message = e.response?.data['error'] ?? message;
    }
    final detail = AppDialogs.buildDioErrorDetail(e);
    AppDialogs.showError(
      title: title,
      message: message,
      detail: detail,
    );
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refreshData() => fetchDashboardData();
}
