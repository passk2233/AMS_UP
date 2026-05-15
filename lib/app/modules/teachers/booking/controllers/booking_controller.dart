import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';
import 'fixed_booking.dart';

class BookingController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<RoomModel> rooms = <RoomModel>[].obs;
  final RxList<RoomBookingModel> myBookings = <RoomBookingModel>[].obs;
  final RxList<RoomBookingModel> _allBookings = <RoomBookingModel>[].obs;
  final RxList<StudyPlanModel> studyPlans = <StudyPlanModel>[].obs;
  final RxList<FixedBooking> fixedBookings = <FixedBooking>[].obs;

  /// UI filter for `myBookings`. One of: all | upcoming | pending | approved
  /// | cancelled | past.
  final RxString bookingFilter = 'all'.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<SemasterModel?> activeSemester = Rx<SemasterModel?>(null);

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    fetchData();
  }

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

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();

      final me = await _dio.get('/auth/me');
      if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
        currentUser.value = UserModel.fromJson(me.data);
      }
      final user = currentUser.value;
      if (user == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນຜູ້ໃຊ້';
        return;
      }

      await _loadActiveSemester();

      final roomResp = await _dio.get('/rooms', queryParameters: {'limit': 200});
      final roomItems = _extractList(roomResp.data);
      rooms.assignAll(roomItems.map((j) => RoomModel.fromJson(j)).toList());

      await _reloadBookings();

      await _loadStudyPlans();
      await _ensureFixedBookingsPersisted();
      _rebuildFixedBookings();
    } on DioException catch (e) {
      debugPrint('Booking Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດການຈອງໄດ້';
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

  /// Upcoming fixed bookings only (used by the page's primary list — past
  /// occurrences are hidden by default).
  List<FixedBooking> get upcomingFixedBookings =>
      fixedBookings.where((fb) => !isPastSlot(fb.date, fb.startTime)).toList();

  Future<void> _loadActiveSemester() async {
    try {
      final resp = await _dio.get('/semasters', queryParameters: {'limit': 20});
      final items = _extractList(resp.data);
      final all = items.map((j) => SemasterModel.fromJson(j)).toList();
      if (all.isEmpty) return;
      final now = DateTime.now();
      final containing = all.where((s) =>
          s.startDate != null &&
          s.endDate != null &&
          !now.isBefore(dateOnly(s.startDate!)) &&
          !now.isAfter(dateOnly(s.endDate!).add(const Duration(days: 1))));
      if (containing.isNotEmpty) {
        activeSemester.value = containing.first;
        return;
      }
      final active = all.where((s) => s.status == 1);
      activeSemester.value = active.isNotEmpty ? active.first : all.first;
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
      final query = <String, dynamic>{
        'teacher_id': teacherId,
        'limit': 200,
      };
      final semId = activeSemester.value?.id;
      if (semId != null) query['semaster_id'] = semId;
      final resp = await _dio.get('/study-plans', queryParameters: query);
      final items = _extractList(resp.data);
      var list = items.map((j) => StudyPlanModel.fromJson(j)).toList();
      if (semId != null) {
        list = list.where((sp) => sp.semasterId == semId).toList();
      }
      studyPlans.assignAll(list);
    } catch (e) {
      debugPrint('Study plans load error: $e');
    }
  }

  /// Reload `/room-bookings` into [_allBookings] and rebuild [myBookings].
  /// Fixed-booking marker rows (both active and cancelled) are excluded from
  /// the teacher's "my bookings" list — they live in the fixed section above.
  Future<void> _reloadBookings() async {
    final user = currentUser.value;
    if (user == null) return;
    final bResp =
        await _dio.get('/room-bookings', queryParameters: {'limit': 500});
    final bItems = _extractList(bResp.data);
    final all = bItems.map((j) => RoomBookingModel.fromJson(j)).toList();
    _allBookings.assignAll(all);

    final mine = all
        .where((b) =>
            b.userId == user.id &&
            parseFixedCancelPurpose(b.purpose) == null &&
            parseFixedActivePurpose(b.purpose) == null)
        .toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    myBookings.assignAll(mine);
  }

  /// Persist any study-plan occurrence that does not yet have a corresponding
  /// `room_booking` row. Each new row is created with the active marker
  /// purpose and PATCHed to status `approved`. Existing rows (active or
  /// cancelled) are left untouched.
  Future<void> _ensureFixedBookingsPersisted() async {
    final sem = activeSemester.value;
    final user = currentUser.value;
    if (sem == null ||
        sem.startDate == null ||
        sem.endDate == null ||
        user == null) {
      return;
    }
    final teacherId = user.teacherId;
    if (teacherId == null) return;

    final existing = <int, Set<String>>{};
    for (final b in _allBookings) {
      final pid = parseFixedActivePurpose(b.purpose) ??
          parseFixedCancelPurpose(b.purpose);
      if (pid == null) continue;
      existing
          .putIfAbsent(pid, () => <String>{})
          .add(_dateKey(b.bookingDate.toLocal()));
    }

    final today = dateOnly(DateTime.now());
    var created = 0;
    for (final p in studyPlans) {
      if (p.teacherId != teacherId) continue;
      if (p.roomId == null || p.startTime == null || p.endTime == null) {
        continue;
      }
      final dates = expandPlanDates(p, sem.startDate!, sem.endDate!);
      for (final d in dates) {
        if (d.isBefore(today.subtract(const Duration(days: 1)))) continue;
        final key = _dateKey(d);
        if (existing[p.id]?.contains(key) ?? false) continue;
        try {
          final resp = await _dio.post('/room-bookings', data: {
            'room_id': p.roomId,
            'user_id': user.id,
            'booking_date': _dateKey(d),
            'start_time': p.startTime,
            'end_time': p.endTime,
            'purpose': fixedActivePurpose(p.id),
          });
          final newId = (resp.data is Map<String, dynamic>)
              ? (resp.data['booking_id'] as int?)
              : null;
          if (newId != null) {
            try {
              await _dio.patch('/room-bookings/$newId/status',
                  data: {'status': 'approved'});
            } catch (_) {
              // Status PATCH may be rejected; row will surface as 'pending'.
            }
          }
          created++;
        } catch (e) {
          debugPrint('Persist fixed booking error (plan ${p.id} $key): $e');
        }
      }
    }
    if (created > 0) {
      await _reloadBookings();
    }
  }

  /// Builds [fixedBookings] purely from `room_booking` rows. Only rows carrying
  /// the active study-plan marker (`__sp_fixed:<plan_id>`) with a non-cancelled
  /// status are surfaced. Rows that are missing, cancelled, or carry the
  /// cancel marker (`__sp_cancel:<plan_id>`) are dropped, so they disappear
  /// from the teacher's UI.
  void _rebuildFixedBookings() {
    final plansById = <int, StudyPlanModel>{
      for (final p in studyPlans) p.id: p,
    };
    final today = dateOnly(DateTime.now());
    final out = <FixedBooking>[];
    for (final b in _allBookings) {
      final pid = parseFixedActivePurpose(b.purpose);
      if (pid == null) continue;
      final status = b.status.toLowerCase();
      if (status == 'cancelled' || status == 'rejected') continue;
      final plan = plansById[pid];
      if (plan == null) continue;
      if (plan.roomId == null || plan.startTime == null || plan.endTime == null) {
        continue;
      }
      final d = dateOnly(b.bookingDate.toLocal());
      if (d.isBefore(today.subtract(const Duration(days: 1)))) continue;
      out.add(FixedBooking(
        plan: plan,
        date: d,
        cancelled: false,
        bookingId: b.bookingId,
        cancelReason: null,
      ));
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
      final cancelled = _allBookings.any((b) =>
          parseFixedCancelPurpose(b.purpose) == p.id &&
          sameDate(b.bookingDate.toLocal(), date));
      if (!cancelled) {
        final code = p.room?.roomCode ?? 'Room $roomId';
        final subj = p.subject?.nameLao ?? p.subject?.nameEng ?? 'ການຮຽນ';
        return 'ຫ້ອງ $code ມີຕາຕະລາງ "$subj" ${p.startTime}-${p.endTime} ໃນວັນດຽວກັນ';
      }
    }

    for (final b in _allBookings) {
      if (b.roomId != roomId) continue;
      if (!sameDate(b.bookingDate.toLocal(), date)) continue;
      if (parseFixedCancelPurpose(b.purpose) != null) continue;
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
      await _loadToken();
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

      final clash = conflictReason(
        roomId: roomId,
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
      );
      if (clash != null) {
        AppDialogs.showWarning(
          title: 'ຫ້ອງບໍ່ວ່າງ',
          message: clash,
        );
        return;
      }

      final resp = await _dio.post('/room-bookings', data: {
        'room_id': roomId,
        'user_id': user.id,
        'booking_date': bookingDate.toUtc().toIso8601String(),
        'start_time': startTime,
        'end_time': endTime,
        'purpose': purpose,
      });

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        AppDialogs.showSuccess(
          title: 'ສົ່ງຄຳຂໍຈອງສຳເລັດ',
          message: 'ກະລຸນາລໍຖ້າການອະນຸມັດ',
        );
        await fetchData();
      } else {
        AppDialogs.showError(
          title: 'ສົ່ງຄຳຂໍບໍ່ສຳເລັດ',
          message: 'ກະລຸນາລອງໃໝ່',
        );
      }
    } on DioException catch (e) {
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
      await _loadToken();
      await _dio.patch('/room-bookings/${b.bookingId}/status',
          data: {'status': 'cancelled'});
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

  /// Locates an already-persisted `room_booking` row that backs the given
  /// study-plan occurrence by matching room/date/time, even when the row was
  /// not created with a `__sp_active` marker purpose.
  int? _findExistingFixedBookingId(FixedBooking fb) {
    final fbStart = timeToMinutes(fb.startTime);
    final fbEnd = timeToMinutes(fb.endTime);
    int? exactId;
    int? overlapId;
    int? sameRoomDateId;
    for (final b in _allBookings) {
      if (b.roomId != fb.roomId) continue;
      if (!sameDate(b.bookingDate.toLocal(), fb.date)) continue;
      if (parseFixedCancelPurpose(b.purpose) != null) continue;
      final s = b.status.toLowerCase();
      if (s == 'cancelled' || s == 'rejected') continue;
      final bStart = timeToMinutes(b.startTime);
      final bEnd = timeToMinutes(b.endTime);
      if (exactId == null && bStart == fbStart && bEnd == fbEnd) {
        exactId = b.bookingId;
      } else if (overlapId == null &&
          timeRangesOverlap(fb.startTime, fb.endTime, b.startTime, b.endTime)) {
        overlapId = b.bookingId;
      } else {
        sameRoomDateId ??= b.bookingId;
      }
    }
    final found = exactId ?? overlapId ?? sameRoomDateId;
    if (found == null) {
      debugPrint(
        'cancelFixedBooking: no backing row for plan=${fb.planId} '
        'room=${fb.roomId} date=${fb.date.toIso8601String()} '
        'time=${fb.startTime}-${fb.endTime}. '
        '_allBookings.length=${_allBookings.length}',
      );
    }
    return found;
  }

  /// Cancel a single occurrence of a study-plan-based fixed booking on
  /// [fb.date]. Updates the existing `room_booking` row's `purpose` with the
  /// cancellation reason and flips its status from `approved` to `cancelled`.
  /// Notifies every student in the affected student_group with [reason].
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
      await _loadToken();

      await _reloadBookings();
      var bookingId = fb.bookingId ?? _findExistingFixedBookingId(fb);
      if (bookingId == null) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບການຈອງ',
          message: 'ບໍ່ພົບຂໍ້ມູນການຈອງສຳລັບຄາບນີ້',
        );
        return;
      }

      final cancelPurpose =
          fixedCancelPurpose(fb.planId, trimmed.isEmpty ? null : trimmed);

      await _dio.patch('/room-bookings/$bookingId',
          data: {'purpose': cancelPurpose});
      await _dio.patch('/room-bookings/$bookingId/status',
          data: {'status': 'cancelled'});

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
      final notiResp = await _dio.post('/notifications', data: {
        'title': title,
        'message': message,
        'type': 'study_plan_cancel',
        'is_read': 0,
      });
      final notiId = (notiResp.data is Map<String, dynamic>)
          ? (notiResp.data['noti_id'] as int?)
          : null;
      if (notiId == null) return;

      final studentsResp = await _dio.get('/students',
          queryParameters: {'std_group_id': fb.stdGroupId, 'limit': 500});
      final studentItems = _extractList(studentsResp.data);
      final usersResp =
          await _dio.get('/users', queryParameters: {'limit': 1000});
      final userItems = _extractList(usersResp.data);
      final usersByStudent = <int, int>{};
      for (final u in userItems) {
        if (u is Map<String, dynamic>) {
          final uid = u['id'] as int?;
          final sid = u['std_id'] as int?;
          if (uid != null && sid != null) usersByStudent[sid] = uid;
        }
      }
      for (final s in studentItems) {
        if (s is! Map<String, dynamic>) continue;
        final sid = s['id'] as int?;
        if (sid == null) continue;
        final uid = usersByStudent[sid];
        if (uid == null) continue;
        try {
          await _dio.post('/user-noti', data: {
            'user_id': uid,
            'noti_id': notiId,
            'is_read': 0,
          });
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

  static String _dateKey(DateTime d) {
    final dd = dateOnly(d);
    return '${dd.year}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')}';
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
