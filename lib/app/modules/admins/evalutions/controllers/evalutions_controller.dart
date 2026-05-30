import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/api_client.dart';
import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// Page modes for the evaluations admin screen.
abstract class EvalutionPageMode {
  /// 0 — manage evaluation question bank.
  static const int questions = 0;

  /// 1 — list of teachers with aggregate evaluation results.
  static const int results = 1;

  /// 2 — drilled-in view of one teacher's per-subject breakdown.
  static const int teacherDetail = 2;

  /// 3 — admin-controlled evaluation window (open / close time).
  static const int window = 3;
}

/// Reactive state owner for the admin "Evaluations" tab.
///
/// Combines three sub-screens:
/// 1. Question bank CRUD ([EvalutionPageMode.questions]).
/// 2. Teacher results list with search ([EvalutionPageMode.results]).
/// 3. Teacher detail with per-subject + per-question breakdowns
///    ([EvalutionPageMode.teacherDetail]).
///
/// Detail-page aggregation is computed client-side by joining
/// `/evaluation-results` with `/study-plans` (which carry the preloads we
/// need: teacher, subject, semester, student group). Evaluator identity is
/// stripped before display per CLAUDE.md privacy rule.
class EvalutionController extends GetxController {
  /// Active page mode — see [EvalutionPageMode].
  final RxInt pageMode = EvalutionPageMode.questions.obs;

  // ───────────────────────────────────────────────────── questions ──

  /// Question bank from `/evaluation-questions`.
  final RxList<EvaluationQuestionModel> questions =
      <EvaluationQuestionModel>[].obs;

  /// `true` while the question fetch is in flight.
  final RxBool isLoadingQuestions = false.obs;

  /// Last user-facing error from the question fetch.
  final RxString questionsError = ''.obs;

  /// Add/edit dialog — question text field.
  final TextEditingController questionTextCtrl = TextEditingController();

  /// Add/edit dialog — category field.
  final TextEditingController categoryCtrl = TextEditingController();

  /// `true` while [addQuestion] / [editQuestion] are persisting.
  final RxBool isSaving = false.obs;

  // ─────────────────────────────────────────────────────── results ──

  /// Raw evaluation results from `/evaluation-results`, enriched with full
  /// study-plan data from [_studyPlanMap].
  final RxList<EvaluationResultModel> results = <EvaluationResultModel>[].obs;

  /// `true` while the results fetch is in flight.
  final RxBool isLoadingResults = false.obs;

  /// Last user-facing error from the results fetch.
  final RxString resultsError = ''.obs;

  /// Teachers list (used to resolve names when the result's study plan
  /// has no preloaded teacher relation).
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;

  /// Current search needle on the teacher list page.
  final RxString teacherSearch = ''.obs;

  /// Backing controller for the teacher search field.
  final TextEditingController teacherSearchCtrl = TextEditingController();

  /// Per-teacher aggregate summaries derived from [results] + [teachers].
  final RxList<TeacherEvalSummary> teacherSummaries =
      <TeacherEvalSummary>[].obs;

  // ───────────────────────────────────────────── evaluation window ──

  /// Evaluation window rows from `/open-evalu`. The row with the largest
  /// `id` is treated as the active gate.
  final RxList<OpenEvaluationModel> openWindows =
      <OpenEvaluationModel>[].obs;

  /// `true` while the window fetch is in flight.
  final RxBool isLoadingWindow = false.obs;

  /// `true` while [openEvaluation] / [closeEvaluation] are persisting.
  final RxBool isSavingWindow = false.obs;

  /// Last user-facing error from the window fetch.
  final RxString windowError = ''.obs;

  /// Form state — open datetime selected in the dialog.
  final Rx<DateTime?> formOpenTime = Rx<DateTime?>(null);

  /// Form state — close datetime selected in the dialog.
  final Rx<DateTime?> formCloseTime = Rx<DateTime?>(null);

  // ──────────────────────────────────────────────── teacher detail ──

  /// Selected row when [pageMode] = [EvalutionPageMode.teacherDetail].
  final Rx<TeacherEvalSummary?> selectedTeacherSummary =
      Rx<TeacherEvalSummary?>(null);

