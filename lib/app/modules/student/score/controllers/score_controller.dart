import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

/// A single academic semester's worth of enrollments plus the resolved
/// term/year used to label it exactly like the official transcript
/// ("ເທີມ 1 ສົກສຶກສາ 2022 - 2023").
class ScoreSemester {
  final int semasterId;

  /// 1 / 2 — or 0 when the term could not be resolved.
  final int term;

  /// Academic *start* year (e.g. 2022 for "2022 - 2023") — 0 when unknown.
  final int year;

  /// Raw semester code, used as a label fallback when term/year are unknown.
  final String? code;

  final List<EnrollmentModel> enrollments;

  const ScoreSemester({
    required this.semasterId,
    required this.term,
    required this.year,
    required this.code,
    required this.enrollments,
  });
}

class ScoreController extends GetxController {
  ScoreController({AuthProvider? auth, AcademicProvider? academic})
      : _auth = auth ?? AuthProvider(),
        _academic = academic ?? AcademicProvider();

  final AuthProvider _auth;
  final AcademicProvider _academic;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<EnrollmentModel> enrollments = <EnrollmentModel>[].obs;

  /// Currently selected semester (its `semaster_id`); -1 = none/auto.
  final RxInt selectedSemesterId = (-1).obs;
  void changeSemester(int semasterId) => selectedSemesterId.value = semasterId;

  /// Resolved term/year metadata keyed by `semaster_id`, fetched from
  /// `/semasters` because the `/enrollments` payload only carries the FK.
  final Map<int, SemasterModel> _semesterById = {};

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      currentUser.value = await _auth.me();
      final stdId = currentUser.value?.stdId ?? currentUser.value?.student?.id;
      if (stdId == null) {
        errorMessage.value = 'ບັນຊີນັກສຶກສາຍັງບໍ່ໄດ້ເຊື່ອມຕໍ່.';
        return;
      }

      await _loadSemesters();

      enrollments.assignAll(await _academic.fetchEnrollments(studentId: stdId));

