import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/admin_app_bar/admin_app_bar_controllers.dart';
import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// Tabs in [ApproveView]'s filter row.
abstract class ApproveTab {
  /// 0 — all bookings.
  static const int all = 0;

  /// 1 — `status = pending` only.
  static const int pending = 1;

  /// 2 — `status = approved` only.
  static const int approved = 2;

  /// 3 — `status = rejected` only.
  static const int rejected = 3;
}

/// Reactive state owner for [ApproveView].
///
/// Loads every room booking, exposes a derived [filteredBookings] list that
/// reflects the active [selectedTab] + [searchQuery], maintains live status
/// counters, and supports both per-row and bulk approve/reject.
class ApproveController extends GetxController {
  /// Injected so tests can supply a mock; defaults to the shared provider in
  /// production via the binding.
  ApproveController({BookingProvider? provider})
      : _provider = provider ?? BookingProvider();

  /// Data-access seam for the `room_bookings` resource.
  final BookingProvider _provider;

  /// Raw bookings returned by the last fetch.
  final RxList<RoomBookingModel> bookings = <RoomBookingModel>[].obs;

  /// Filtered, sorted projection of [bookings] driven by [selectedTab] and
  /// [searchQuery]. Pending rows come first; within a group the newest
  /// `booking_date` wins.
  final RxList<RoomBookingModel> filteredBookings = <RoomBookingModel>[].obs;

  /// `true` while the initial fetch or a bulk mutation is in flight.
  final RxBool isLoading = false.obs;

  /// Last user-facing error from the load path; empty when there is none.
  final RxString errorMessage = ''.obs;

  /// Active filter tab — see [ApproveTab]. Defaults to pending so the
  /// admin's primary task surface is immediate.
  final RxInt selectedTab = ApproveTab.pending.obs;

  /// Backing text controller for the search bar (also exposed to the view).
  final TextEditingController searchCtrl = TextEditingController();

  /// Current search needle; bound to [searchCtrl] via [onSearchChanged].
  final RxString searchQuery = ''.obs;

  /// Number of bookings with `status = pending`.
  final RxInt pendingCount = 0.obs;

  /// Number of bookings with `status = approved`.
  final RxInt approvedCount = 0.obs;

  /// Number of bookings with `status = rejected`.
  final RxInt rejectedCount = 0.obs;

  /// Total number of loaded bookings (sum of the three above).
  final RxInt totalCount = 0.obs;

  /// `true` when the bulk-selection toolbar is active; tapping a row toggles
  /// inclusion in [selectedBookingIds] instead of opening the row's actions.
  final RxBool selectionMode = false.obs;

  /// IDs of bookings currently included in the bulk selection.
  final RxSet<int> selectedBookingIds = <int>{}.obs;

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

  /// Refresh handler — re-runs the bookings fetch.
  Future<void> refreshData() => fetchBookings();

  /// Fetch up to 200 most-recent bookings, refresh derived state, and
  /// surface a friendly error in [errorMessage] on failure.
  Future<void> fetchBookings() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      bookings.assignAll(await _provider.fetchBookings());
      _updateStats();
      _applyFilters();
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

  // ───────────────────────────────────────────────────────── filtering ──

  /// Switch the active filter tab and re-derive [filteredBookings].
  void setTab(int tab) {
    selectedTab.value = tab;
    _applyFilters();
  }

  /// Bound to the search bar's `onChanged` callback.
  void onSearchChanged(String val) {
    searchQuery.value = val;
    _applyFilters();
  }

