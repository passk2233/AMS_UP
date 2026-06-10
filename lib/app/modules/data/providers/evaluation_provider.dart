import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for the teacher-evaluation feature: the question bank
/// (`/evaluation-questions`), submitted results (`/evaluation-results`), and
/// the admin-controlled open-evaluation window (`/open-evalu`).
///
/// Owns the endpoint paths, JSON-envelope unwrapping, and JSON → model
/// mapping. Methods throw [DioException] on failure; the calling controller
/// owns the user-facing error handling.
class EvaluationProvider {
  EvaluationProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/open-evalu` — the most recent active evaluation window, or `null`
  /// when none is open. Used to gate the student feedback flow.
  Future<OpenEvaluationModel?> fetchActiveWindow() async {
    final resp = await _dio.get(
      '/open-evalu',
      queryParameters: {'inactive': 0, 'limit': 1},
    );
    final items = _extractList(resp.data);
    if (items.isEmpty) return null;
    return OpenEvaluationModel.fromJson(items.first);
  }

  /// GET `/evaluation-results`, optionally scoped by [teacherId] /
  /// [studyPlanId] / [studentId]. Per the CLAUDE.md privacy rule the teacher
  /// views never pass [studentId]; only the student's own feedback flow does,
  /// to check whether they have already submitted.
  Future<List<EvaluationResultModel>> fetchResults({
    int? teacherId,
    int? studyPlanId,
    int? studentId,
    int limit = 500,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (teacherId != null) query['teacher_id'] = teacherId;
    if (studyPlanId != null) query['study_plan_id'] = studyPlanId;
    if (studentId != null) query['student_id'] = studentId;
    final resp = await _dio.get('/evaluation-results', queryParameters: query);
    return _extractList(resp.data)
        .map((j) => EvaluationResultModel.fromJson(j))
        .toList();
  }

  /// GET `/evaluation-questions`. [activeOnly] adds `?is_active=1` (the
  /// student-facing form; admins manage inactive questions too). [limit] caps
  /// the row count when provided.
  Future<List<EvaluationQuestionModel>> fetchQuestions({
    bool activeOnly = false,
    int? limit,
  }) async {
    final query = <String, dynamic>{};
    if (activeOnly) query['is_active'] = 1;
    if (limit != null) query['limit'] = limit;
    final resp = await _dio.get(
      '/evaluation-questions',
      queryParameters: query.isEmpty ? null : query,
    );
    return _extractList(resp.data)
        .map((j) => EvaluationQuestionModel.fromJson(j))
        .toList();
  }

  /// POST `/evaluation-questions`. Throws on failure.
  Future<void> createQuestion({
    required String question,
    String? category,
    int isActive = 1,
  }) async {
    await _dio.post('/evaluation-questions', data: {
      'question': question,
      'category': category,
      'is_active': isActive,
    });
  }

  /// PUT `/evaluation-questions/:id`. Throws on failure.
  Future<void> updateQuestion({
    required int id,
    required String question,
    String? category,
    required int isActive,
  }) async {
    await _dio.put('/evaluation-questions/$id', data: {
      'question': question,
      'category': category,
      'is_active': isActive,
    });
  }

  /// DELETE `/evaluation-questions/:id`. Throws on failure.
  Future<void> deleteQuestion(int id) async {
    await _dio.delete('/evaluation-questions/$id');
  }

  /// GET `/open-evalu` — evaluation windows (newest-first server-side).
  Future<List<OpenEvaluationModel>> fetchWindows({int limit = 20}) async {
    final resp =
        await _dio.get('/open-evalu', queryParameters: {'limit': limit});
    return _extractList(resp.data)
        .map((j) => OpenEvaluationModel.fromJson(j))
        .toList();
  }

  /// POST `/open-evalu` — open (or extend) a window. Throws on failure.
  Future<void> createWindow({
    int? studyPlanId,
    required DateTime openTime,
    required DateTime closeTime,
    int inactive = 0,
  }) async {
    await _dio.post('/open-evalu', data: {
      'study_plan_id': studyPlanId,
      'open_time': openTime.toUtc().toIso8601String(),
      'close_time': closeTime.toUtc().toIso8601String(),
      'inactive': inactive,
    });
  }

  /// PUT `/open-evalu/:id` — update a window (e.g. close it). Throws on failure.
  Future<void> updateWindow({
    required int id,
    int? studyPlanId,
    DateTime? openTime,
    required DateTime closeTime,
    required int inactive,
  }) async {
    await _dio.put('/open-evalu/$id', data: {
      'study_plan_id': studyPlanId,
      'open_time': openTime?.toUtc().toIso8601String(),
      'close_time': closeTime.toUtc().toIso8601String(),
      'inactive': inactive,
    });
  }

  /// POST `/evaluation-results` — one row per (study plan, question). Throws
  /// on failure.
  Future<void> submitResult({
    required int studyPlanId,
    required int studentId,
    required int evaQuestionId,
    required int score,
    String? comment,
  }) async {
    await _dio.post('/evaluation-results', data: {
      'study_plan_id': studyPlanId,
      'student_id': studentId,
      'eva_question_id': evaQuestionId,
      'score': score,
      'comment': comment,
    });
  }

  /// PUT `/evaluation-results/:id` — admin maintenance: correct a submitted
  /// score or scrub an abusive comment. The backend whitelists exactly these
  /// two fields; a submission's (study plan, student, question) identity is
  /// immutable. Throws on failure (403 for non-admin callers).
  Future<void> updateResult({
    required int id,
    int? score,
    String? comment,
  }) async {
    await _dio.put('/evaluation-results/$id', data: {
      if (score != null) 'score': score,
      if (comment != null) 'comment': comment,
    });
  }

  /// DELETE `/evaluation-results/:id` — admin maintenance: remove a spam or
  /// misfiled submission outright (hard delete server-side). Throws on
  /// failure (403 for non-admin callers).
  Future<void> deleteResult(int id) async {
    await _dio.delete('/evaluation-results/$id');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
