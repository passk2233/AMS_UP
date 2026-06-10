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

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
