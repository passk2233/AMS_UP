import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class EvalutionController extends GetxController {
  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE MODE: 0 = Questions, 1 = Results (teacher list), 2 = Teacher Detail
  // ═══════════════════════════════════════════════════════════════════════════
  final RxInt pageMode = 0.obs;

  // ═══════════════════════════════════════════════════════════════════════════
  // QUESTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  final RxList<EvaluationQuestionModel> questions =
      <EvaluationQuestionModel>[].obs;
  final RxBool isLoadingQuestions = false.obs;
  final RxString questionsError = ''.obs;

  // Form controllers for add/edit
  final questionTextCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final RxBool isSaving = false.obs;

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS
  // ═══════════════════════════════════════════════════════════════════════════
  final RxList<EvaluationResultModel> results =
      <EvaluationResultModel>[].obs;
  final RxBool isLoadingResults = false.obs;
  final RxString resultsError = ''.obs;

  // Teachers list for the results view
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final RxString teacherSearch = ''.obs;
  final teacherSearchCtrl = TextEditingController();

  // Computed: per-teacher summary
  final RxList<TeacherEvalSummary> teacherSummaries =
      <TeacherEvalSummary>[].obs;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEACHER DETAIL PAGE STATE
  // ═══════════════════════════════════════════════════════════════════════════
  final Rx<TeacherEvalSummary?> selectedTeacherSummary =
      Rx<TeacherEvalSummary?>(null);
  final RxList<SubjectEvalSummary> selectedTeacherSubjects =
      <SubjectEvalSummary>[].obs;

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_URL'] ?? '',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    },
  ));

  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _loadToken().then((_) async {
      fetchQuestions();
      await fetchTeachers();
      fetchResults();
    });
  }

  @override
  void onClose() {
    questionTextCtrl.dispose();
    categoryCtrl.dispose();
    teacherSearchCtrl.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIO
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH QUESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> fetchQuestions() async {
    isLoadingQuestions.value = true;
    questionsError.value = '';
    try {
      final response = await _dio.get('/evaluation-questions',
          queryParameters: {'limit': 200});

      if (response.statusCode == 200) {
        final data = response.data;
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
    } on DioException catch (e) {
      questionsError.value = 'ບໍ່ສາມາດໂຫຼດຄຳຖາມໄດ້';
      debugPrint('fetchQuestions error: ${e.message}');
    } finally {
      isLoadingQuestions.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD QUESTION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> addQuestion() async {
    questionTextCtrl.clear();
    categoryCtrl.clear();

    final confirmed = await _showQuestionDialog(isEdit: false);
    if (confirmed != true) return;

    final text = questionTextCtrl.text.trim();
    if (text.isEmpty) {
      AppDialogs.showWarning(
        title: 'ກະລຸນາໃສ່ຄຳຖາມ',
        message: 'ຄຳຖາມບໍ່ສາມາດເປົ່າວ່າງໄດ້.',
      );
      return;
    }

    isSaving.value = true;
    try {
      final response = await _dio.post('/evaluation-questions', data: {
        'question': text,
        'category': categoryCtrl.text.trim().isEmpty
            ? null
            : categoryCtrl.text.trim(),
        'is_active': 1,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchQuestions();
        AppDialogs.showSuccess(
          title: 'ເພີ່ມສຳເລັດ',
          message: 'ຄຳຖາມໄດ້ຖືກເພີ່ມແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ເພີ່ມຄຳຖາມລົ້ມເຫຼວ', e);
    } finally {
      isSaving.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT QUESTION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> editQuestion(EvaluationQuestionModel q) async {
    questionTextCtrl.text = q.question;
    categoryCtrl.text = q.category ?? '';

    final confirmed = await _showQuestionDialog(isEdit: true);
    if (confirmed != true) return;

    final text = questionTextCtrl.text.trim();
    if (text.isEmpty) return;

    isSaving.value = true;
    try {
      final response = await _dio.put(
        '/evaluation-questions/${q.evaQuestionId}',
        data: {
          'question': text,
          'category': categoryCtrl.text.trim().isEmpty
              ? null
              : categoryCtrl.text.trim(),
          'is_active': q.isActive,
        },
      );

      if (response.statusCode == 200) {
        await fetchQuestions();
        AppDialogs.showSuccess(
          title: 'ແກ້ໄຂສຳເລັດ',
          message: 'ຄຳຖາມໄດ້ຖືກອັບເດດແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ແກ້ໄຂຄຳຖາມລົ້ມເຫຼວ', e);
    } finally {
      isSaving.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOGGLE QUESTION ACTIVE/INACTIVE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> toggleQuestionActive(EvaluationQuestionModel q) async {
    final newStatus = q.isActive == 1 ? 0 : 1;
    final statusLabel = newStatus == 1 ? 'ເປີດໃຊ້ງານ' : 'ປິດໃຊ້ງານ';

    final confirmed = await AppDialogs.showConfirmation(
      title: '$statusLabel ຄຳຖາມ',
      message: 'ຕ້ອງການ $statusLabel ຄຳຖາມນີ້ແທ້ບໍ?',
      confirmText: statusLabel,
      cancelText: 'ຍົກເລີກ',
      confirmColor:
          newStatus == 1 ? const Color(0xFF10B981) : const Color(0xFFE53935),
    );
    if (confirmed != true) return;

    try {
      final response = await _dio.put(
        '/evaluation-questions/${q.evaQuestionId}',
        data: {
          'question': q.question,
          'category': q.category,
          'is_active': newStatus,
        },
      );

      if (response.statusCode == 200) {
        final index =
            questions.indexWhere((x) => x.evaQuestionId == q.evaQuestionId);
        if (index != -1) {
          questions[index].isActive = newStatus;
          questions.refresh();
        }
      }
    } on DioException catch (e) {
      _showDioError('ອັບເດດສະຖານະລົ້ມເຫຼວ', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE QUESTION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> deleteQuestion(int questionId) async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ລຶບຄຳຖາມ',
      message: 'ທ່ານຕ້ອງການລຶບຄຳຖາມນີ້ແທ້ບໍ?\nການກະທຳນີ້ບໍ່ສາມາດຍ້ອນກັບໄດ້.',
      confirmText: 'ລຶບ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: const Color(0xFFE53935),
    );
    if (confirmed != true) return;

    try {
      await _dio.delete('/evaluation-questions/$questionId');
      questions.removeWhere((q) => q.evaQuestionId == questionId);
      AppDialogs.showSuccess(
        title: 'ລຶບສຳເລັດ',
        message: 'ຄຳຖາມໄດ້ຖືກລຶບແລ້ວ.',
      );
    } on DioException catch (e) {
      _showDioError('ລຶບຄຳຖາມລົ້ມເຫຼວ', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH TEACHERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> fetchTeachers() async {
    try {
      final response =
          await _dio.get('/teachers', queryParameters: {'limit': 200});

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        teachers.assignAll(
          items.map((j) => TeacherModel.fromJson(j)).toList(),
        );
      }
    } on DioException catch (e) {
      debugPrint('fetchTeachers error: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH STUDY PLANS (has full preloads: Teacher, Subject, Semaster, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  final Map<int, StudyPlanModel> _studyPlanMap = {};

  Future<void> _fetchStudyPlans() async {
    try {
      final response =
          await _dio.get('/study-plans', queryParameters: {'limit': 500});
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        _studyPlanMap.clear();
        for (final j in items) {
          final sp = StudyPlanModel.fromJson(j);
          _studyPlanMap[sp.id] = sp;
        }
      }
    } on DioException catch (e) {
      debugPrint('fetchStudyPlans error: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> fetchResults() async {
    isLoadingResults.value = true;
    resultsError.value = '';
    try {
      // Fetch study plans first (they have full preloads)
      await _fetchStudyPlans();

      final response = await _dio.get('/evaluation-results',
          queryParameters: {'limit': 500});

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        final parsed =
            items.map((j) => EvaluationResultModel.fromJson(j)).toList();

        // Enrich results with full study plan data
        for (final r in parsed) {
          final fullSp = _studyPlanMap[r.studyPlanId];
          if (fullSp != null) {
            r.studyPlan = fullSp;
          }
        }

        results.assignAll(parsed);
        _buildTeacherSummaries();
      }
    } on DioException catch (e) {
      resultsError.value = 'ບໍ່ສາມາດໂຫຼດຜົນການປະເມີນໄດ້';
      debugPrint('fetchResults error: ${e.message}');
    } finally {
      isLoadingResults.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD PER-TEACHER SUMMARIES
  // ═══════════════════════════════════════════════════════════════════════════

  void _buildTeacherSummaries() {
    // Build teacher lookup from the separately-fetched teachers list
    final Map<int, TeacherModel> teacherMap = {};
    for (final t in teachers) {
      teacherMap[t.id] = t;
    }

    final Map<int, TeacherEvalSummary> map = {};

    for (final r in results) {
      // Try multiple sources to find the teacher
      TeacherModel? teacher = r.studyPlan?.teacher;

      // Fallback 1: lookup teacher from study plan's teacherId
      if (teacher == null && r.studyPlan != null) {
        teacher = teacherMap[r.studyPlan!.teacherId];
      }

      // Fallback 2: lookup study plan from map, then get teacher
      if (teacher == null) {
        final sp = _studyPlanMap[r.studyPlanId];
        teacher = sp?.teacher ?? teacherMap[sp?.teacherId ?? 0];
        // Also enrich the result's studyPlan if we found one
        if (sp != null && r.studyPlan == null) {
          r.studyPlan = sp;
        }
      }

      if (teacher == null) continue;

      final tid = teacher.id;
      map.putIfAbsent(
        tid,
        () => TeacherEvalSummary(
          teacher: teacher!,
          totalResponses: 0,
          totalScore: 0,
          questionScores: {},
          subjectNames: {},
          results: [],
        ),
      );

      final summary = map[tid]!;
      summary.totalResponses++;
      summary.totalScore += (r.score ?? 0);
      summary.results.add(r);

      // Collect subject names
      final subjectName = r.studyPlan?.subject?.nameLao ?? '';
      if (subjectName.isNotEmpty) {
        summary.subjectNames.add(subjectName);
      }

      // Per-question breakdown
      final qId = r.evaQuestionId;
      summary.questionScores.putIfAbsent(
        qId,
        () => QuestionScore(
          questionText: r.evaQuestion?.question ?? 'ຄຳຖາມ #$qId',
          totalScore: 0,
          count: 0,
        ),
      );
      summary.questionScores[qId]!.totalScore += (r.score ?? 0);
      summary.questionScores[qId]!.count++;
    }

    final summaries = map.values.toList();
    summaries.sort((a, b) {
      final aAvg = a.totalResponses > 0 ? a.totalScore / a.totalResponses : 0;
      final bAvg = b.totalResponses > 0 ? b.totalScore / b.totalResponses : 0;
      return bAvg.compareTo(aAvg);
    });

    teacherSummaries.assignAll(summaries);
  }

  /// Filter teacher summaries by search query
  List<TeacherEvalSummary> get filteredSummaries {
    final q = teacherSearch.value.toLowerCase();
    if (q.isEmpty) return teacherSummaries;
    return teacherSummaries.where((s) {
      final name =
          '${s.teacher.nameLao} ${s.teacher.surnameLao}'.toLowerCase();
      final code = s.teacher.teacherCode.toLowerCase();
      final dept = s.teacher.department?.deptNameLao.toLowerCase() ?? '';
      return name.contains(q) || code.contains(q) || dept.contains(q);
    }).toList();
  }

  void onTeacherSearchChanged(String val) {
    teacherSearch.value = val;
  }

  void clearTeacherSearch() {
    teacherSearchCtrl.clear();
    teacherSearch.value = '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEACHER DETAIL NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  void openTeacherDetail(TeacherEvalSummary summary) {
    selectedTeacherSummary.value = summary;
    _buildSubjectSummaries(summary);
    pageMode.value = 2;
  }

  void closeTeacherDetail() {
    selectedTeacherSummary.value = null;
    selectedTeacherSubjects.clear();
    pageMode.value = 1;
  }

  /// Build per-subject evaluation summaries for the selected teacher.
  /// Groups results by (studyPlanId → subject + semester + studentGroup).
  /// Evaluator identity is kept anonymous.
  void _buildSubjectSummaries(TeacherEvalSummary teacherSummary) {
    // Group results by studyPlanId
    final Map<int, SubjectEvalSummary> subjectMap = {};

    for (final r in teacherSummary.results) {
      final sp = r.studyPlan;
      if (sp == null) continue;

      final spId = sp.id;
      subjectMap.putIfAbsent(
        spId,
        () => SubjectEvalSummary(
          studyPlanId: spId,
          subjectName: sp.subject?.nameLao ?? 'ບໍ່ລະບຸ',
          subjectCode: sp.subject?.subjectCode ?? '',
          semesterLabel: sp.semaster != null
              ? 'ປີ ${sp.semaster!.year} ເທີມ ${sp.semaster!.term}'
              : 'ບໍ່ລະບຸ',
          semesterId: sp.semasterId,
          studentGroupName: sp.studentGroup?.stdGroupName ?? '',
          totalResponses: 0,
          totalScore: 0,
          questionScores: {},
          evaluationDetails: [],
        ),
      );

      final subSummary = subjectMap[spId]!;
      subSummary.totalResponses++;
      subSummary.totalScore += (r.score ?? 0);

      // Per-question scores
      final qId = r.evaQuestionId;
      subSummary.questionScores.putIfAbsent(
        qId,
        () => QuestionScore(
          questionText: r.evaQuestion?.question ?? 'ຄຳຖາມ #$qId',
          totalScore: 0,
          count: 0,
        ),
      );
      subSummary.questionScores[qId]!.totalScore += (r.score ?? 0);
      subSummary.questionScores[qId]!.count++;

      // Anonymous evaluation detail (no student info exposed)
      subSummary.evaluationDetails.add(
        AnonymousEvalDetail(
          questionText: r.evaQuestion?.question ?? 'ຄຳຖາມ #$qId',
          score: r.score ?? 0,
          comment: r.comment,
          date: r.createAt,
        ),
      );
    }

    final subjects = subjectMap.values.toList();
    // Sort by semester descending, then subject name
    subjects.sort((a, b) {
      final cmp = b.semesterId.compareTo(a.semesterId);
      if (cmp != 0) return cmp;
      return a.subjectName.compareTo(b.subjectName);
    });

    selectedTeacherSubjects.assignAll(subjects);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUESTION DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool?> _showQuestionDialog({required bool isEdit}) {
    return Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'ແກ້ໄຂຄຳຖາມ' : 'ເພີ່ມຄຳຖາມໃໝ່',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ຄຳຖາມ *',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              TextField(
                controller: questionTextCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ພິມຄຳຖາມ...',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('ໝວດໝູ່ (ບໍ່ບັງຄັບ)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              TextField(
                controller: categoryCtrl,
                decoration: InputDecoration(
                  hintText: 'ເຊັ່ນ: ການສອນ, ການປະເມີນ...',
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ຍົກເລີກ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C4DDC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isEdit ? 'ບັນທຶກ' : 'ເພີ່ມ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showDioError(String title, DioException e) {
    String message = 'ມີບັນຫາເກີດຂຶ້ນ, ກະລຸນາລອງໃໝ່.';
    if (e.response?.data is Map<String, dynamic>) {
      message = e.response?.data['error'] ?? message;
    }
    final detail = AppDialogs.buildDioErrorDetail(e);
    AppDialogs.showError(title: title, message: message, detail: detail);
  }

  Future<void> refreshData() async {
    await Future.wait([
      fetchQuestions(),
      fetchResults(),
      fetchTeachers(),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER MODELS
// ═══════════════════════════════════════════════════════════════════════════

class TeacherEvalSummary {
  final TeacherModel teacher;
  int totalResponses;
  int totalScore;
  final Map<int, QuestionScore> questionScores;
  final Set<String> subjectNames;
  final List<EvaluationResultModel> results;

  TeacherEvalSummary({
    required this.teacher,
    required this.totalResponses,
    required this.totalScore,
    required this.questionScores,
    required this.subjectNames,
    required this.results,
  });

  double get averageScore =>
      totalResponses > 0 ? totalScore / totalResponses : 0;
}

class QuestionScore {
  final String questionText;
  int totalScore;
  int count;

  QuestionScore({
    required this.questionText,
    required this.totalScore,
    required this.count,
  });

  double get average => count > 0 ? totalScore / count : 0;
}

/// Per-subject evaluation summary for a teacher's detail page
class SubjectEvalSummary {
  final int studyPlanId;
  final String subjectName;
  final String subjectCode;
  final String semesterLabel;
  final int semesterId;
  final String studentGroupName;
  int totalResponses;
  int totalScore;
  final Map<int, QuestionScore> questionScores;
  final List<AnonymousEvalDetail> evaluationDetails;

  SubjectEvalSummary({
    required this.studyPlanId,
    required this.subjectName,
    required this.subjectCode,
    required this.semesterLabel,
    required this.semesterId,
    required this.studentGroupName,
    required this.totalResponses,
    required this.totalScore,
    required this.questionScores,
    required this.evaluationDetails,
  });

  double get averageScore =>
      totalResponses > 0 ? totalScore / totalResponses : 0;

  /// Count unique evaluators (by date grouping as proxy since identity is hidden)
  int get uniqueEvaluatorCount {
    final dates = evaluationDetails
        .where((d) => d.date != null)
        .map((d) => '${d.date!.year}-${d.date!.month}-${d.date!.day}')
        .toSet();
    return dates.isNotEmpty ? dates.length : totalResponses;
  }
}

/// Anonymized evaluation detail — no student info exposed
class AnonymousEvalDetail {
  final String questionText;
  final int score;
  final String? comment;
  final DateTime? date;

  AnonymousEvalDetail({
    required this.questionText,
    required this.score,
    this.comment,
    this.date,
  });
}