  /// Per-subject summaries computed for [selectedTeacherSummary].
  final RxList<SubjectEvalSummary> selectedTeacherSubjects =
      <SubjectEvalSummary>[].obs;

  Dio get _dio => ApiClient.dio;

  /// Cache of `study_plan.id → StudyPlanModel` with preloaded relations.
  final Map<int, StudyPlanModel> _studyPlanMap = {};

  @override
  void onInit() {
    super.onInit();
    fetchQuestions();
    fetchTeachers().then((_) => fetchResults());
    fetchOpenWindow();
  }

  @override
  void onClose() {
    questionTextCtrl.dispose();
    categoryCtrl.dispose();
    teacherSearchCtrl.dispose();
    super.onClose();
  }

  /// Refresh handler bound to the bottom-nav tab.
  Future<void> refreshData() async {
    await Future.wait([
      fetchQuestions(),
      fetchResults(),
      fetchTeachers(),
      fetchOpenWindow(),
    ]);
  }

  // ─────────────────────────────────────────────── question fetch ──

  /// GET `/evaluation-questions` and populate [questions].
  Future<void> fetchQuestions() async {
    isLoadingQuestions.value = true;
    questionsError.value = '';
    try {
      final response = await _dio.get(
        '/evaluation-questions',
        queryParameters: {'limit': 200},
      );
      if (response.statusCode != 200) return;
      questions.assignAll(
        _extractList(response.data)
            .map((j) => EvaluationQuestionModel.fromJson(j))
            .toList(),
      );
    } on DioException catch (e) {
      questionsError.value = 'ບໍ່ສາມາດໂຫຼດຄຳຖາມໄດ້';
      debugPrint('fetchQuestions error: ${e.message}');
    } finally {
      isLoadingQuestions.value = false;
    }
  }

  // ─────────────────────────────────────────────── question writes ──

  /// Open the [_QuestionDialog] in add mode and POST the captured fields on
  /// confirm. Empty question text aborts with a warning.
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
        'category': _orNull(categoryCtrl.text.trim()),
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

  /// Open the [_QuestionDialog] pre-filled with [q] and PUT the changes on
  /// confirm.
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
          'category': _orNull(categoryCtrl.text.trim()),
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

  /// Flip the question's `is_active` flag after a confirmation dialog.
  Future<void> toggleQuestionActive(EvaluationQuestionModel q) async {
    final newStatus = q.isActive == 1 ? 0 : 1;
    final statusLabel = newStatus == 1 ? 'ເປີດໃຊ້ງານ' : 'ປິດໃຊ້ງານ';

    final confirmed = await AppDialogs.showConfirmation(
      title: '$statusLabel ຄຳຖາມ',
      message: 'ຕ້ອງການ $statusLabel ຄຳຖາມນີ້ແທ້ບໍ?',
      confirmText: statusLabel,
      cancelText: 'ຍົກເລີກ',
      confirmColor:
          newStatus == 1 ? AppColors.borderApproved : AppColors.rejectRed,
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
      if (response.statusCode != 200) return;
      final index =
          questions.indexWhere((x) => x.evaQuestionId == q.evaQuestionId);
      if (index != -1) {
        questions[index].isActive = newStatus;
        questions.refresh();
      }
    } on DioException catch (e) {
      _showDioError('ອັບເດດສະຖານະລົ້ມເຫຼວ', e);
    }
  }

  /// Permanently delete a question after a confirmation dialog.
  Future<void> deleteQuestion(int questionId) async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ລຶບຄຳຖາມ',
      message: 'ທ່ານຕ້ອງການລຶບຄຳຖາມນີ້ແທ້ບໍ?\nການກະທຳນີ້ບໍ່ສາມາດຍ້ອນກັບໄດ້.',
      confirmText: 'ລຶບ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: AppColors.rejectRed,
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

  // ─────────────────────────────────────────── evaluation window ──

