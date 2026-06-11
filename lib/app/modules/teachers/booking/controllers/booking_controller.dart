import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';
import 'fixed_booking.dart';

class BookingController extends GetxController {
  BookingController({
    AuthProvider? auth,
    BookingProvider? booking,
    AcademicProvider? academic,
    PeopleProvider? people,
    NotificationProvider? notification,
  })  : _auth = auth ?? AuthProvider(),
        _booking = booking ?? BookingProvider(),
        _academic = academic ?? AcademicProvider(),
        _people = people ?? PeopleProvider(),
        _noti = notification ?? NotificationProvider();

  final AuthProvider _auth;
  final BookingProvider _booking;
  final AcademicProvider _academic;
  final PeopleProvider _people;
  final NotificationProvider _noti;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<RoomModel> rooms = <RoomModel>[].obs;
  final RxList<RoomBookingModel> myBookings = <RoomBookingModel>[].obs;
  final RxList<RoomBookingModel> _allBookings = <RoomBookingModel>[].obs;
  final RxList<StudyPlanModel> studyPlans = <StudyPlanModel>[].obs;
  final RxList<FixedBooking> fixedBookings = <FixedBooking>[].obs;
  final RxList<ClassCancellationModel> classCancellations =
      <ClassCancellationModel>[].obs;

  /// UI filter for `myBookings`. One of: all | upcoming | pending | approved
  /// | cancelled | past.
  final RxString bookingFilter = 'all'.obs;

  /// UI filter for [fixedBookings]. One of: upcoming | today | week |
  /// cancelled | all.
  final RxString fixedFilter = 'upcoming'.obs;

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

      await _reloadBookings();

      await _loadStudyPlans();
      await _loadClassCancellations();
      _rebuildFixedBookings();
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

  /// Upcoming, non-cancelled fixed bookings. Used by the dashboard's primary
  /// list when no explicit filter is engaged.
  List<FixedBooking> get upcomingFixedBookings => fixedBookings
      .where((fb) => !fb.cancelled && !isPastSlot(fb.date, fb.startTime))
      .toList();

  /// Fixed bookings filtered by [fixedFilter].
  ///   * upcoming — future + not cancelled (default)
  ///   * today    — date == today + not cancelled
  ///   * week     — within the next 7 days + not cancelled
  ///   * cancelled — only cancelled occurrences
  ///   * all      — everything in [fixedBookings]
  List<FixedBooking> get filteredFixedBookings {
    final f = fixedFilter.value;
    final today = dateOnly(DateTime.now());
    final weekEnd = today.add(const Duration(days: 7));
    return fixedBookings.where((fb) {
      switch (f) {
        case 'today':
          return !fb.cancelled && sameDate(fb.date, today);
        case 'week':
          return !fb.cancelled &&
              !fb.date.isBefore(today) &&
              !fb.date.isAfter(weekEnd);
        case 'cancelled':
          return fb.cancelled;
        case 'all':
          return true;
        case 'upcoming':
        default:
          return !fb.cancelled && !isPastSlot(fb.date, fb.startTime);
      }
    }).toList();
  }

  /// Header counts used by the fixed-booking section in the view.
  int get countFixedUpcoming => fixedBookings
      .where((fb) => !fb.cancelled && !isPastSlot(fb.date, fb.startTime))
      .length;
  int get countFixedToday {
    final today = dateOnly(DateTime.now());
    return fixedBookings
        .where((fb) => !fb.cancelled && sameDate(fb.date, today))
        .length;
  }
  int get countFixedCancelled =>
      fixedBookings.where((fb) => fb.cancelled).length;

  Future<void> _loadActiveSemester() async {
    try {
      activeSemester.value = await _academic.fetchActiveSemester();
    } catch (e) {
      debugPrint('Active semester load error: $e');
    }
  }

  Future<void> _loadStudyPlans() async {
    final teacherId = currentUser.value?.teacherId;
    if (teacherId == null) {
      studyPlans.clear();
      return;
    }
    try {
      final semId = activeSemester.value?.id;
      var list = await _academic.fetchStudyPlans(
        teacherId: teacherId,
        semesterId: semId,
        limit: 200,
      );
      if (semId != null) {
        list = list.where((sp) => sp.semasterId == semId).toList();
      }
      studyPlans.assignAll(list);
    } catch (e) {
      debugPrint('Study plans load error: $e');
    }
  }

  /// Reload `/room-bookings` into [_allBookings] and rebuild [myBookings].
  Future<void> _reloadBookings() async {
    final user = currentUser.value;
    if (user == null) return;
    final all = await _booking.fetchBookings(limit: 500);
    _allBookings.assignAll(all);

    final mine = all.where((b) => b.userId == user.id).toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    myBookings.assignAll(mine);
  }

