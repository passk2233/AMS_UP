import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class TeacherEvaluationController extends GetxController {
  TeacherEvaluationController({
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

  final RxList<EvaluationResultModel> results = <EvaluationResultModel>[].obs;
  final RxList<SubjectEvalGroup> subjectGroups = <SubjectEvalGroup>[].obs;
  final RxList<EvaluationQuestionModel> questions = <EvaluationQuestionModel>[].obs;

  /// Selected semester filter — 0 means "all semesters".
  final RxInt selectedSemesterId = 0.obs;

  /// Study plans keyed by id, kept for re-grouping when the filter changes.
  final Map<int, StudyPlanModel> _spMap = {};

  int? _currentTeacherId;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // 1. Get current user to find teacher ID
      _currentTeacherId = (await _auth.me())?.teacherId;
      final teacherId = _currentTeacherId;
      if (teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      // 2. Fetch study plans for this teacher (with preloads)
      _spMap.clear();
      for (final sp
          in await _academic.fetchStudyPlans(teacherId: teacherId, limit: 200)) {
        _spMap[sp.id] = sp;
      }
      final spMap = _spMap;

      // 3. Fetch evaluation results — the backend scopes non-admin callers
      //    to their own teacher_id (joined through study_plan) and returns
      //    the anonymised projection without student_id. The client-side
      //    spMap intersect below stays as belt-and-braces.
      final myResults = (await _eval.fetchResults(teacherId: teacherId))
          .where((r) => spMap.containsKey(r.studyPlanId))
          .toList();

      // Enrich with study plan data
      for (final r in myResults) {
        final sp = spMap[r.studyPlanId];
        if (sp != null) r.studyPlan = sp;
      }
      results.assignAll(myResults);

      // 4. Fetch questions
      questions.assignAll(await _eval.fetchQuestions());

      // Drop a stale filter whose semester no longer appears in the data.
      if (selectedSemesterId.value != 0 &&
          !semesterOptions.any((s) => s.id == selectedSemesterId.value)) {
        selectedSemesterId.value = 0;
      }
      _buildSubjectGroups();
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('TeacherEvaluation Dio error:\n$detail');

      // 401 is handled centrally by ApiClient — only set the error string.
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
          : 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  /// Distinct semesters present in [results], newest first.
  List<({int id, String label})> get semesterOptions {
    final seen = <int, String>{};
    for (final r in results) {
      final sp = r.studyPlan;
      if (sp == null || seen.containsKey(sp.semasterId)) continue;
      seen[sp.semasterId] = sp.semaster != null
          ? 'ປີ ${sp.semaster!.year} ເທີມ ${sp.semaster!.term}'
          : 'ເທີມ ${sp.semasterId}';
    }
    return (seen.entries.map((e) => (id: e.key, label: e.value)).toList()
      ..sort((a, b) => b.id.compareTo(a.id)));
  }

  /// Rows narrowed to [selectedSemesterId] (all rows when the filter is 0).
  List<EvaluationResultModel> get _filteredResults =>
      selectedSemesterId.value == 0
          ? results
          : results
              .where((r) => r.studyPlan?.semasterId == selectedSemesterId.value)
              .toList();

  /// Switch the semester filter and rebuild the per-subject groups.
  void selectSemester(int semesterId) {
    selectedSemesterId.value = semesterId;
    _buildSubjectGroups();
  }

  void _buildSubjectGroups() {
    final spMap = _spMap;
    // Build a fast lookup so question text never depends on the preloaded
    // relation (which may be absent from the API response).
    final Map<int, String> questionTextMap = {
      for (final q in questions) q.evaQuestionId: q.question.trim(),
    };

    // Also pull question text from each result's preloaded evaQuestion
    // relation — covers inactive/deleted questions not in the questions list.
    for (final r in results) {
      final eq = r.evaQuestion;
      if (eq != null && eq.question.trim().isNotEmpty && !questionTextMap.containsKey(eq.evaQuestionId)) {
        questionTextMap[eq.evaQuestionId] = eq.question.trim();
      }
    }

    final Map<int, SubjectEvalGroup> groups = {};

    for (final r in _filteredResults) {
      final spId = r.studyPlanId;
      final sp = spMap[spId];
      if (sp == null) continue;

      groups.putIfAbsent(
        spId,
        () => SubjectEvalGroup(
          studyPlanId: spId,
          subjectName: sp.subject?.nameLao ?? 'ບໍ່ລະບຸ',
          subjectCode: sp.subject?.subjectCode ?? '',
          semesterLabel: sp.semaster != null
              ? 'ປີ ${sp.semaster!.year} ເທີມ ${sp.semaster!.term}'
              : '',
          semesterId: sp.semasterId,
          studentGroupName: sp.studentGroup?.stdGroupName ?? '',
          totalResponses: 0,
          totalScore: 0,
          questionScores: {},
          comments: [],
        ),
      );

      final g = groups[spId]!;
      g.totalResponses++;
      g.totalScore += (r.score ?? 0);

      final qId = r.evaQuestionId;
      g.questionScores.putIfAbsent(
        qId,
        () => QScore(
          questionText: questionTextMap[qId] ?? '-',
          totalScore: 0,
          count: 0,
        ),
      );
      g.questionScores[qId]!.totalScore += (r.score ?? 0);
      g.questionScores[qId]!.count++;

      if (r.comment != null && r.comment!.isNotEmpty) {
        g.comments.add(r.comment!);
      }
    }

    final list = groups.values.toList();
    list.sort((a, b) {
      final cmp = b.semesterId.compareTo(a.semesterId);
      if (cmp != 0) return cmp;
      return a.subjectName.compareTo(b.subjectName);
    });

    subjectGroups.assignAll(list);
  }

  // Overall average — respects the semester filter so the header stats match
  // the term the teacher is looking at.
  double get overallAverage {
    final rows = _filteredResults;
    if (rows.isEmpty) return 0;
    final total = rows.fold<int>(0, (sum, r) => sum + (r.score ?? 0));
    return total / rows.length;
  }

  /// Number of distinct students who submitted an evaluation.
  /// Each student submits one row per question, so we divide total rows by
  /// the number of distinct questions that appear in the results.
  int get totalEvaluations => subjectGroups.fold<int>(0, (s, g) => s + g.numRespondents);

  int get totalSubjects => subjectGroups.length;

  /// Sum + count of scores per semesterId, ordered by id descending so the
  /// most recent semester comes first. Only semesters with ≥1 response are
  /// included.
  List<({int semesterId, double average, int count})>
      get _semesterAverages {
    final acc = <int, ({int sum, int count})>{};
    for (final r in results) {
      final semId = r.studyPlan?.semasterId;
      if (semId == null) continue;
      final entry = acc[semId] ?? (sum: 0, count: 0);
      acc[semId] =
          (sum: entry.sum + (r.score ?? 0), count: entry.count + 1);
    }
    final list = acc.entries
        .map((e) => (
              semesterId: e.key,
              average: e.value.count > 0 ? e.value.sum / e.value.count : 0.0,
              count: e.value.count,
            ))
        .toList();
    list.sort((a, b) => b.semesterId.compareTo(a.semesterId));
    return list;
  }

  /// Average score for the most recent semester with data.
  double? get currentSemesterAverage {
    final list = _semesterAverages;
    return list.isEmpty ? null : list.first.average;
  }

  /// Average score for the previous semester with data, or null when there
  /// is no prior semester to compare against.
  double? get previousSemesterAverage {
    final list = _semesterAverages;
    return list.length < 2 ? null : list[1].average;
  }

  /// Signed difference current − previous; null when there is no prior
  /// semester to compare.
  double? get semesterTrendDelta {
    final cur = currentSemesterAverage;
    final prev = previousSemesterAverage;
    if (cur == null || prev == null) return null;
    return cur - prev;
  }

  Future<void> refreshData() => _loadData();
}

// Helper models
class SubjectEvalGroup {
  final int studyPlanId;
  final String subjectName;
  final String subjectCode;
  final String semesterLabel;
  final int semesterId;
  final String studentGroupName;
  int totalResponses;
  int totalScore;
  final Map<int, QScore> questionScores;
  final List<String> comments;

  SubjectEvalGroup({
    required this.studyPlanId,
    required this.subjectName,
    required this.subjectCode,
    required this.semesterLabel,
    required this.semesterId,
    required this.studentGroupName,
    required this.totalResponses,
    required this.totalScore,
    required this.questionScores,
    required this.comments,
  });

  double get averageScore =>
      totalResponses > 0 ? totalScore / totalResponses : 0;

  /// Number of students who responded.
  /// Each student submits exactly one row per question, so:
  /// respondents = totalResponses ÷ distinct questions answered.
  int get numRespondents {
    final uniqueQ = questionScores.length;
    return uniqueQ > 0 ? totalResponses ~/ uniqueQ : 0;
  }
}

class QScore {
  final String questionText;
  int totalScore;
  int count;
  QScore({required this.questionText, required this.totalScore, required this.count});
  double get average => count > 0 ? totalScore / count : 0;
}
