import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';
import 'package:frontend/app/modules/teachers/booking/controllers/fixed_booking.dart';

class BookingStudentController extends GetxController {
  BookingStudentController({
    AuthProvider? auth,
    BookingProvider? booking,
    AcademicProvider? academic,
  })  : _auth = auth ?? AuthProvider(),
        _booking = booking ?? BookingProvider(),
        _academic = academic ?? AcademicProvider();

  final AuthProvider _auth;
  final BookingProvider _booking;
  final AcademicProvider _academic;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<RoomModel> rooms = <RoomModel>[].obs;
  final RxList<RoomBookingModel> myBookings = <RoomBookingModel>[].obs;
  final RxList<RoomBookingModel> _allBookings = <RoomBookingModel>[].obs;
  final RxList<StudyPlanModel> studyPlans = <StudyPlanModel>[].obs;
  final RxList<ClassCancellationModel> _classCancellations =
      <ClassCancellationModel>[].obs;

  /// UI filter for `myBookings`. One of: all | upcoming | pending | approved
  /// | cancelled | past.
  final RxString bookingFilter = 'all'.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<SemasterModel?> activeSemester = Rx<SemasterModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _auth.me();
      currentUser.value = user;
      if (user == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນຜູ້ໃຊ້';
        return;
      }

      await _loadActiveSemester();

      rooms.assignAll(await _booking.fetchRooms(limit: 200));

      final all = await _booking.fetchBookings(limit: 500);
      _allBookings.assignAll(all);

      final mine = all.where((b) => b.userId == user.id).toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      myBookings.assignAll(mine);

