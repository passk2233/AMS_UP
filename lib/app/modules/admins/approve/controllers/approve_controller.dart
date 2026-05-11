import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../../widgets/admin_app_bar/admin_app_bar_controllers.dart';

class ApproveController extends GetxController {
  // ── All bookings from API ─────────────────────────────────────────────────
  final RxList<RoomBookingModel> bookings = <RoomBookingModel>[].obs;
  final RxList<RoomBookingModel> filteredBookings = <RoomBookingModel>[].obs;

  // ── UI state ──────────────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Filter / Search ───────────────────────────────────────────────────────
  // 0=All, 1=Pending, 2=Approved, 3=Rejected
  final RxInt selectedTab = 1.obs; // default to Pending
  final searchCtrl = TextEditingController();
  final RxString searchQuery = ''.obs;

  // ── Stats ─────────────────────────────────────────────────────────────────
  final RxInt pendingCount = 0.obs;
  final RxInt approvedCount = 0.obs;
  final RxInt rejectedCount = 0.obs;
  final RxInt totalCount = 0.obs;

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_URL'] ?? '',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    },
  ));

  String _token = '';

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIO SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH BOOKINGS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> fetchBookings() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _loadToken();

      final response = await _dio.get('/room-bookings', queryParameters: {
        'limit': 200,
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

        _updateStats();
        _applyFilters();
      }
    } on DioException catch (e) {
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນການຈອງໄດ້';
      debugPrint('Failed to fetch bookings: ${e.message}');
    } catch (e) {
      errorMessage.value = 'ມີຂໍ້ຜິດພາດເກີດຂຶ້ນ';
      debugPrint('Approve fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER & SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  void setTab(int tab) {
    selectedTab.value = tab;
    _applyFilters();
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
    _applyFilters();
  }

  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = '';
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<RoomBookingModel>.from(bookings);

    // Tab filter
    switch (selectedTab.value) {
      case 1:
        list = list.where((b) => b.status.toLowerCase() == 'pending').toList();
        break;
      case 2:
        list = list.where((b) => b.status.toLowerCase() == 'approved').toList();
        break;
      case 3:
        list = list.where((b) => b.status.toLowerCase() == 'rejected').toList();
        break;
    }

    // Search filter
    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        final roomCode = b.room?.roomCode.toLowerCase() ?? '';
        final purpose = (b.purpose ?? '').toLowerCase();
        final userName = _getDisplayName(b).toLowerCase();
        return roomCode.contains(q) ||
            purpose.contains(q) ||
            userName.contains(q);
      }).toList();
    }

    // Sort: pending first, then by date descending
    list.sort((a, b) {
      // Primary: pending before others
      final aPending = a.status.toLowerCase() == 'pending' ? 0 : 1;
      final bPending = b.status.toLowerCase() == 'pending' ? 0 : 1;
      if (aPending != bPending) return aPending.compareTo(bPending);
      // Secondary: newest first
      return b.bookingDate.compareTo(a.bookingDate);
    });

    filteredBookings.assignAll(list);
  }

  String _getDisplayName(RoomBookingModel b) {
    final user = b.user;
    if (user == null) return '';
    if (user.teacher != null) {
      final t = user.teacher!;
      return '${t.nameLao} ${t.surnameLao}'.trim();
    }
    if (user.student != null) {
      final s = user.student!;
      return '${s.nameLao} ${s.surnameLao ?? ''}'.trim();
    }
    return user.username;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════════════════════

  void _updateStats() {
    pendingCount.value =
        bookings.where((b) => b.status.toLowerCase() == 'pending').length;
    approvedCount.value =
        bookings.where((b) => b.status.toLowerCase() == 'approved').length;
    rejectedCount.value =
        bookings.where((b) => b.status.toLowerCase() == 'rejected').length;
    totalCount.value = bookings.length;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPROVE / REJECT WITH CONFIRMATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> approveBooking(int bookingId) async {
    final booking = bookings.firstWhereOrNull((b) => b.bookingId == bookingId);
    final roomName = booking?.room?.roomCode ?? 'ID: $bookingId';

    final confirmed = await AppDialogs.showConfirmation(
      title: 'ຢືນຢັນການອະນຸມັດ',
      message: 'ທ່ານຕ້ອງການອະນຸມັດການຈອງ\nຫ້ອງ $roomName ແທ້ບໍ?',
      confirmText: 'ອະນຸມັດ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: const Color(0xFF10B981),
    );
    if (confirmed != true) return;

    try {
      final response = await _dio.patch(
        '/room-bookings/$bookingId/status',
        data: {'status': 'approved'},
      );

      if (response.statusCode == 200) {
        final index = bookings.indexWhere((b) => b.bookingId == bookingId);
        if (index != -1) {
          bookings[index].status = 'approved';
          bookings.refresh();
          _updateStats();
          _applyFilters();
          _refreshAppBarBadge();
        }

        AppDialogs.showSuccess(
          title: 'ອະນຸມັດສຳເລັດ',
          message: 'ການຈອງຫ້ອງ $roomName ໄດ້ຮັບການອະນຸມັດແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showErrorDialog('ອະນຸມັດລົ້ມເຫຼວ', e);
    }
  }

  Future<void> rejectBooking(int bookingId) async {
    final booking = bookings.firstWhereOrNull((b) => b.bookingId == bookingId);
    final roomName = booking?.room?.roomCode ?? 'ID: $bookingId';

    final confirmed = await AppDialogs.showConfirmation(
      title: 'ຢືນຢັນການປະຕິເສດ',
      message: 'ທ່ານຕ້ອງການປະຕິເສດການຈອງ\nຫ້ອງ $roomName ແທ້ບໍ?',
      confirmText: 'ປະຕິເສດ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: const Color(0xFFE53935),
    );
    if (confirmed != true) return;

    try {
      final response = await _dio.patch(
        '/room-bookings/$bookingId/status',
        data: {'status': 'rejected'},
      );

      if (response.statusCode == 200) {
        final index = bookings.indexWhere((b) => b.bookingId == bookingId);
        if (index != -1) {
          bookings[index].status = 'rejected';
          bookings.refresh();
          _updateStats();
          _applyFilters();
          _refreshAppBarBadge();
        }

        AppDialogs.showWarning(
          title: 'ປະຕິເສດແລ້ວ',
          message: 'ການຈອງຫ້ອງ $roomName ໄດ້ຖືກປະຕິເສດ.',
        );
      }
    } on DioException catch (e) {
      _showErrorDialog('ປະຕິເສດລົ້ມເຫຼວ', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _refreshAppBarBadge() {
    if (Get.isRegistered<AdminAppBarControllers>()) {
      Get.find<AdminAppBarControllers>().refreshData();
    }
  }

  void _showErrorDialog(String title, DioException e) {
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
  Future<void> refreshData() => fetchBookings();
}
