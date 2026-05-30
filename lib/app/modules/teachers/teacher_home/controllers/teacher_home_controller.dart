import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/api_client.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// Reactive state owner for [TeacherHomeView].
///
/// Loads the signed-in teacher's dashboard counters and today's class list
/// in a single fan-out. Filtering is done both server-side (`teacher_id`
/// query param) and client-side, in case the backend ignores the filter.
class TeacherHomeController extends GetxController {
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

  Dio get _dio => ApiClient.dio;

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
      todaySchedules.assignAll(_filterTodaysClasses(studyPlans));

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
    final me = await _dio.get('/auth/me');
    if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
      currentUser.value = UserModel.fromJson(me.data);
    }
  }

  /// Server-side filter by `teacher_id`, with a client-side fallback when
  /// the backend ignores the filter (returns the full list, possibly empty).
  Future<List<StudyPlanModel>> _loadTeacherStudyPlans(int teacherId) async {
    final scoped = await _dio.get(
      '/study-plans',
      queryParameters: {'teacher_id': teacherId, 'limit': 500},
    );
    final scopedList = _extractList(scoped.data)
        .map((j) => StudyPlanModel.fromJson(j))
        .toList();
    if (scopedList.isNotEmpty) return scopedList;

    final all = await _dio.get(
      '/study-plans',
      queryParameters: {'limit': 500},
    );
    return _extractList(all.data)
        .map((j) => StudyPlanModel.fromJson(j))
        .where((sp) => sp.teacherId == teacherId)
        .toList();
  }

  /// Filter [studyPlans] to entries whose `day_of_week` matches today and
  /// sort by start-time ascending.
  List<StudyPlanModel> _filterTodaysClasses(List<StudyPlanModel> studyPlans) {
    final todayKey = _todayKey();
    final todays = studyPlans
        .where((sp) => (sp.dayOfWeek ?? '').toLowerCase() == todayKey)
        .toList();
    todays.sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
    return todays;
  }

  Future<void> _loadMyBookings() async {
    final response = await _dio.get(
      '/room-bookings',
      queryParameters: {'limit': 200},
    );
    final mine = _extractList(response.data)
        .map((j) => RoomBookingModel.fromJson(j))
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
    final response = await _dio.get(
      '/evaluation-results',
      queryParameters: {'teacher_id': teacherId, 'limit': 500},
    );
    myEvaluationsCount.value = _extractList(response.data)
        .map((j) => EvaluationResultModel.fromJson(j))
        .where((r) => spIds.contains(r.studyPlanId))
        .length;
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }

  /// Lowercase English weekday name matching the backend's `day_of_week`
  /// column.
  static String _todayKey() {
    const keys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return keys[(DateTime.now().weekday - 1).clamp(0, 6)];
  }
}