  /// GET `/open-evalu` and populate [openWindows]. The list is sorted
  /// newest-first server-side; the head is treated as the active gate.
  Future<void> fetchOpenWindow() async {
    isLoadingWindow.value = true;
    windowError.value = '';
    try {
      final response = await _dio.get(
        '/open-evalu',
        queryParameters: {'limit': 20},
      );
      if (response.statusCode != 200) return;
      openWindows.assignAll(
        _extractList(response.data)
            .map((j) => OpenEvaluationModel.fromJson(j))
            .toList(),
      );
    } on DioException catch (e) {
      windowError.value = 'ບໍ່ສາມາດໂຫຼດໄລຍະເວລາການປະເມີນໄດ້';
      debugPrint('fetchOpenWindow error: ${e.message}');
    } finally {
      isLoadingWindow.value = false;
    }
  }

  /// The current evaluation window — the highest-id row in [openWindows],
  /// or `null` when no row exists yet.
  OpenEvaluationModel? get currentWindow =>
      openWindows.isEmpty ? null : openWindows.first;

  /// `true` when the active window is open right now — the student
  /// evaluation page should be visible.
  bool get isEvaluationOpen => currentWindow?.isOpenNow ?? false;

  /// Pre-fill the dialog form with current window values (when editing) or
  /// sensible defaults (when opening for the first time).
  void prepareWindowForm() {
    final current = currentWindow;
    if (current != null && current.isOpenNow) {
      formOpenTime.value = current.openTime;
      formCloseTime.value = current.closeTime;
    } else {
      final now = DateTime.now();
      formOpenTime.value = DateTime(now.year, now.month, now.day, 8, 0);
      formCloseTime.value = formOpenTime.value!.add(const Duration(days: 14));
    }
  }

