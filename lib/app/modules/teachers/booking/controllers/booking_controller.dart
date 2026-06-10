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

  /// UI filter for `myBookings`. One of: all | upcoming | pending | approved
  /// | cancelled | past.
  final RxString bookingFilter = 'all'.obs;

  /// UI filter for [fixedBookings]. One of: upcoming | today | week |
  /// cancelled | all.
  final RxString fixedFilter = 'upcoming'.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<SemasterModel?> activeSemester = Rx<SemasterModel?>(null);

  /// Re-entrancy guard for [_ensureFixedBookingsPersisted]. Prevents two
  /// concurrent refreshes from racing and creating duplicate marker rows.
  bool _persisting = false;

  /// Diagnostic snapshot of the last [_ensureFixedBookingsPersisted] run.
  /// Surfaced by the booking view's diagnostic banner so a teacher (or the
  /// developer) can see *why* no fixed bookings appeared, instead of staring
  /// at an empty list and a silent debug log.
  ///
  /// `persistBailReason` is a short human-readable label for the early-return
  /// path that aborted persist (e.g. 'no active semester', 'no teacher id').
  /// Empty when persist ran the full loop.
  final RxString persistBailReason = ''.obs;
  final RxString persistLastError = ''.obs;
  final RxInt persistPlansConsidered = 0.obs;
  final RxInt persistPlansForMe = 0.obs;
  final RxInt persistPlansComplete = 0.obs;
  final RxInt persistSlotsSkippedExisting = 0.obs;
  final RxInt persistSlotsSkippedTaken = 0.obs;
  final RxInt persistRowsCreated = 0.obs;
  final RxInt persistMarkerRowsInDb = 0.obs;

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
      await _ensureFixedBookingsPersisted();
      _rebuildFixedBookings();

      // Make persist failures visible. Initial-load dialog fires only when
      // persist actually attempted a POST and got a backend error — quiet
      // for happy-path loads where everything was already persisted.
      if (persistLastError.value.isNotEmpty &&
          persistRowsCreated.value == 0) {
        AppDialogs.showError(
          title: 'ບໍ່ສາມາດສ້າງຄາບການຮຽນ',
          message: 'API ປະຕິເສດການສ້າງຄາບປະຈຳ. ກວດສອບ backend logs.',
          detail: persistLastError.value,
        );
      }
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
  /// Fixed-booking marker rows (both active and cancelled) are excluded from
  /// the teacher's "my bookings" list — they live in the fixed section above.
  Future<void> _reloadBookings() async {
    final user = currentUser.value;
    if (user == null) return;
    final all = await _booking.fetchBookings(limit: 500);
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
  ///
  /// Guarded against concurrent invocations via [_persisting] — a second
  /// refresh while the first persist is still in flight is a no-op so we
  /// never double-create the same marker row.
  Future<void> _ensureFixedBookingsPersisted() async {
    if (_persisting) return;

    persistBailReason.value = '';
    persistLastError.value = '';
    persistPlansConsidered.value = 0;
    persistPlansForMe.value = 0;
    persistPlansComplete.value = 0;
    persistSlotsSkippedExisting.value = 0;
    persistSlotsSkippedTaken.value = 0;
    persistRowsCreated.value = 0;
    persistMarkerRowsInDb.value = 0;

    final sem = activeSemester.value;
    final user = currentUser.value;
    if (user == null) {
      persistBailReason.value = 'ບໍ່ມີຜູ້ໃຊ້ (no current user)';
      return;
    }
    if (sem == null) {
      persistBailReason.value = 'ບໍ່ມີພາກຮຽນກຳລັງດຳເນີນ (no active semester)';
      return;
    }
    if (sem.startDate == null || sem.endDate == null) {
      persistBailReason.value =
          'ພາກຮຽນບໍ່ມີວັນທີເລີ່ມ/ສິ້ນສຸດ (semester missing start/end date)';
      return;
    }
    final teacherId = user.teacherId;
    if (teacherId == null) {
      persistBailReason.value =
          'ບັນຊີນີ້ບໍ່ມີ teacher_id (user is not a teacher)';
      return;
    }

    _persisting = true;
    try {
      final existing = <int, Set<String>>{};
      var markerRows = 0;
      for (final b in _allBookings) {
        final pid = parseFixedActivePurpose(b.purpose) ??
            parseFixedCancelPurpose(b.purpose);
        if (pid == null) continue;
        markerRows++;
        existing
            .putIfAbsent(pid, () => <String>{})
            .add(_dateKey(b.bookingDate.toLocal()));
      }
      persistMarkerRowsInDb.value = markerRows;
      persistPlansConsidered.value = studyPlans.length;

      var plansForMe = 0;
      var plansComplete = 0;
      var skippedExisting = 0;
      var skippedTaken = 0;
      final today = dateOnly(DateTime.now());
      var created = 0;
      for (final p in studyPlans) {
        if (p.teacherId != teacherId) continue;
        plansForMe++;
        if (p.roomId == null || p.startTime == null || p.endTime == null) {
          continue;
        }
        plansComplete++;
        final dates = expandPlanDates(p, sem.startDate!, sem.endDate!);
        for (final d in dates) {
          if (d.isBefore(today.subtract(const Duration(days: 1)))) continue;
          final key = _dateKey(d);
          if (existing[p.id]?.contains(key) ?? false) {
            skippedExisting++;
            continue;
          }

          // Skip when another non-marker booking already occupies this slot.
          // Without this guard a teacher who manually pre-booked the room for
          // their class would end up with two rows for the same period.
          final slotTaken = _allBookings.any((b) {
            if (b.roomId != p.roomId) return false;
            if (!sameDate(b.bookingDate.toLocal(), d)) return false;
            if (parseFixedActivePurpose(b.purpose) != null) return false;
            if (parseFixedCancelPurpose(b.purpose) != null) return false;
            final s = b.status.toLowerCase();
            if (s != 'approved' && s != 'pending') return false;
            return timeRangesOverlap(
                p.startTime ?? '', p.endTime ?? '', b.startTime, b.endTime);
          });
          if (slotTaken) {
            skippedTaken++;
            continue;
          }

          try {
            // user_id intentionally omitted — backend derives from JWT.
            final newId = await _booking.createBooking(
              roomId: p.roomId!,
              bookingDate: _bookingDatePayload(d),
              startTime: p.startTime!,
              endTime: p.endTime!,
              purpose: fixedActivePurpose(p.id),
            );
            if (newId != null) {
              try {
                await _booking.updateStatus(newId, 'approved');
              } catch (_) {
                // Status PATCH may be rejected; row will surface as 'pending'.
              }
            }
            // Remember the date locally so a follow-up plan iteration in this
            // same persist pass doesn't try to recreate it.
            existing.putIfAbsent(p.id, () => <String>{}).add(key);
            created++;
          } on DioException catch (e) {
            // Capture the FIRST error with full detail so the diagnostic
            // banner / dialog can show the backend's actual rejection
            // (status code + response body) — silent debugPrint is invisible
            // unless you happen to be running flutter run.
            if (persistLastError.value.isEmpty) {
              persistLastError.value =
                  'POST /room-bookings ${e.response?.statusCode ?? '?'} '
                  '(plan ${p.id} $key): '
                  '${e.response?.data ?? e.message ?? e}';
            }
            debugPrint(
              'Persist fixed booking Dio error (plan ${p.id} $key) '
              'status=${e.response?.statusCode} body=${e.response?.data}',
            );
          } catch (e) {
            if (persistLastError.value.isEmpty) {
              persistLastError.value =
                  'POST /room-bookings (plan ${p.id} $key): $e';
            }
            debugPrint('Persist fixed booking error (plan ${p.id} $key): $e');
          }
        }
      }
      persistPlansForMe.value = plansForMe;
      persistPlansComplete.value = plansComplete;
      persistSlotsSkippedExisting.value = skippedExisting;
      persistSlotsSkippedTaken.value = skippedTaken;
      persistRowsCreated.value = created;
      if (created > 0) {
        await _reloadBookings();
        // Refresh marker count from the post-create state.
        var refreshedMarkers = 0;
        for (final b in _allBookings) {
          if (parseFixedActivePurpose(b.purpose) != null ||
              parseFixedCancelPurpose(b.purpose) != null) {
            refreshedMarkers++;
          }
        }
        persistMarkerRowsInDb.value = refreshedMarkers;
      }
    } finally {
      _persisting = false;
    }
  }

  /// Builds [fixedBookings] from `room_booking` rows that carry a study-plan
  /// marker. Both active (`__sp_fixed:<plan_id>`) and cancelled
  /// (`__sp_cancel:<plan_id>`) markers are surfaced — the latter are flagged
  /// `cancelled: true` so the teacher can review (and restore) what they
  /// previously cancelled. Rows older than yesterday are dropped.
  void _rebuildFixedBookings() {
    final plansById = <int, StudyPlanModel>{
      for (final p in studyPlans) p.id: p,
    };
    final today = dateOnly(DateTime.now());
    final out = <FixedBooking>[];
    final seen = <String>{}; // de-dup on plan|date
    for (final b in _allBookings) {
      final activePid = parseFixedActivePurpose(b.purpose);
      final cancelPid = parseFixedCancelPurpose(b.purpose);
      final pid = activePid ?? cancelPid;
      if (pid == null) continue;
      final plan = plansById[pid];
      if (plan == null) continue;
      if (plan.roomId == null ||
          plan.startTime == null ||
          plan.endTime == null) {
        continue;
      }
      final d = dateOnly(b.bookingDate.toLocal());
      if (d.isBefore(today.subtract(const Duration(days: 1)))) continue;

      final dupKey = '$pid|${_dateKey(d)}';
      if (!seen.add(dupKey)) continue;

      final status = b.status.toLowerCase();
      final cancelled = cancelPid != null ||
          status == 'cancelled' ||
          status == 'rejected';

      out.add(FixedBooking(
        plan: plan,
        date: d,
        cancelled: cancelled,
        bookingId: b.bookingId,
        cancelReason: cancelled ? parseFixedCancelReason(b.purpose) : null,
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
      // A plan occurrence is treated as "freed" when its backing
      // room_booking row exists with status=cancelled (or rejected).
      // We used to look for an explicit `__sp_cancel:<pid>` purpose
      // marker, but the backend has no partial-update endpoint for
      // purpose, so cancellation now flips status alone — the marker
      // stays `__sp_fixed:<pid>`.
      final cancelled = _allBookings.any((b) {
        final pid = parseFixedActivePurpose(b.purpose) ??
            parseFixedCancelPurpose(b.purpose);
        if (pid != p.id) return false;
        if (!sameDate(b.bookingDate.toLocal(), date)) return false;
        final s = b.status.toLowerCase();
        return s == 'cancelled' || s == 'rejected';
      });
      if (!cancelled) {
        final code = p.room?.roomCode ?? 'ຫ້ອງ $roomId';
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

      // user_id intentionally omitted — backend derives from JWT.
      await _booking.createBooking(
        roomId: roomId,
        bookingDate: _bookingDatePayload(bookingDate),
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

  /// Locates an already-persisted `room_booking` row that backs the given
  /// study-plan occurrence. Resolution order, strongest match first:
  ///   1. Marker rows that already point at `fb.planId` (active or cancel).
  ///   2. Exact room + date + start + end time match (non-cancelled).
  ///   3. Room + date + time-overlap with the plan slot (non-cancelled).
  ///
  /// Rows that share only room + date but no time relation are deliberately
  /// **not** matched — that would risk cancelling an unrelated booking when
  /// two different reservations exist on the same room/day.
  int? _findExistingFixedBookingId(FixedBooking fb) {
    final fbStart = timeToMinutes(fb.startTime);
    final fbEnd = timeToMinutes(fb.endTime);
    int? markerId;
    int? exactId;
    int? overlapId;
    for (final b in _allBookings) {
      if (b.roomId != fb.roomId) continue;
      if (!sameDate(b.bookingDate.toLocal(), fb.date)) continue;

      final markerPid = parseFixedActivePurpose(b.purpose) ??
          parseFixedCancelPurpose(b.purpose);
      if (markerPid == fb.planId) {
        markerId ??= b.bookingId;
        continue;
      }
      if (markerPid != null) continue; // marker for a different plan — skip

      final s = b.status.toLowerCase();
      if (s == 'cancelled' || s == 'rejected') continue;

      final bStart = timeToMinutes(b.startTime);
      final bEnd = timeToMinutes(b.endTime);
      if (exactId == null && bStart == fbStart && bEnd == fbEnd) {
        exactId = b.bookingId;
      } else if (overlapId == null &&
          timeRangesOverlap(fb.startTime, fb.endTime, b.startTime, b.endTime)) {
        overlapId = b.bookingId;
      }
    }
    final found = markerId ?? exactId ?? overlapId;
    if (found == null) {
      debugPrint(
        'fixed booking lookup: no backing row for plan=${fb.planId} '
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

      await _reloadBookings();
      var bookingId = fb.bookingId ?? _findExistingFixedBookingId(fb);
      if (bookingId == null) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບການຈອງ',
          message: 'ບໍ່ພົບຂໍ້ມູນການຈອງສຳລັບຄາບນີ້',
        );
        return;
      }

      // Backend only exposes PATCH /room-bookings/:id/status — there is no
      // partial-update endpoint for `purpose`. We rely on status alone to
      // signal cancellation; `_rebuildFixedBookings` already treats a row
      // with status='cancelled' as cancelled regardless of its purpose
      // marker. The teacher-supplied reason rides along in the student
      // notification body below, which is where students actually see it.
      await _booking.updateStatus(bookingId, 'cancelled');

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

  /// Reverse a previously-cancelled fixed booking back to active. Flips the
  /// row's purpose to the active marker and its status back to `approved`.
  /// Owner-only.
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
      await _reloadBookings();
      final bookingId = fb.bookingId ?? _findExistingFixedBookingId(fb);
      if (bookingId == null) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບການຈອງ',
          message: 'ບໍ່ພົບຂໍ້ມູນການຈອງສຳລັບຄາບນີ້',
        );
        return;
      }
      // Backend has no PATCH /room-bookings/:id for partial purpose update.
      // The original row keeps its `__sp_fixed:<plan_id>` marker through the
      // cancel→restore cycle (we never overwrite it), so flipping status
      // back to `approved` is sufficient to restore the occurrence.
      await _booking.updateStatus(bookingId, 'approved');
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

  /// Re-runs the fixed-booking sync pipeline: semester → study plans →
  /// persist → reload → rebuild. Bound to the diagnostic banner's "retry"
  /// button so the teacher can re-try without a full app refresh.
  Future<void> resyncFixedBookings() async {
    try {
      isLoading.value = true;
      await _loadActiveSemester();
      await _loadStudyPlans();
      await _reloadBookings();
      await _ensureFixedBookingsPersisted();
      _rebuildFixedBookings();
      if (persistRowsCreated.value > 0) {
        AppDialogs.showSuccess(
          title: 'ດຶງຂໍ້ມູນສຳເລັດ',
          message: 'ສ້າງຄາບໃໝ່ ${persistRowsCreated.value} ລາຍການ',
        );
      } else if (persistBailReason.value.isNotEmpty) {
        AppDialogs.showWarning(
          title: 'ບໍ່ສາມາດສ້າງຄາບໄດ້',
          message: persistBailReason.value,
        );
      } else if (persistLastError.value.isNotEmpty) {
        AppDialogs.showError(
          title: 'ບໍ່ສາມາດສ້າງຄາບໄດ້',
          message: 'ມີຂໍ້ຜິດພາດຈາກ server',
          detail: persistLastError.value,
        );
      } else if (fixedBookings.isEmpty) {
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

  /// Date-only string `YYYY-MM-DD` for *internal* de-dup keys — do NOT send
  /// this to the backend. Use [_bookingDatePayload] for API payloads.
  static String _dateKey(DateTime d) {
    final dd = dateOnly(d);
    return '${dd.year}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')}';
  }

  /// RFC3339 representation of the chosen calendar date at midnight UTC:
  /// e.g. `2026-05-18T00:00:00.000Z`. The Go backend parses booking_date
  /// with layout `2006-01-02T15:04:05Z07:00`, which rejects a bare
  /// `YYYY-MM-DD` (`cannot parse "" as "T"`). Anchoring to UTC midnight
  /// keeps the date stable across timezones — converting back via
  /// `.toLocal()` lands on the same calendar day everywhere east of GMT.
  static String _bookingDatePayload(DateTime d) {
    final dd = dateOnly(d);
    return DateTime.utc(dd.year, dd.month, dd.day).toIso8601String();
  }

}
