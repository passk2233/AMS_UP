import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../../services/api_client.dart';

class TeacherEvaluationController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<EvaluationResultModel> results = <EvaluationResultModel>[].obs;
  final RxList<SubjectEvalGroup> subjectGroups = <SubjectEvalGroup>[].obs;
  final RxList<EvaluationQuestionModel> questions = <EvaluationQuestionModel>[].obs;

  // Current teacher info
  final Rx<TeacherModel?> currentTeacher = Rx<TeacherModel?>(null);
  int? _currentTeacherId;

  Dio get _dio => ApiClient.dio;

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
      final meResp = await _dio.get('/auth/me');
      if (meResp.statusCode == 200 && meResp.data is Map<String, dynamic>) {
        final user = UserModel.fromJson(meResp.data);
        _currentTeacherId = user.teacherId;
      }

      if (_currentTeacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      // 2. Fetch teacher info
      final teacherResp = await _dio.get('/teachers/$_currentTeacherId');
      if (teacherResp.statusCode == 200) {
        currentTeacher.value = TeacherModel.fromJson(
          teacherResp.data is Map && teacherResp.data['data'] != null
              ? teacherResp.data['data']
              : teacherResp.data,
        );
      }

      // 3. Fetch study plans for this teacher (with preloads)
      final spResp = await _dio.get('/study-plans', queryParameters: {
        'teacher_id': _currentTeacherId,
        'limit': 200,
      });
      final Map<int, StudyPlanModel> spMap = {};
      if (spResp.statusCode == 200) {
        final data = spResp.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        for (final j in items) {
          final sp = StudyPlanModel.fromJson(j);
          spMap[sp.id] = sp;
        }
      }

      // 4. Fetch evaluation results — server filters by teacher_id so the
      //    response only contains evaluations of THIS teacher (and, by
      //    contract, with student_id stripped). The client-side spMap
      //    intersect below is belt-and-braces in case the backend ignores
      //    the filter.
      final evalResp = await _dio.get('/evaluation-results', queryParameters: {
        'teacher_id': _currentTeacherId,
        'limit': 500,
      });
      if (evalResp.statusCode == 200) {
        final data = evalResp.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        final allResults =
            items.map((j) => EvaluationResultModel.fromJson(j)).toList();

        // Only keep results for this teacher's study plans — last line of
        // defence if the backend hasn't applied teacher_id.
        final myResults = allResults.where((r) {
          return spMap.containsKey(r.studyPlanId);
        }).toList();

        // Enrich with study plan data
        for (final r in myResults) {
          final sp = spMap[r.studyPlanId];
          if (sp != null) r.studyPlan = sp;
        }

        results.assignAll(myResults);
      }

      // 5. Fetch questions
      final qResp = await _dio.get('/evaluation-questions');
      if (qResp.statusCode == 200) {
        final data = qResp.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        questions.assignAll(
          items.map((j) => EvaluationQuestionModel.fromJson(j)).toList(),
        );
      }

      _buildSubjectGroups(spMap);
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

  void _buildSubjectGroups(Map<int, StudyPlanModel> spMap) {
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

    for (final r in results) {
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
          questionText: questionTextMap[qId] ?? 'ຄຳຖາມ #$qId',
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

  // Overall average
  double get overallAverage {
    if (results.isEmpty) return 0;
    final total = results.fold<int>(0, (sum, r) => sum + (r.score ?? 0));
    return total / results.length;
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