  /// Open (or extend) the evaluation window with the dialog form's values.
  /// On success this also dispatches an in-app + push notification to
  /// every student so they know to head to the evaluation page.
  Future<void> openEvaluation() async {
    final openAt = formOpenTime.value;
    final closeAt = formCloseTime.value;
    if (openAt == null || closeAt == null) {
      AppDialogs.showWarning(
        title: 'ກະລຸນາເລືອກເວລາ',
        message: 'ກະລຸນາເລືອກເວລາເປີດ ແລະ ເວລາປິດການປະເມີນ.',
      );
      return;
    }
    if (!closeAt.isAfter(openAt)) {
      AppDialogs.showWarning(
        title: 'ເວລາບໍ່ຖືກຕ້ອງ',
        message: 'ເວລາປິດຕ້ອງຊ້າກວ່າເວລາເປີດ.',
      );
      return;
    }

    isSavingWindow.value = true;
    try {
      final fallbackPlanId = await _firstStudyPlanId();
      final response = await _dio.post('/open-evalu', data: {
        'study_plan_id': fallbackPlanId,
        'open_time': openAt.toUtc().toIso8601String(),
        'close_time': closeAt.toUtc().toIso8601String(),
        'inactive': 0,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOpenWindow();
        await _broadcastEvaluationOpened(openAt, closeAt);
        AppDialogs.showSuccess(
          title: 'ເປີດການປະເມີນສຳເລັດ',
          message:
              'ນັກສຶກສາສາມາດເຂົ້າປະເມີນອາຈານໄດ້ແລ້ວ ແລະ ການແຈ້ງເຕືອນຖືກສົ່ງອອກ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ເປີດການປະເມີນລົ້ມເຫຼວ', e);
    } finally {
      isSavingWindow.value = false;
    }
  }

  /// Close the current window by flipping `inactive` to 1 (or DELETEing
  /// when the route lacks PUT). Hides the student evaluation page.
  Future<void> closeEvaluation() async {
    final current = currentWindow;
    if (current == null) {
      AppDialogs.showWarning(
        title: 'ຍັງບໍ່ມີໄລຍະເວລາ',
        message: 'ຍັງບໍ່ມີໄລຍະການປະເມີນທີ່ເປີດໃຊ້ງານຢູ່.',
      );
      return;
    }

    final confirmed = await AppDialogs.showConfirmation(
      title: 'ປິດການປະເມີນ',
      message: 'ທ່ານຕ້ອງການປິດໄລຍະການປະເມີນປະຈຸບັນແທ້ບໍ?',
      confirmText: 'ປິດ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: AppColors.rejectRed,
    );
    if (confirmed != true) return;

    isSavingWindow.value = true;
    try {
      final response = await _dio.put(
        '/open-evalu/${current.id}',
        data: {
          'study_plan_id': current.studyPlanId,
          'open_time': current.openTime?.toUtc().toIso8601String(),
          'close_time': DateTime.now().toUtc().toIso8601String(),
          'inactive': 1,
        },
      );
      if (response.statusCode == 200) {
        await fetchOpenWindow();
        AppDialogs.showSuccess(
          title: 'ປິດສຳເລັດ',
          message: 'ໄລຍະການປະເມີນຖືກປິດແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ປິດການປະເມີນລົ້ມເຫຼວ', e);
    } finally {
      isSavingWindow.value = false;
    }
  }

  /// Pluck the lowest valid `study_plan.id` to use as a sentinel for the
  /// global window row. Needed because the live `open_evalu` schema still
  /// enforces `NOT NULL` + FK on `study_plan_id`; until the migration to
  /// nullable runs, we satisfy the FK by attaching the window to any real
  /// study plan. Student-side logic ignores which plan it points to.
  Future<int?> _firstStudyPlanId() async {
    try {
      final response = await _dio.get(
        '/study-plans',
        queryParameters: {'limit': 1},
      );
      if (response.statusCode != 200) return null;
      final items = _extractList(response.data);
      if (items.isEmpty) return null;
      return (items.first as Map<String, dynamic>)['id'] as int?;
    } on DioException catch (e) {
      debugPrint('firstStudyPlanId error: ${e.message}');
      return null;
    }
  }

  /// Post an announcement to every student so they know the evaluation
  /// page is now open. Failure here is non-fatal: the window row was
  /// already created, students just won't get the push.
  Future<void> _broadcastEvaluationOpened(
    DateTime openAt,
    DateTime closeAt,
  ) async {
    final openLabel = _formatDateTime(openAt);
    final closeLabel = _formatDateTime(closeAt);
    try {
      await _dio.post(
        '/notifications',
        queryParameters: {'audience': 'students'},
        data: {
          'title': 'ເປີດການປະເມີນອາຈານ',
          'message':
              'ໄລຍະການປະເມີນອາຈານໄດ້ເປີດແລ້ວ. ກະລຸນາເຂົ້າປະເມີນລະຫວ່າງ '
                  '$openLabel ຫາ $closeLabel.',
          'type': 'evaluation_open',
        },
      );
    } on DioException catch (e) {
      debugPrint('evaluation announce error: ${e.message}');
    }
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  // ──────────────────────────────────────────────── result fetches ──

  /// GET `/teachers` and populate [teachers].
  Future<void> fetchTeachers() async {
    try {
      final response = await _dio.get(
        '/teachers',
        queryParameters: {'limit': 200},
      );
      if (response.statusCode != 200) return;
      teachers.assignAll(
        _extractList(response.data)
            .map((j) => TeacherModel.fromJson(j))
            .toList(),
      );
    } on DioException catch (e) {
      debugPrint('fetchTeachers error: ${e.message}');
    }
  }

  /// GET `/evaluation-results` (after `/study-plans` for preload joins) and
  /// rebuild [teacherSummaries].
  Future<void> fetchResults() async {
    isLoadingResults.value = true;
    resultsError.value = '';
    try {
      await _fetchStudyPlans();

      final response = await _dio.get(
        '/evaluation-results',
        queryParameters: {'limit': 500},
      );
      if (response.statusCode != 200) return;

      final parsed = _extractList(response.data)
          .map((j) => EvaluationResultModel.fromJson(j))
          .toList();
      for (final r in parsed) {
        final fullSp = _studyPlanMap[r.studyPlanId];
        if (fullSp != null) r.studyPlan = fullSp;
      }
      results.assignAll(parsed);
      _buildTeacherSummaries();
    } on DioException catch (e) {
      resultsError.value = 'ບໍ່ສາມາດໂຫຼດຜົນການປະເມີນໄດ້';
      debugPrint('fetchResults error: ${e.message}');
    } finally {
      isLoadingResults.value = false;
    }
  }

  Future<void> _fetchStudyPlans() async {
    try {
      final response = await _dio.get(
        '/study-plans',
        queryParameters: {'limit': 500},
      );
      if (response.statusCode != 200) return;

      _studyPlanMap.clear();
      for (final j in _extractList(response.data)) {
        final sp = StudyPlanModel.fromJson(j);
        _studyPlanMap[sp.id] = sp;
      }
    } on DioException catch (e) {
      debugPrint('fetchStudyPlans error: ${e.message}');
    }
  }

  // ──────────────────────────────────────── summary aggregations ──

  /// Group [results] by teacher and aggregate counts + per-question scores.
  /// Falls back to the [teachers] map for results whose study plan has no
  /// preloaded teacher.
  void _buildTeacherSummaries() {
    final teacherMap = {for (final t in teachers) t.id: t};
    final summaries = <int, TeacherEvalSummary>{};

    for (final r in results) {
      final teacher = _resolveTeacher(r, teacherMap);
      if (teacher == null) continue;

      final summary = summaries.putIfAbsent(
        teacher.id,
        () => TeacherEvalSummary(
          teacher: teacher,
          totalResponses: 0,
          totalScore: 0,
          questionScores: {},
          subjectNames: {},
          results: [],
        ),
      );
      summary.totalResponses++;
      summary.totalScore += r.score ?? 0;
      summary.results.add(r);

      final subjectName = r.studyPlan?.subject?.nameLao ?? '';
      if (subjectName.isNotEmpty) summary.subjectNames.add(subjectName);

      _bumpQuestionScore(summary.questionScores, r);
    }

    final list = summaries.values.toList()
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
    teacherSummaries.assignAll(list);
  }

  TeacherModel? _resolveTeacher(
    EvaluationResultModel r,
    Map<int, TeacherModel> teacherMap,
  ) {
    final fromPlan = r.studyPlan?.teacher;
    if (fromPlan != null) return fromPlan;

    if (r.studyPlan != null) {
      final byId = teacherMap[r.studyPlan!.teacherId];
      if (byId != null) return byId;
    }

    final sp = _studyPlanMap[r.studyPlanId];
    if (sp != null && r.studyPlan == null) r.studyPlan = sp;
    return sp?.teacher ?? teacherMap[sp?.teacherId ?? 0];
  }

  /// Group one [TeacherEvalSummary]'s results by study plan to build the
  /// detail page's per-subject breakdown.
  void _buildSubjectSummaries(TeacherEvalSummary teacherSummary) {
    final subjectMap = <int, SubjectEvalSummary>{};

    for (final r in teacherSummary.results) {
      final sp = r.studyPlan;
      if (sp == null) continue;

      final subSummary = subjectMap.putIfAbsent(
        sp.id,
        () => SubjectEvalSummary(
          studyPlanId: sp.id,
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
      subSummary.totalResponses++;
      subSummary.totalScore += r.score ?? 0;
      _bumpQuestionScore(subSummary.questionScores, r);
      subSummary.evaluationDetails.add(
        AnonymousEvalDetail(
          questionText: _resolveQuestionText(r),
          score: r.score ?? 0,
          comment: r.comment,
          date: r.createAt,
        ),
      );
    }

    final subjects = subjectMap.values.toList()
      ..sort((a, b) {
        final cmp = b.semesterId.compareTo(a.semesterId);
        if (cmp != 0) return cmp;
        return a.subjectName.compareTo(b.subjectName);
      });
    selectedTeacherSubjects.assignAll(subjects);
  }

  void _bumpQuestionScore(
    Map<int, QuestionScore> scores,
    EvaluationResultModel r,
  ) {
    final qId = r.evaQuestionId;
    final qs = scores.putIfAbsent(
      qId,
      () => QuestionScore(
        questionText: _resolveQuestionText(r),
        totalScore: 0,
        count: 0,
      ),
    );
    qs.totalScore += r.score ?? 0;
    qs.count++;
  }

  /// Resolve the question text for [r]: prefer the fetched questions list,
  /// then the preloaded relation, then a generic ordinal fallback.
  String _resolveQuestionText(EvaluationResultModel r) {
    final qId = r.evaQuestionId;
    // 1. Try the separately-fetched questions list (includes all questions).
    final fromList = questions.cast<EvaluationQuestionModel?>().firstWhere(
      (q) => q!.evaQuestionId == qId,
      orElse: () => null,
    );
    if (fromList != null && fromList.question.trim().isNotEmpty) {
      return fromList.question.trim();
    }
    // 2. Try the preloaded relation on the result row.
    final fromRelation = r.evaQuestion?.question;
    if (fromRelation != null && fromRelation.trim().isNotEmpty) {
      return fromRelation.trim();
    }
    // 3. Ordinal fallback.
    return 'ຄຳຖາມທີ $qId';
  }

  // ───────────────────────────────────────────── search + nav ──

  /// Filter teacher summaries by [teacherSearch].
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

  /// Bound to the teacher-search field.
  void onTeacherSearchChanged(String val) => teacherSearch.value = val;

  /// Clear the teacher search field and reset the filter.
  void clearTeacherSearch() {
    teacherSearchCtrl.clear();
    teacherSearch.value = '';
  }

  /// Drill into the per-teacher detail view.
  void openTeacherDetail(TeacherEvalSummary summary) {
    selectedTeacherSummary.value = summary;
    _buildSubjectSummaries(summary);
    pageMode.value = EvalutionPageMode.teacherDetail;
  }

  /// Return from the detail view to the teacher list.
  void closeTeacherDetail() {
    selectedTeacherSummary.value = null;
    selectedTeacherSubjects.clear();
    pageMode.value = EvalutionPageMode.results;
  }

  // ─────────────────────────────────────────────── ui + helpers ──

  Future<bool?> _showQuestionDialog({required bool isEdit}) {
    return Get.dialog<bool>(
      _QuestionDialog(controller: this, isEdit: isEdit),
      barrierDismissible: false,
    );
  }

  void _showDioError(String title, DioException e) {
    var message = 'ມີບັນຫາເກີດຂຶ້ນ, ກະລຸນາລອງໃໝ່.';
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      message = data['error'].toString();
    }
    AppDialogs.showError(
      title: title,
      message: message,
      detail: AppDialogs.buildDioErrorDetail(e),
    );
  }

  /// `null` for empty/whitespace, otherwise the string unchanged. Used so
  /// optional fields go in as JSON null rather than empty strings.
  String? _orNull(String s) => s.isEmpty ? null : s;

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}

// ────────────────────────────────────────────────── view models ──

/// Aggregate evaluation summary for one teacher.
class TeacherEvalSummary {
  /// The teacher this summary is for.
  final TeacherModel teacher;

  /// Total number of evaluation rows attributed to this teacher.
  int totalResponses;

  /// Sum of every score across those rows.
  int totalScore;

  /// Per-question aggregates (key = `eva_question_id`).
  final Map<int, QuestionScore> questionScores;

  /// Distinct subject names this teacher has taught.
  final Set<String> subjectNames;

  /// Raw rows used to build this summary — needed for the detail page.
  final List<EvaluationResultModel> results;

  TeacherEvalSummary({
    required this.teacher,
    required this.totalResponses,
    required this.totalScore,
    required this.questionScores,
    required this.subjectNames,
    required this.results,
  });

  /// Average score (0..5 range) across [results]. Returns `0` if there are
  /// no responses.
  double get averageScore =>
      totalResponses > 0 ? totalScore / totalResponses : 0;
}

/// Per-question score aggregate used inside [TeacherEvalSummary] /
/// [SubjectEvalSummary].
class QuestionScore {
  /// Localized question text, resolved from the questions list or the
  /// isn't loaded.
  final String questionText;

  /// Sum of all submitted scores for this question.
  int totalScore;

  /// Number of submissions.
  int count;

  QuestionScore({
    required this.questionText,
    required this.totalScore,
    required this.count,
  });

  /// Average score for this question. Returns `0` when [count] is zero.
  double get average => count > 0 ? totalScore / count : 0;
}

/// Per-subject evaluation summary used on the teacher detail page.
class SubjectEvalSummary {
  /// Study-plan primary key (`study_plans.id`).
  final int studyPlanId;

  /// Subject name in Lao.
  final String subjectName;

  /// Subject short code.
  final String subjectCode;

  /// Human-readable semester label ("ປີ N ເທີມ M").
  final String semesterLabel;

  /// Semester primary key, used for sorting (newest first).
  final int semesterId;

  /// Student group display name.
  final String studentGroupName;

  /// Number of evaluation rows aggregated.
  int totalResponses;

  /// Sum of every score across those rows.
  int totalScore;

  /// Per-question aggregates keyed by `eva_question_id`.
  final Map<int, QuestionScore> questionScores;

  /// Anonymized rows used for the comments section.
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

  /// Average score across [evaluationDetails]. Returns `0` when there are
  /// no responses.
  double get averageScore =>
      totalResponses > 0 ? totalScore / totalResponses : 0;

  /// Approximation of how many distinct students rated this subject.
  ///
  /// Per the CLAUDE.md privacy rule we never join evaluator identity to the
  /// client; we instead group by submission date as a heuristic. Falls back
  /// to [totalResponses] when no rows carry a date.
  int get uniqueEvaluatorCount {
    final dates = evaluationDetails
        .where((d) => d.date != null)
        .map((d) => '${d.date!.year}-${d.date!.month}-${d.date!.day}')
        .toSet();
    return dates.isNotEmpty ? dates.length : totalResponses;
  }
}

/// One anonymized evaluation row (no student identity carried).
class AnonymousEvalDetail {
  /// Question text the score was given for.
  final String questionText;

  /// Submitted score (0..5).
  final int score;

  /// Optional free-form comment.
  final String? comment;

  /// Submission timestamp (used by [SubjectEvalSummary.uniqueEvaluatorCount]).
  final DateTime? date;

  AnonymousEvalDetail({
    required this.questionText,
    required this.score,
    this.comment,
    this.date,
  });
}

// ────────────────────────────────────────── question dialog ──

/// Add / edit question dialog. Reads its inputs from the controller's
/// [EvalutionController.questionTextCtrl] and [EvalutionController.categoryCtrl]
/// so the caller can act on the captured values when this dialog returns
/// `true`.
class _QuestionDialog extends StatelessWidget {
  /// Source of the text controllers.
  final EvalutionController controller;

  /// `true` shows "edit" copy, `false` shows "add" copy.
  final bool isEdit;

  const _QuestionDialog({required this.controller, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
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
            const _DialogLabel('ຄຳຖາມ *'),
            const SizedBox(height: 4),
            _DialogTextField(
              controller: controller.questionTextCtrl,
              hint: 'ພິມຄຳຖາມ...',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const _DialogLabel('ໝວດໝູ່ (ບໍ່ບັງຄັບ)'),
            const SizedBox(height: 4),
            _DialogTextField(
              controller: controller.categoryCtrl,
              hint: 'ເຊັ່ນ: ການສອນ, ການປະເມີນ...',
            ),
            const SizedBox(height: 18),
            _DialogFooter(confirmLabel: isEdit ? 'ບັນທຶກ' : 'ເພີ່ມ'),
          ],
        ),
      ),
    );
  }
}

/// Caption rendered above each field in [_QuestionDialog].
class _DialogLabel extends StatelessWidget {
  /// Caption text.
  final String text;

  const _DialogLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

/// Filled, rounded multi-line text field used inside [_QuestionDialog].
class _DialogTextField extends StatelessWidget {
  /// Backing controller.
  final TextEditingController controller;

  /// Placeholder.
  final String hint;

  /// Vertical line count.
  final int maxLines;

  const _DialogTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 10,
        ),
      ),
    );
  }
}

/// Cancel / confirm footer used by [_QuestionDialog].
class _DialogFooter extends StatelessWidget {
  /// Confirm button caption (changes between "add" and "save").
  final String confirmLabel;

  const _DialogFooter({required this.confirmLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(result: false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ຍົກເລີກ'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.laoBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