      await _loadStudyPlans();
      await _loadClassCancellations();
    } on DioException catch (e) {
      debugPrint('Booking Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
          : 'ບໍ່ສາມາດໂຫຼດການຈອງໄດ້';
    } catch (e) {
      debugPrint('Booking error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດການຈອງໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() => fetchData();

  /// True when [b] represents a slot that has already started or ended.
  bool isBookingPast(RoomBookingModel b) =>
      isPastSlot(b.bookingDate, b.startTime);

  /// Filtered view of [myBookings] driven by [bookingFilter].
  List<RoomBookingModel> get filteredMyBookings {
    final f = bookingFilter.value;
    return myBookings.where((b) {
      final s = b.status.toLowerCase();
      final past = isBookingPast(b);
      switch (f) {
        case 'upcoming':
          return !past && (s == 'pending' || s == 'approved');
        case 'pending':
          return s == 'pending';
        case 'approved':
          return s == 'approved';
        case 'cancelled':
          return s == 'cancelled' || s == 'rejected';
        case 'past':
          return past;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  int get countUpcoming => myBookings
      .where((b) =>
          !isBookingPast(b) &&
          (b.status.toLowerCase() == 'pending' ||
              b.status.toLowerCase() == 'approved'))
      .length;
  int get countPending =>
      myBookings.where((b) => b.status.toLowerCase() == 'pending').length;
  int get countApproved =>
      myBookings.where((b) => b.status.toLowerCase() == 'approved').length;
  int get countPast => myBookings.where(isBookingPast).length;

  Future<void> _loadActiveSemester() async {
    try {
      activeSemester.value = await _academic.fetchActiveSemester();
    } catch (_) {}
  }

  Future<void> _loadStudyPlans() async {
    try {
      final semId = activeSemester.value?.id;
      var list = await _academic.fetchStudyPlans(semesterId: semId);
      if (semId != null) {
        list = list.where((sp) => sp.semasterId == semId).toList();
      }
      studyPlans.assignAll(list);
    } catch (_) {}
  }

  /// Single-date study-plan exceptions: a cancelled class occurrence frees
  /// its room for that day in [conflictReason], mirroring the backend rule.
  Future<void> _loadClassCancellations() async {
    try {
      final sem = activeSemester.value;
      _classCancellations.assignAll(await _academic.fetchClassCancellations(
        from: sem?.startDate,
        to: sem?.endDate,
      ));
    } catch (_) {}
  }

  /// Returns a human-readable reason if [bookingDate] + [startTime] is in the
  /// past; null when the slot is in the future.
  String? pastSlotReason(DateTime bookingDate, String startTime) {
    if (isPastDate(bookingDate)) {
      return 'ບໍ່ສາມາດຈອງວັນທີ່ຜ່ານໄປແລ້ວ';
    }
    if (isPastSlot(bookingDate, startTime)) {
      return 'ບໍ່ສາມາດຈອງເວລາທີ່ຜ່ານໄປແລ້ວ';
    }
    return null;
  }

  String? conflictReason({
    required int roomId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
  }) {
    final date = dateOnly(bookingDate);
    final weekday = date.weekday;
    for (final p in studyPlans) {
      if (p.roomId != roomId) continue;
      if (dayOfWeekToWeekday(p.dayOfWeek) != weekday) continue;
      if (!timeRangesOverlap(
          startTime, endTime, p.startTime ?? '', p.endTime ?? '')) {
        continue;
      }
      // A class occurrence cancelled for this date (class_cancellations row)
      // does not occupy the room — same rule as the backend's check.
      final cancelled = _classCancellations.any(
          (cc) => cc.studyPlanId == p.id && sameDate(cc.cancelDate, date));
      if (!cancelled) {
        final code = p.room?.roomCode ?? 'ຫ້ອງ $roomId';
        final subj = p.subject?.nameLao ?? p.subject?.nameEng ?? 'ການຮຽນ';
        return 'ຫ້ອງ $code ມີຕາຕະລາງ "$subj" ${p.startTime}-${p.endTime} ໃນວັນດຽວກັນ';
      }
    }
    for (final b in _allBookings) {
      if (b.roomId != roomId) continue;
      if (!sameDate(b.bookingDate, date)) continue;
      final s = b.status.toLowerCase();
      if (s != 'pending' && s != 'approved') continue;
      if (!timeRangesOverlap(startTime, endTime, b.startTime, b.endTime)) {
        continue;
      }
      return 'ມີການຈອງ ${b.startTime}-${b.endTime} ໃນຫ້ອງນີ້ແລ້ວ';
    }
    return null;
  }

  /// Rooms that are free for the given date/time range. Returns an empty list
  /// when the slot itself is in the past — no room can be booked there.
  List<RoomModel> availableRoomsFor({
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
  }) {
    if (!_isValidTime(startTime) ||
        !_isValidTime(endTime) ||
        !_isStartBeforeEnd(startTime, endTime)) {
      return rooms.toList();
    }
    if (pastSlotReason(bookingDate, startTime) != null) {
      return const <RoomModel>[];
    }
    return rooms
        .where((r) =>
            conflictReason(
              roomId: r.id,
              bookingDate: bookingDate,
              startTime: startTime,
              endTime: endTime,
            ) ==
            null)
        .toList();
  }

  Future<void> createBooking({
    required int roomId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    String? purpose,
  }) async {
    try {
      isLoading.value = true;
      final user = currentUser.value;
      if (user == null) return;

      if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
        AppDialogs.showWarning(
          title: 'ຮູບແບບເວລາບໍ່ຖືກ',
          message: 'ກະລຸນາໃສ່ເວລາແບບ HH:mm (ເຊັ່ນ 08:30)',
        );
        return;
      }
      if (!_isStartBeforeEnd(startTime, endTime)) {
        AppDialogs.showWarning(
          title: 'ເວລາບໍ່ຖືກ',
          message: 'ເວລາເລີ່ມຕ້ອງກ່ອນເວລາສິ້ນສຸດ',
        );
        return;
      }

      final pastMsg = pastSlotReason(bookingDate, startTime);
      if (pastMsg != null) {
        AppDialogs.showWarning(
          title: 'ບໍ່ສາມາດຈອງໄດ້',
          message: pastMsg,
        );
        return;
      }

      // Spec §6.1: the backend is the authority on slot conflicts — probe
      // check-availability first; a 409 lands in the catch below. The create
      // itself re-checks under a room lock, covering the probe→create race.
      // (The local conflictReason stays for the sheet's live room filter.)
      final datePayload = bookingDatePayload(bookingDate);
      await _booking.checkAvailability(
        roomId: roomId,
        bookingDate: datePayload,
        startTime: startTime,
        endTime: endTime,
      );

      // Note: user_id is NOT sent — the backend derives the booker from the
      // JWT subject. Trusting a client-provided user_id would let any
      // logged-in user book on behalf of someone else.
      await _booking.createBooking(
        roomId: roomId,
        bookingDate: datePayload,
        startTime: startTime,
        endTime: endTime,
        purpose: purpose,
      );
      AppDialogs.showSuccess(
        title: 'ສົ່ງຄຳຂໍຈອງສຳເລັດ',
        message: 'ກະລຸນາລໍຖ້າການອະນຸມັດ',
      );
      await fetchData();
    } on DioException catch (e) {
      // 409 = the backend's conflict check rejected the slot. The body's
      // `conflict` field says what it clashed with: "class" = the room's
      // fixed class schedule, anything else = another booking.
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        final clashesClass = data is Map && data['conflict'] == 'class';
        AppDialogs.showWarning(
          title: 'ຫ້ອງບໍ່ວ່າງ',
          message: clashesClass
              ? 'ຊ່ວງເວລານີ້ກົງກັບຕາຕະລາງຮຽນປະຈຳຂອງຫ້ອງ ກະລຸນາເລືອກເວລາອື່ນ'
              : 'ຫ້ອງຖືກຈອງໄປແລ້ວໃນຊ່ວງເວລານີ້ ກະລຸນາເລືອກເວລາອື່ນ',
        );
        await fetchData();
        return;
      }
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'ສົ່ງຄຳຂໍບໍ່ສຳເລັດ',
        message: 'ກະລຸນາກວດສອບຂໍ້ມູນແລະລອງໃໝ່',
        detail: detail,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel an ad-hoc booking by id. Marks the booking as `cancelled` via
  /// PATCH `/room-bookings/:id/status`. Owner-only.
  Future<void> cancelBooking(RoomBookingModel b) async {
    final user = currentUser.value;
    if (user == null) return;
    if (b.userId != user.id) {
      AppDialogs.showWarning(
        title: 'ບໍ່ມີສິດ',
        message: 'ສາມາດຍົກເລີກໄດ້ສະເພາະການຈອງຂອງຕົນເອງ',
      );
      return;
    }
    if (isPastSlot(b.bookingDate, b.startTime)) {
      AppDialogs.showWarning(
        title: 'ການຈອງຜ່ານໄປແລ້ວ',
        message: 'ບໍ່ສາມາດຍົກເລີກການຈອງທີ່ຜ່ານໄປແລ້ວ',
      );
      return;
    }
    final ok = await AppDialogs.showConfirmation(
      title: 'ຍົກເລີກການຈອງ',
      message: 'ຕ້ອງການຍົກເລີກການຈອງນີ້ບໍ່?',
      confirmText: 'ຍົກເລີກການຈອງ',
      cancelText: 'ກັບຄືນ',
    );
    if (ok != true) return;

    try {
      isLoading.value = true;
      await _booking.updateStatus(b.bookingId, 'cancelled');
      AppDialogs.showSuccess(
        title: 'ຍົກເລີກສຳເລັດ',
        message: 'ການຈອງຖືກຍົກເລີກແລ້ວ',
      );
      await fetchData();
    } on DioException catch (e) {
      AppDialogs.showError(
        title: 'ຍົກເລີກບໍ່ສຳເລັດ',
        message: 'ກະລຸນາລອງໃໝ່',
        detail: AppDialogs.buildDioErrorDetail(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  static bool _isValidTime(String v) {
    final m = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').firstMatch(v.trim());
    return m != null;
  }

  static bool _isStartBeforeEnd(String start, String end) {
    int toMin(String t) {
      final parts = t.split(':');
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    return toMin(start.trim()) < toMin(end.trim());
  }
}
