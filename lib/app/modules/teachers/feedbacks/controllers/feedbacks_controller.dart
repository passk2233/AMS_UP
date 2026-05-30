import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/api_client.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// One non-empty student comment surfaced on the teacher's "Feedback" page.
class TeacherFeedbackItem {
  /// Subject name (Lao) the comment was left under.
  final String subjectName;

  /// Subject short code (`subjects.subject_code`).
  final String subjectCode;

  /// Display name of the student group.
  final String studentGroupName;

  /// Semester label, e.g. "ປີ 4 ເທີມ 1".
  final String semesterLabel;

  /// Verbatim comment text (already trimmed of whitespace).
  final String comment;

  /// The `eva_question_id` that this comment was submitted under.
  final int questionId;

  /// Full question text from `evaluation_questions.question`.
  /// Empty when the backend didn't preload the relation.
  final String questionText;

  TeacherFeedbackItem({
    required this.subjectName,
    required this.subjectCode,
    required this.studentGroupName,
    required this.semesterLabel,
    required this.comment,
    required this.questionId,
    required this.questionText,
  });
}

/// Reactive state owner for [FeedbacksView].
///
/// Flattens `/evaluation-results` rows that carry a non-empty `comment`
/// into [TeacherFeedbackItem]s, joining each row with its study plan so
/// the subject / group / semester labels can be rendered. Per the CLAUDE.md
/// privacy rule, no student identifier is fetched or displayed.
class FeedbacksController extends GetxController {
  /// `true` while [fetchFeedbacks] is in flight.
  final RxBool isLoading = false.obs;

  /// Last user-facing error from the load path; empty when none.
  final RxString errorMessage = ''.obs;

  /// Flattened, comment-only feedback entries for this teacher.
  final RxList<TeacherFeedbackItem> items = <TeacherFeedbackItem>[].obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchFeedbacks();
  }

  /// Refresh handler — bound to pull-to-refresh.
  Future<void> refreshData() => fetchFeedbacks();

  /// Fetch the teacher's evaluation results, filter to rows with a comment,
  /// and join each with its study plan for the subject/group/semester
  /// display strings.
  Future<void> fetchFeedbacks() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final teacherId = await _resolveTeacherId();
      if (teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      final studyPlans = await _loadTeacherStudyPlans(teacherId);
      final spMap = {for (final sp in studyPlans) sp.id: sp};

      // Fetch all questions up-front so we can look up question text by ID
      // without relying on the backend's nested preload, which may be absent.
      final qResp = await _dio.get('/evaluation-questions');
      final Map<int, EvaluationQuestionModel> questionsMap = {};
      for (final j in _extractList(qResp.data)) {
        final q = EvaluationQuestionModel.fromJson(j);
        questionsMap[q.evaQuestionId] = q;
      }

      items.assignAll(await _loadFeedbackItems(teacherId, spMap, questionsMap));
    } on DioException catch (e) {
      debugPrint(
        'Feedbacks Dio error:\n${AppDialogs.buildDioErrorDetail(e)}',
      );
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
          : 'ບໍ່ສາມາດໂຫຼດຄຳເຫັນໄດ້';
    } catch (e) {
      debugPrint('Feedbacks error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຄຳເຫັນໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<int?> _resolveTeacherId() async {
    final meResp = await _dio.get('/auth/me');
    if (meResp.statusCode != 200 || meResp.data is! Map<String, dynamic>) {
      return null;
    }
    return UserModel.fromJson(meResp.data).teacherId;
  }

  /// Server-side filter by `teacher_id`, falling back to client-side filter
  /// when the backend returns nothing.
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

  Future<List<TeacherFeedbackItem>> _loadFeedbackItems(
    int teacherId,
    Map<int, StudyPlanModel> spMap,
    Map<int, EvaluationQuestionModel> questionsMap,
  ) async {
    final response = await _dio.get(
      '/evaluation-results',
      queryParameters: {'teacher_id': teacherId, 'limit': 500},
    );
    final out = <TeacherFeedbackItem>[];
    for (final j in _extractList(response.data)) {
      final r = EvaluationResultModel.fromJson(j);
      final comment = (r.comment ?? '').trim();
      if (comment.isEmpty) continue;
      final sp = spMap[r.studyPlanId];
      if (sp == null) continue;

      // Resolve question text: prefer the dedicated questions map, fall back
      // to the preloaded relation on the result row (covers deleted/inactive Qs).
      final questionText =
          (questionsMap[r.evaQuestionId]?.question ?? r.evaQuestion?.question ?? '').trim();

      out.add(
        TeacherFeedbackItem(
          subjectName: sp.subject?.nameLao ?? 'ບໍ່ລະບຸວິຊາ',
          subjectCode: sp.subject?.subjectCode ?? '',
          studentGroupName: sp.studentGroup?.stdGroupName ?? '',
          semesterLabel: sp.semaster != null
              ? 'ປີ ${sp.semaster!.year} ເທີມ ${sp.semaster!.term}'
              : '',
          comment: comment,
          questionId: r.evaQuestionId,
          questionText: questionText,
        ),
      );
    }
    return out.reversed.toList();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
