import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// Reactive state owner for [TeacherHomeView].
///
/// Loads the signed-in teacher's dashboard counters and today's class list
/// in a single fan-out. Filtering is done both server-side (`teacher_id`
/// query param) and client-side, in case the backend ignores the filter.
class TeacherHomeController extends GetxController {
  TeacherHomeController({
    AuthProvider? auth,
    AcademicProvider? academic,
    BookingProvider? booking,
    EvaluationProvider? evaluation,
  })  : _auth = auth ?? AuthProvider(),
        _academic = academic ?? AcademicProvider(),
        _booking = booking ?? BookingProvider(),
        _eval = evaluation ?? EvaluationProvider();

  final AuthProvider _auth;
  final AcademicProvider _academic;
  final BookingProvider _booking;
  final EvaluationProvider _eval;

  /// `true` while [fetchDashboard] is in flight.
  final RxBool isLoading = false.obs;

  /// Last user-facing error from the load path; empty when none.
  final RxString errorMessage = ''.obs;

  /// Total number of study plans assigned to this teacher.
  final RxInt mySubjectsCount = 0.obs;

  /// Total room bookings created by this teacher's `user_id`.
  final RxInt myBookingsCount = 0.obs;

  /// Subset of [myBookingsCount] still awaiting approval.
  final RxInt myPendingBookingsCount = 0.obs;

  /// Total evaluation rows attributed to this teacher's study plans.
  final RxInt myEvaluationsCount = 0.obs;

  /// Today's classes, sorted by start time ascending.
  final RxList<StudyPlanModel> todaySchedules = <StudyPlanModel>[].obs;

  /// Currently signed-in user (used to derive [UserModel.teacherId]).
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  /// Refresh handler — bound to the bottom-nav tab refresher.
  Future<void> refreshData() => fetchDashboard();

  /// Run the full dashboard fan-out. Surfaces a friendly error in
  /// [errorMessage] on failure; always clears [isLoading] in `finally`.
  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadCurrentUser();
      final teacherId = currentUser.value?.teacherId;
      if (teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      final studyPlans = await _loadTeacherStudyPlans(teacherId);
      mySubjectsCount.value = studyPlans.length;
      final todays = _filterTodaysClasses(studyPlans);
      final cancelledIds = await _loadTodayCancelledPlanIds(teacherId);
      todaySchedules
          .assignAll(todays.where((sp) => !cancelledIds.contains(sp.id)));

      await _loadMyBookings();
      await _loadEvaluationCount(teacherId, studyPlans);
    } on DioException catch (e) {
      debugPrint(
        'Teacher dashboard Dio error:\n${AppDialogs.buildDioErrorDetail(e)}',
      );
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
          : 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້';
    } catch (e) {
      debugPrint('Teacher dashboard error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCurrentUser() async {
    currentUser.value = await _auth.me();
  }

  /// Server-side filter by `teacher_id`, with a client-side fallback when
  /// the backend ignores the filter (returns the full list, possibly empty).
  Future<List<StudyPlanModel>> _loadTeacherStudyPlans(int teacherId) async {
    final scoped = await _academic.fetchStudyPlans(teacherId: teacherId);
    if (scoped.isNotEmpty) return scoped;

    final all = await _academic.fetchStudyPlans();
    return all.where((sp) => sp.teacherId == teacherId).toList();
  }

  /// Filter [studyPlans] to entries whose `day_of_week` matches today and
  /// sort by start-time ascending. Uses the same tolerant weekday parsing as
  /// the schedule view so numeric / abbreviated `day_of_week` values still hit
  /// (the schedule showed classes the exact-name match here silently dropped).
  List<StudyPlanModel> _filterTodaysClasses(List<StudyPlanModel> studyPlans) {
    final today = DateTime.now().weekday;
    final todays = studyPlans
        .where((sp) => _dayOfWeekToWeekday(sp.dayOfWeek) == today)
        .toList();
    todays.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    return todays;
  }

  /// Plan ids cancelled for today — hidden from the home list. Non-fatal:
  /// on failure the list simply shows every scheduled class.
  Future<Set<int>> _loadTodayCancelledPlanIds(int teacherId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final rows = await _academic.fetchClassCancellations(
        teacherId: teacherId,
        from: today,
        to: today,
      );
      return rows.map((c) => c.studyPlanId).toSet();
    } catch (e) {
      debugPrint('Today cancellations error: $e');
      return const <int>{};
    }
  }

  Future<void> _loadMyBookings() async {
    final mine = (await _booking.fetchBookings(limit: 200))
        .where((b) => b.userId == currentUser.value?.id)
        .toList();
    myBookingsCount.value = mine.length;
    myPendingBookingsCount.value =
        mine.where((b) => b.status.toLowerCase() == 'pending').length;
  }

  /// Server-side filter by `teacher_id`; client-side intersection with the
  /// teacher's study-plan ids as a defensive fallback. Per the CLAUDE.md
  /// privacy rule, the parsed model strips student identifiers.
  Future<void> _loadEvaluationCount(
    int teacherId,
    List<StudyPlanModel> studyPlans,
  ) async {
    final spIds = studyPlans.map((sp) => sp.id).toSet();
    final results = await _eval.fetchResults(teacherId: teacherId);
    myEvaluationsCount.value =
        results.where((r) => spIds.contains(r.studyPlanId)).length;
  }

  /// Parse the backend `day_of_week` (full name, abbreviation, or 0/1-7
  /// numeric) into a [DateTime.weekday] value; -1 when unrecognised.
  // ponytail: third copy of this switch (schedule + student home have it);
  // extract to a shared util if a fourth caller appears.
  static int _dayOfWeekToWeekday(String? rawDay) {
    if (rawDay == null || rawDay.trim().isEmpty) return -1;
    switch (rawDay.trim().toLowerCase()) {
      case 'monday':
      case 'mon':
      case '1':
        return DateTime.monday;
      case 'tuesday':
      case 'tue':
      case '2':
        return DateTime.tuesday;
      case 'wednesday':
      case 'wed':
      case '3':
        return DateTime.wednesday;
      case 'thursday':
      case 'thu':
      case '4':
        return DateTime.thursday;
      case 'friday':
      case 'fri':
      case '5':
        return DateTime.friday;
      case 'saturday':
      case 'sat':
      case '6':
        return DateTime.saturday;
      case 'sunday':
      case 'sun':
      case '0':
      case '7':
        return DateTime.sunday;
      default:
        return -1;
    }
  }
}