      _ensureSelection();
    } on DioException catch (e) {
      debugPrint(
          'ScoreController Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບຫມົດອາຍຸ. ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່.'
          : 'ບໍ່ສາມາດໂຫຼດຄະແນນໄດ້.';
    } catch (e) {
      debugPrint('ScoreController error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຄະແນນໄດ້.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSemesters() async {
    try {
      _semesterById.clear();
      for (final s in await _academic.fetchSemesters(limit: 100)) {
        _semesterById[s.id] = s;
      }
    } on DioException catch (e) {
      debugPrint(
          'ScoreController semesters Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
    } catch (e) {
      debugPrint('ScoreController semesters error: $e');
    }
  }

  /// Default the selection to the latest (most recent) semester when nothing
  /// valid is selected yet.
  void _ensureSelection() {
    final groups = semesters;
    if (groups.isEmpty) {
      selectedSemesterId.value = -1;
      return;
    }
    final exists = groups.any((g) => g.semasterId == selectedSemesterId.value);
    if (!exists) selectedSemesterId.value = groups.last.semasterId;
  }

  // ── Profile helpers ──────────────────────────────────────────────────────

  String get displayName {
    final s = currentUser.value?.student;
    if (s == null) return currentUser.value?.username ?? '';
    final surname = (s.surnameEng ?? '').trim();
    final name = s.nameEng.trim();
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get studentCode => currentUser.value?.student?.stdCode ?? '-';

  /// Stored profile photo path/URL; null when unset (header shows placeholder).
  String? get photo => currentUser.value?.student?.photo;

  String get curriculumName =>
      currentUser.value?.student?.curriculum?.curriNameEng ??
      currentUser.value?.student?.curriculum?.curriNameLao ??
      '-';

  // ── Semester grouping ────────────────────────────────────────────────────

  /// Distinct semesters present in the enrollments, ordered oldest → newest
  /// (chronological, so cumulative CGPA is computed in the right order).
  List<ScoreSemester> get semesters {
    final byId = <int, List<EnrollmentModel>>{};
    for (final e in enrollments) {
      final sid = e.studyPlan?.semasterId;
      if (sid == null || sid == 0) continue;
      (byId[sid] ??= []).add(e);
    }

    final list = byId.entries.map((entry) {
      final resolved =
          _semesterById[entry.key] ?? entry.value.first.studyPlan?.semaster;
      return ScoreSemester(
        semasterId: entry.key,
        term: resolved?.term ?? 0,
        year: resolved?.year ?? 0,
        code: resolved?.semasterCode,
        enrollments: entry.value,
      );
    }).toList();

    list.sort((a, b) {
      if (a.year > 0 && b.year > 0) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        if (a.term != b.term) return a.term.compareTo(b.term);
      }
      return a.semasterId.compareTo(b.semasterId);
    });
    return list;
  }

  /// Chip display order — most recent term first so the (default-selected)
  /// latest semester is visible without scrolling.
  List<ScoreSemester> get semestersNewestFirst => semesters.reversed.toList();

  ScoreSemester? get selectedSemester {
    final groups = semesters;
    if (groups.isEmpty) return null;
    final match =
        groups.where((g) => g.semasterId == selectedSemesterId.value);
    return match.isNotEmpty ? match.first : groups.last;
  }

  /// Full transcript-style label, e.g. "ເທີມ 1 ສົກສຶກສາ 2022 - 2023".
  String labelFor(ScoreSemester s) {
    if (s.term > 0 && s.year > 0) {
      return 'ເທີມ ${s.term} ສົກສຶກສາ ${s.year} - ${s.year + 1}';
    }
    if (s.code != null && s.code!.isNotEmpty) return s.code!;
    final idx = semesters.indexWhere((g) => g.semasterId == s.semasterId) + 1;
    return 'ເທີມ $idx';
  }

  /// Two-line chip label: top "ເທີມ 1", bottom "ສົກສຶກສາ 2022 - 2023".
  ({String line1, String line2}) chipLabelFor(ScoreSemester s) {
    if (s.term > 0 && s.year > 0) {
      return (
        line1: 'ເທີມ ${s.term}',
        line2: 'ສົກສຶກສາ ${s.year} - ${s.year + 1}',
      );
    }
    if (s.code != null && s.code!.isNotEmpty) {
      return (line1: s.code!, line2: '');
    }
    final idx = semesters.indexWhere((g) => g.semasterId == s.semasterId) + 1;
    return (line1: 'ເທີມ $idx', line2: '');
  }

  // ── Aggregate / cumulative stats (transcript header) ──────────────────────

  /// Overall credit-weighted GPA across every graded course (= final CGPA).
  double get gpa => _gpaOf(enrollments);

  /// Sum of credits across all enrolled courses.
  int get totalCredits => _creditsOf(enrollments);

  /// Total number of courses on record.
  int get totalSubjects => enrollments.length;

  /// Number of terms studied (distinct semesters with records).
  int get currentTermNumber => semesters.length;

  /// Total terms in the program. Derived from the highest curriculum year
  /// among the student's subjects (years × 2); falls back to rounding the
  /// studied-term count up to the nearest even number. Always ≥ studied terms.
  int get totalProgramTerms {
    final studied = semesters.length;
    var maxYear = 0;
    for (final e in enrollments) {
      final y = e.studyPlan?.subject?.year ?? 0;
      if (y > maxYear) maxYear = y;
    }
    final total =
        maxYear > 0 ? maxYear * 2 : (studied.isOdd ? studied + 1 : studied);
    return math.max(total, studied);
  }

  /// Current academic year (1-based), e.g. term 7 → year 4.
  int get currentAcademicYear =>
      currentTermNumber == 0 ? 0 : (currentTermNumber / 2).ceil();

  // ── Selected-semester stats (transcript per-term footer) ──────────────────

  double get selectedSemesterGpa => _gpaOf(selectedSemester?.enrollments ?? []);
  int get selectedSemesterCredits =>
      _creditsOf(selectedSemester?.enrollments ?? []);
  int get selectedSemesterSubjects => selectedSemester?.enrollments.length ?? 0;

  double get selectedCumulativeGpa {
    final s = selectedSemester;
    return s == null ? 0 : _gpaOf(_enrollmentsUpTo(s));
  }

  int get selectedCumulativeCredits {
    final s = selectedSemester;
    return s == null ? 0 : _creditsOf(_enrollmentsUpTo(s));
  }

  List<EnrollmentModel> _enrollmentsUpTo(ScoreSemester target) {
    final out = <EnrollmentModel>[];
    for (final g in semesters) {
      out.addAll(g.enrollments);
      if (g.semasterId == target.semasterId) break;
    }
    return out;
  }

  /// Per-semester GPA series (chronological), skipping ungraded semesters —
  /// used by the GPA trend sparkline.
  List<double> get gpaTrend {
    final out = <double>[];
    for (final s in semesters) {
      final hasGrade =
          s.enrollments.any((e) => (e.grade?.trim().isNotEmpty ?? false));
      if (hasGrade) out.add(_gpaOf(s.enrollments));
    }
    return out;
  }

  // ── Grade math ────────────────────────────────────────────────────────────

  static double _gpaOf(List<EnrollmentModel> list) {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final e in list) {
      final grade = e.grade?.trim();
      if (grade == null || grade.isEmpty) continue;
      final credit = e.studyPlan?.subject?.credit ?? 0;
      final gp = _gradePoint(grade);
      if (gp == null || credit <= 0) continue;
      totalCredits += credit;
      totalPoints += gp * credit;
    }
    return totalCredits == 0 ? 0 : totalPoints / totalCredits;
  }

  static int _creditsOf(List<EnrollmentModel> list) {
    int sum = 0;
    for (final e in list) {
      final credit = e.studyPlan?.subject?.credit ?? 0;
      if (credit > 0) sum += credit;
    }
    return sum;
  }

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

}