  /// Clear the search field and re-derive [filteredBookings].
  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = '';
    _applyFilters();
  }

  // ─────────────────────────────────────────────────── bulk selection ──

  /// Enter / leave bulk selection mode. Leaving also clears any selection.
  void toggleSelectionMode() {
    selectionMode.value = !selectionMode.value;
    if (!selectionMode.value) selectedBookingIds.clear();
  }

  /// Add [bookingId] to the selection, or remove it if already present.
  void toggleSelected(int bookingId) {
    if (selectedBookingIds.contains(bookingId)) {
      selectedBookingIds.remove(bookingId);
    } else {
      selectedBookingIds.add(bookingId);
    }
  }

  /// Select every currently visible pending booking.
  void selectAllVisiblePending() {
    selectedBookingIds.addAll(
      filteredBookings
          .where((b) => b.status.toLowerCase() == 'pending')
          .map((b) => b.bookingId),
    );
  }

  /// Drop every booking from the selection.
  void clearSelection() => selectedBookingIds.clear();

  /// Approve every currently selected pending booking after a confirmation
  /// dialog. Non-pending entries in the selection are silently skipped.
  Future<void> bulkApproveSelected() =>
      _bulkConfirmAndPatch(status: 'approved');

  /// Reject every currently selected pending booking after a confirmation
  /// dialog. Non-pending entries in the selection are silently skipped.
  Future<void> bulkRejectSelected() =>
      _bulkConfirmAndPatch(status: 'rejected');

  // ────────────────────────────────────────────────── single mutations ──

  /// Approve one booking (with confirmation dialog).
  Future<void> approveBooking(int bookingId) =>
      _confirmAndPatch(bookingId, 'approved');

  /// Reject one booking (with confirmation dialog).
  Future<void> rejectBooking(int bookingId) =>
      _confirmAndPatch(bookingId, 'rejected');

  // ───────────────────────────────────────────────────────────── private ──

  Future<void> _confirmAndPatch(int bookingId, String status) async {
    final booking = bookings.firstWhereOrNull((b) => b.bookingId == bookingId);
    final roomName = booking?.room?.roomCode ?? 'ID: $bookingId';
    final approving = status == 'approved';

    final confirmed = await AppDialogs.showConfirmation(
      title: approving ? 'ຢືນຢັນການອະນຸມັດ' : 'ຢືນຢັນການປະຕິເສດ',
      message: approving
          ? 'ທ່ານຕ້ອງການອະນຸມັດການຈອງ\nຫ້ອງ $roomName ແທ້ບໍ?'
          : 'ທ່ານຕ້ອງການປະຕິເສດການຈອງ\nຫ້ອງ $roomName ແທ້ບໍ?',
      confirmText: approving ? 'ອະນຸມັດ' : 'ປະຕິເສດ',
      cancelText: 'ຍົກເລີກ',
      confirmColor:
          approving ? AppColors.borderApproved : AppColors.rejectRed,
    );
    if (confirmed != true) return;

    try {
      await _provider.updateStatus(bookingId, status);

      final index = bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        bookings[index].status = status;
        bookings.refresh();
        _updateStats();
        _applyFilters();
        _refreshAppBarBadge();
      }

      if (approving) {
        AppDialogs.showSuccess(
          title: 'ອະນຸມັດສຳເລັດ',
          message: 'ການຈອງຫ້ອງ $roomName ໄດ້ຮັບການອະນຸມັດແລ້ວ.',
        );
      } else {
        AppDialogs.showWarning(
          title: 'ປະຕິເສດແລ້ວ',
          message: 'ການຈອງຫ້ອງ $roomName ໄດ້ຖືກປະຕິເສດ.',
        );
      }
    } on DioException catch (e) {
      _showErrorDialog(
        approving ? 'ອະນຸມັດລົ້ມເຫຼວ' : 'ປະຕິເສດລົ້ມເຫຼວ',
        e,
      );
    }
  }

  Future<void> _bulkConfirmAndPatch({required String status}) async {
    final approving = status == 'approved';
    final ids = _pendingIdsInSelection();
    if (ids.isEmpty) {
      AppDialogs.showWarning(
        title: 'ບໍ່ມີລາຍການລໍຖ້າ',
        message: 'ກະລຸນາເລືອກລາຍການທີ່ຢູ່ໃນສະຖານະ "ລໍຖ້າ".',
      );
      return;
    }

    final ok = await AppDialogs.showConfirmation(
      title: approving ? 'ອະນຸມັດທັງໝົດ' : 'ປະຕິເສດທັງໝົດ',
      message: '${approving ? 'ອະນຸມັດ' : 'ປະຕິເສດ'} ${ids.length} ລາຍການ?',
      confirmText: approving ? 'ອະນຸມັດ' : 'ປະຕິເສດ',
      cancelText: 'ຍົກເລີກ',
      confirmColor:
          approving ? AppColors.borderApproved : AppColors.rejectRed,
    );
    if (ok != true) return;
    await _bulkPatchStatus(ids, status);
  }

  List<int> _pendingIdsInSelection() {
    return selectedBookingIds.where((id) {
      final b = bookings.firstWhereOrNull((x) => x.bookingId == id);
      return b != null && b.status.toLowerCase() == 'pending';
    }).toList();
  }

  Future<void> _bulkPatchStatus(List<int> ids, String status) async {
    isLoading.value = true;
    var success = 0;
    var failed = 0;
    try {
      for (final id in ids) {
        try {
          await _provider.updateStatus(id, status);
          final index = bookings.indexWhere((b) => b.bookingId == id);
          if (index != -1) bookings[index].status = status;
          success++;
        } catch (_) {
          failed++;
        }
      }
      bookings.refresh();
      _updateStats();
      _applyFilters();
      _refreshAppBarBadge();
      selectedBookingIds.clear();
      selectionMode.value = false;

      if (failed == 0) {
        AppDialogs.showSuccess(
          title: status == 'approved' ? 'ອະນຸມັດສຳເລັດ' : 'ປະຕິເສດສຳເລັດ',
          message: '$success ລາຍການ',
        );
      } else {
        AppDialogs.showWarning(
          title: 'ບາງລາຍການລົ້ມເຫຼວ',
          message: 'ສຳເລັດ $success, ລົ້ມເຫຼວ $failed',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var list = List<RoomBookingModel>.from(bookings);

    final tabStatus = _statusForTab(selectedTab.value);
    if (tabStatus != null) {
      list = list.where((b) => b.status.toLowerCase() == tabStatus).toList();
    }

    final q = searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        final roomCode = b.room?.roomCode.toLowerCase() ?? '';
        final purpose = (b.purpose ?? '').toLowerCase();
        final userName = _displayName(b).toLowerCase();
        return roomCode.contains(q) ||
            purpose.contains(q) ||
            userName.contains(q);
      }).toList();
    }

    list.sort((a, b) {
      final aPending = a.status.toLowerCase() == 'pending' ? 0 : 1;
      final bPending = b.status.toLowerCase() == 'pending' ? 0 : 1;
      if (aPending != bPending) return aPending.compareTo(bPending);
      return b.bookingDate.compareTo(a.bookingDate);
    });

    filteredBookings.assignAll(list);
  }

  String? _statusForTab(int tab) {
    switch (tab) {
      case ApproveTab.pending:
        return 'pending';
      case ApproveTab.approved:
        return 'approved';
      case ApproveTab.rejected:
        return 'rejected';
      default:
        return null;
    }
  }

  String _displayName(RoomBookingModel b) {
    final user = b.user;
    if (user == null) return '';
    final teacher = user.teacher;
    if (teacher != null) {
      return '${teacher.nameLao} ${teacher.surnameLao}'.trim();
    }
    final student = user.student;
    if (student != null) {
      return '${student.nameLao} ${student.surnameLao ?? ''}'.trim();
    }
    return user.username;
  }

  void _updateStats() {
    pendingCount.value =
        bookings.where((b) => b.status.toLowerCase() == 'pending').length;
    approvedCount.value =
        bookings.where((b) => b.status.toLowerCase() == 'approved').length;
    rejectedCount.value =
        bookings.where((b) => b.status.toLowerCase() == 'rejected').length;
    totalCount.value = bookings.length;
  }

  void _refreshAppBarBadge() {
    if (Get.isRegistered<AdminAppBarControllers>()) {
      Get.find<AdminAppBarControllers>().refreshData();
    }
  }

  void _showErrorDialog(String title, DioException e) {
    var message = 'ມີບັນຫາເກີດຂຶ້ນ, ກະລຸນາລອງໃໝ່.';
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
}