  /// Load the single-date study-plan exceptions for the semester window.
  /// These drive both the struck-out occurrences in the fixed list and the
  /// "cancelled class frees its room" rule in [conflictReason].
  Future<void> _loadClassCancellations() async {
    try {
      final sem = activeSemester.value;
      classCancellations.assignAll(await _academic.fetchClassCancellations(
        from: sem?.startDate,
        to: sem?.endDate,
      ));
    } catch (e) {
      debugPrint('Class cancellations load error: $e');
    }
  }

  /// The cancellation row covering plan [planId] on [date], or null when the
  /// occurrence runs as scheduled.
  ClassCancellationModel? _cancellationFor(int planId, DateTime date) {
    for (final cc in classCancellations) {
      if (cc.studyPlanId == planId && sameDate(cc.cancelDate, date)) {
        return cc;
      }
    }
    return null;
  }

  /// Builds [fixedBookings] by expanding the teacher's own study plans into
  /// weekly occurrences across the active semester — entirely client-side,
  /// no `room_booking` rows involved. Occurrences with a matching
  /// [classCancellations] row are flagged `cancelled` (struck out in the UI,
  /// restorable via its row id). Dates older than yesterday are dropped.
  void _rebuildFixedBookings() {
    final sem = activeSemester.value;
    final teacherId = currentUser.value?.teacherId;
    if (sem == null ||
        sem.startDate == null ||
        sem.endDate == null ||
        teacherId == null) {
      fixedBookings.clear();
      return;
    }

    final today = dateOnly(DateTime.now());
    final out = <FixedBooking>[];
    for (final p in studyPlans) {
      if (p.teacherId != teacherId) continue;
      if (p.roomId == null || p.startTime == null || p.endTime == null) {
        continue;
      }
      for (final d in expandPlanDates(p, sem.startDate!, sem.endDate!)) {
        if (d.isBefore(today.subtract(const Duration(days: 1)))) continue;
        final cc = _cancellationFor(p.id, d);
        out.add(FixedBooking(
          plan: p,
          date: d,
          cancelled: cc != null,
          cancellationId: cc?.id,
          cancelReason: cc?.reason,
        ));
      }
    }
    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      return timeToMinutes(a.startTime).compareTo(timeToMinutes(b.startTime));
    });
    fixedBookings.assignAll(out);
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

  /// Returns a human-readable reason if [roomId] cannot host a booking on
  /// [bookingDate] [start,end]; null when the slot is free.
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
      if (_cancellationFor(p.id, date) != null) continue;
      final code = p.room?.roomCode ?? 'ຫ້ອງ $roomId';
      final subj = p.subject?.nameLao ?? p.subject?.nameEng ?? 'ການຮຽນ';
      return 'ຫ້ອງ $code ມີຕາຕະລາງ "$subj" ${p.startTime}-${p.endTime} ໃນວັນດຽວກັນ';
    }

    for (final b in _allBookings) {
      if (b.roomId != roomId) continue;
      if (!sameDate(b.bookingDate.toLocal(), date)) continue;
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

      // user_id intentionally omitted — backend derives from JWT.
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
  Future<void> cancelAdHocBooking(RoomBookingModel b) async {
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

  /// Cancel a single occurrence of the teacher's fixed class schedule on
  /// [fb.date] via POST /class-cancellations. The backend enforces that only
  /// the plan's own teacher (or an admin) may do this; the guard here just
  /// gives instant feedback. Notifies every student in the affected
  /// student_group with [reason].
  Future<void> cancelFixedBooking(FixedBooking fb, {String? reason}) async {
    final user = currentUser.value;
    if (user == null) return;
    final teacherId = user.teacherId;
    if (teacherId == null || teacherId != fb.teacherId) {
      AppDialogs.showWarning(
        title: 'ບໍ່ມີສິດ',
        message: 'ສະເພາະອາຈານຂອງວິຊານີ້ສາມາດຍົກເລີກໄດ້',
      );
      return;
    }
    if (fb.cancelled) {
      AppDialogs.showWarning(
        title: 'ຍົກເລີກແລ້ວ',
        message: 'ຄາບນີ້ຖືກຍົກເລີກໄປແລ້ວ',
      );
      return;
    }
    if (isPastSlot(fb.date, fb.startTime)) {
      AppDialogs.showWarning(
        title: 'ຄາບນີ້ຜ່ານໄປແລ້ວ',
        message: 'ບໍ່ສາມາດຍົກເລີກຄາບທີ່ຜ່ານໄປແລ້ວ',
      );
      return;
    }
    final trimmed = (reason ?? '').trim();
    try {
      isLoading.value = true;

      await _academic.cancelClassOccurrence(
        studyPlanId: fb.planId,
        date: fb.date,
        reason: trimmed,
      );

      await _notifyGroupOfCancellation(fb, trimmed);

      AppDialogs.showSuccess(
        title: 'ຍົກເລີກສຳເລັດ',
        message: 'ໄດ້ສົ່ງການແຈ້ງເຕືອນຫານັກສຶກສາແລ້ວ',
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

  /// Restore a previously-cancelled class occurrence by deleting its
  /// class_cancellations row. Owner-only (backend-enforced).
  Future<void> restoreFixedBooking(FixedBooking fb) async {
    final user = currentUser.value;
    if (user == null) return;
    final teacherId = user.teacherId;
    if (teacherId == null || teacherId != fb.teacherId) {
      AppDialogs.showWarning(
        title: 'ບໍ່ມີສິດ',
        message: 'ສະເພາະອາຈານຂອງວິຊານີ້ສາມາດກູ້ຄືນໄດ້',
      );
      return;
    }
    if (!fb.cancelled) return;
    if (isPastSlot(fb.date, fb.startTime)) {
      AppDialogs.showWarning(
        title: 'ຄາບນີ້ຜ່ານໄປແລ້ວ',
        message: 'ບໍ່ສາມາດກູ້ຄືນຄາບທີ່ຜ່ານໄປແລ້ວ',
      );
      return;
    }

    final ok = await AppDialogs.showConfirmation(
      title: 'ກູ້ຄືນຄາບການຮຽນ',
      message: 'ກູ້ຄືນຄາບການຮຽນວັນທີ ${fb.date.day}/${fb.date.month}/${fb.date.year} '
          'ເວລາ ${fb.startTime}-${fb.endTime}?',
      confirmText: 'ກູ້ຄືນ',
      cancelText: 'ກັບຄືນ',
    );
    if (ok != true) return;

    try {
      isLoading.value = true;
      final ccId = fb.cancellationId;
      if (ccId == null) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບຂໍ້ມູນ',
          message: 'ບໍ່ພົບລາຍການຍົກເລີກສຳລັບຄາບນີ້',
        );
        return;
      }
      await _academic.restoreClassOccurrence(ccId);
      AppDialogs.showSuccess(
        title: 'ກູ້ຄືນສຳເລັດ',
        message: 'ຄາບການຮຽນຖືກກູ້ຄືນແລ້ວ',
      );
      await fetchData();
    } on DioException catch (e) {
      AppDialogs.showError(
        title: 'ກູ້ຄືນບໍ່ສຳເລັດ',
        message: 'ກະລຸນາລອງໃໝ່',
        detail: AppDialogs.buildDioErrorDetail(e),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-fetches the fixed-schedule inputs (semester → study plans →
  /// cancellations) and rebuilds the list. Bound to the empty-state banner's
  /// "retry" button so the teacher can re-try without a full app refresh.
  Future<void> resyncFixedBookings() async {
    try {
      isLoading.value = true;
      await _loadActiveSemester();
      await _loadStudyPlans();
      await _loadClassCancellations();
      _rebuildFixedBookings();
      if (fixedBookings.isEmpty) {
        AppDialogs.showWarning(
          title: 'ບໍ່ມີຄາບການຮຽນ',
          message: 'ບໍ່ມີ study_plan ສຳລັບອາຈານໃນພາກຮຽນນີ້',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _notifyGroupOfCancellation(
      FixedBooking fb, String reason) async {
    final subject = fb.plan.subject?.nameLao ?? fb.plan.subject?.nameEng ?? 'ວິຊາ';
    final group = fb.plan.studentGroup?.stdGroupName ?? 'ກຸ່ມ ${fb.stdGroupId}';
    final dateStr = '${fb.date.day}/${fb.date.month}/${fb.date.year}';
    final title = 'ຍົກເລີກການຮຽນ - $subject';
    final base =
        'ກຸ່ມ $group: ການຮຽນວິຊາ $subject ໃນວັນທີ $dateStr ເວລາ ${fb.startTime}-${fb.endTime} ຖືກຍົກເລີກ';
    final message = reason.trim().isEmpty ? base : '$base\nເຫດຜົນ: $reason';

    try {
      final notiId = await _noti.create(
        title: title,
        message: message,
        type: 'study_plan_cancel',
      );
      if (notiId == null) return;

      final students =
          await _people.fetchStudents(studentGroupId: fb.stdGroupId);
      final users = await _people.fetchUsers();
      final usersByStudent = <int, int>{
        for (final u in users)
          if (u.stdId != null) u.stdId!: u.id,
      };
      for (final s in students) {
        final uid = usersByStudent[s.id];
        if (uid == null) continue;
        try {
          await _noti.createUserNoti(userId: uid, notiId: notiId);
        } catch (_) {
          // user-noti endpoint may be unavailable; the global notification
          // still surfaces via the notifications feed.
        }
      }
    } catch (e) {
      debugPrint('Notify group of cancel error: $e');
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
