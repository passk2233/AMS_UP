import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for academic reference data shared across the home,
/// schedule, score, booking and evaluation features: semesters, study plans
/// (the fixed class timetable), and enrollments.
///
/// Owns the endpoint paths, query shapes, JSON-envelope unwrapping, and
/// JSON → model mapping. Methods throw [DioException] on failure; callers own
/// the user-facing error handling. The active-semester heuristic — previously
/// copy-pasted into half a dozen controllers — lives here as a pure static so
/// it is shared and unit-testable.
class AcademicProvider {
  AcademicProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/semasters`.
  Future<List<SemasterModel>> fetchSemesters({int limit = 20}) async {
    final resp = await _dio.get(
      '/semasters',
      queryParameters: {'limit': limit},
    );
    return _extractList(resp.data)
        .map((j) => SemasterModel.fromJson(j))
        .toList();
  }

  /// The semester to treat as "current": the one whose date range contains
  /// today, else the first flagged `status == 1`, else the first row.
  Future<SemasterModel?> fetchActiveSemester({int limit = 20}) async =>
      pickActiveSemester(await fetchSemesters(limit: limit));

  /// Pure selection of the active semester from an already-loaded list.
  /// Exposed (and static) so it can be reused and tested without a network.
  static SemasterModel? pickActiveSemester(List<SemasterModel> all) {
    if (all.isEmpty) return null;
    final now = DateTime.now();
    final containing = all.where((s) =>
        s.startDate != null &&
        s.endDate != null &&
        !now.isBefore(_dateOnly(s.startDate!)) &&
        !now.isAfter(_dateOnly(s.endDate!).add(const Duration(days: 1))));
    if (containing.isNotEmpty) return containing.first;
    final active = all.where((s) => s.status == 1);
    return active.isNotEmpty ? active.first : all.first;
  }

  /// GET `/study-plans` — the fixed class timetable. Any combination of the
  /// optional filters is forwarded as query params; the caller still applies
  /// whatever client-side ordering / refinement it needs.
  Future<List<StudyPlanModel>> fetchStudyPlans({
    int? teacherId,
    int? semesterId,
    int? studentGroupId,
    int limit = 500,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (teacherId != null) query['teacher_id'] = teacherId;
    if (semesterId != null) query['semaster_id'] = semesterId;
    if (studentGroupId != null) query['std_group_id'] = studentGroupId;
    final resp = await _dio.get('/study-plans', queryParameters: query);
    return _extractList(resp.data)
        .map((j) => StudyPlanModel.fromJson(j))
        .toList();
  }

  /// GET `/class-cancellations` — single-date exceptions to the study-plan
  /// timetable. A plan with a cancellation row on a date does not occupy its
  /// room that day; every role's booking UI needs these to render freed
  /// slots. [from]/[to] bound `cancel_date` (calendar days, inclusive).
  Future<List<ClassCancellationModel>> fetchClassCancellations({
    int? studyPlanId,
    int? teacherId,
    DateTime? from,
    DateTime? to,
    // The backend caps page size at 200 (handlers.maxLimit) — asking for
    // more is silently truncated, so don't pretend otherwise.
    int limit = 200,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (studyPlanId != null) query['study_plan_id'] = studyPlanId;
    if (teacherId != null) query['teacher_id'] = teacherId;
    if (from != null) query['from'] = _isoDate(from);
    if (to != null) query['to'] = _isoDate(to);
    final resp = await _dio.get('/class-cancellations', queryParameters: query);
    return _extractList(resp.data)
        .map((j) => ClassCancellationModel.fromJson(j))
        .toList();
  }

  /// POST `/class-cancellations` — cancel one occurrence of [studyPlanId] on
  /// [date]. Only the plan's own teacher or an admin may call this (the
  /// backend enforces it; 403 otherwise). Idempotent server-side: re-sending
  /// the same (plan, date) returns the existing row. Returns the row id.
  Future<int?> cancelClassOccurrence({
    required int studyPlanId,
    required DateTime date,
    String? reason,
  }) async {
    final resp = await _dio.post('/class-cancellations', data: {
      'study_plan_id': studyPlanId,
      'cancel_date': _isoDate(date),
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    final data = resp.data;
    return (data is Map<String, dynamic>) ? data['id'] as int? : null;
  }

  /// DELETE `/class-cancellations/:id` — restore a previously cancelled
  /// occurrence. Same authorization as [cancelClassOccurrence].
  Future<void> restoreClassOccurrence(int cancellationId) async {
    await _dio.delete('/class-cancellations/$cancellationId');
  }

  /// GET `/enrollments` — a student's graded course records.
  Future<List<EnrollmentModel>> fetchEnrollments({
    int? studentId,
    int limit = 200,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (studentId != null) query['std_id'] = studentId;
    final resp = await _dio.get('/enrollments', queryParameters: query);
    return _extractList(resp.data)
        .map((j) => EnrollmentModel.fromJson(j))
        .toList();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar-date wire format (`YYYY-MM-DD`) for cancel_date params — the
  /// backend's parseDateOrTime accepts bare dates here, unlike booking_date.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
