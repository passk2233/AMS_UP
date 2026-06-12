import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

/// Controller for the student dashboard / home page.
/// Fetches user profile, enrollments, and today's schedule.
class HomePageController extends GetxController {
  HomePageController({
    AuthProvider? auth,
    AcademicProvider? academic,
    EvaluationProvider? evaluation,
  })  : _auth = auth ?? AuthProvider(),
        _academic = academic ?? AcademicProvider(),
        _eval = evaluation ?? EvaluationProvider();

  final AuthProvider _auth;
  final AcademicProvider _academic;
  final EvaluationProvider _eval;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<EnrollmentModel> enrollments = <EnrollmentModel>[].obs;
  final RxList<StudyPlanModel> studyPlans = <StudyPlanModel>[].obs;
  final Rx<SemasterModel?> activeSemester = Rx<SemasterModel?>(null);

  /// `true` while the admin-controlled `open_evalu` window is active and
  /// `now` falls within it. Drives the home page's "ປະເມີນອາຈານ" button.
  final RxBool isEvaluationWindowOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // ── ດຶງຂໍ້ມູນຜູ້ໃຊ້ ──
      currentUser.value = await _auth.me();

      final stdId = currentUser.value?.stdId ?? currentUser.value?.student?.id;
      if (stdId == null) {
        errorMessage.value = 'ບັນຊີນັກສຶກສາບໍ່ໄດ້ເຊື່ອມຕໍ່.';
        return;
      }

      await _loadActiveSemester();
      await _loadEvaluationWindow();

      // ── ດຶງ enrollments (ສຳລັບ GPA + ຈຳນວນວິຊາ) ──
      enrollments.assignAll(await _academic.fetchEnrollments(studentId: stdId));

      // ── ດຶງ study plans (ສຳລັບຫ້ອງຮຽນມື້ນີ້) ──
      final groupId = currentUser.value?.student?.stdGroupId;
      if (groupId != null) {
        studyPlans.assignAll(
          await _academic.fetchStudyPlans(studentGroupId: groupId, limit: 200),
        );
      }
    } on DioException catch (e) {
      debugPrint(
          'HomePageController Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      errorMessage.value = e.response?.statusCode == 401
          ? 'Session ໝົດອາຍຸ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.'
          : 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້.';
    } catch (e) {
      debugPrint('HomePageController error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadActiveSemester() async {
    try {
      activeSemester.value = await _academic.fetchActiveSemester();
    } catch (_) {}
  }

  /// Public wrapper around [_loadEvaluationWindow] so the home view can
  /// refresh the gate (e.g. after the student returns from the feedback
  /// flow) without paying for a full [fetchDashboard].
  Future<void> refreshEvaluationWindow() => _loadEvaluationWindow();

  /// GET `/open-evalu?inactive=0&limit=1` and set [isEvaluationWindowOpen]
  /// according to the row's `isOpenNow`. Mirrors the same gate used by the
  /// faculty-feedback page so the home CTA and that page stay in sync.
  Future<void> _loadEvaluationWindow() async {
    try {
      final window = await _eval.fetchActiveWindow();
      isEvaluationWindowOpen.value = window != null && window.inactive == 0;
    } on DioException catch (e) {
      isEvaluationWindowOpen.value = false;
      debugPrint('loadEvaluationWindow error: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════

  String get displayName {
    final s = currentUser.value?.student;
    if (s == null) return currentUser.value?.username ?? '';
    final name = s.nameLao.trim();
    final surname = (s.surnameLao ?? '').trim();
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get currentDate => DateFormat('dd/MM/yyyy').format(DateTime.now());

  int get totalClasses => todayClasses.length;

  int get totalSubjects {
    final unique = <int>{};
    for (final e in enrollments) {
      final subId = e.studyPlan?.subject?.id;
      if (subId != null) unique.add(subId);
    }
    return unique.length;
  }

  double get gpa {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final e in enrollments) {
      final grade = e.grade?.trim();
      if (grade == null || grade.isEmpty) continue;
      final credit = e.studyPlan?.subject?.credit ?? 0;
      final gp = _gradePoint(grade);
      if (gp == null || credit <= 0) continue;
      totalCredits += credit;
      totalPoints += gp * credit;
    }
    if (totalCredits == 0) return 0;
    return totalPoints / totalCredits;
  }

  List<Map<String, String>> get todayClasses {
    final today = DateTime.now().weekday;
    final todayPlans = studyPlans.where((p) {
      return _dayOfWeekToWeekday(p.dayOfWeek) == today;
    }).toList()
      ..sort((a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

    return todayPlans.map((p) {
      final subject = p.subject?.nameLao ?? p.subject?.nameEng ?? 'ວິຊາ';
      final room = p.room?.roomCode ?? '-';
      final start = _formatTime(p.startTime);
      final end = _formatTime(p.endTime);
      return {
        'subject': subject,
        'time': '$start - $end',
        'room': room,
      };
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  static double? _gradePoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 4.0;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.5;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return null;
    }
  }

  int _dayOfWeekToWeekday(String? rawDay) {
    if (rawDay == null || rawDay.trim().isEmpty) return -1;
    final d = rawDay.trim().toLowerCase();
    switch (d) {
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

  int _timeToMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
    if (match == null) return 0;
    final h = int.tryParse(match.group(1) ?? '') ?? 0;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    return (h * 60) + m;
  }

  String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
    if (match == null) return value.trim();
    final h = int.tryParse(match.group(1) ?? '') ?? 0;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    return DateFormat('HH:mm').format(DateTime(2000, 1, 1, h, m));
  }

}
