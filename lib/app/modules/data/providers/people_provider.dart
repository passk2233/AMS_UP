import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for the people directories: students, teachers, and the
/// raw `users` table. Used by the announcement composer (audience lookup),
/// the teacher self-evaluation view, and the booking notification fan-out.
///
/// Owns the endpoint paths, JSON-envelope unwrapping, and JSON → model
/// mapping. Methods throw [DioException] on failure.
class PeopleProvider {
  PeopleProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/teachers/:id` — a single teacher, or `null` when the payload is
  /// not a JSON object. Tolerates both a bare object and a `{ "data": {...} }`
  /// envelope.
  Future<TeacherModel?> fetchTeacherById(int teacherId) async {
    final resp = await _dio.get('/teachers/$teacherId');
    final data = resp.data;
    final json = (data is Map && data['data'] != null) ? data['data'] : data;
    if (json is Map<String, dynamic>) return TeacherModel.fromJson(json);
    return null;
  }

  /// GET `/teachers`, optionally scoped to a department.
  Future<List<TeacherModel>> fetchTeachers({int? deptId, int limit = 200}) async {
    final query = <String, dynamic>{'limit': limit};
    if (deptId != null) query['dept_id'] = deptId;
    final resp = await _dio.get('/teachers', queryParameters: query);
    return _extractList(resp.data)
        .map((j) => TeacherModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET `/students`, optionally scoped to a student group and/or an extra
  /// [filters] map (e.g. dept / type / year used by the announcement reach
  /// estimate).
  Future<List<StudentModel>> fetchStudents({
    int? studentGroupId,
    Map<String, dynamic>? filters,
    int limit = 500,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (studentGroupId != null) query['std_group_id'] = studentGroupId;
    if (filters != null) query.addAll(filters);
    final resp = await _dio.get('/students', queryParameters: query);
    return _extractList(resp.data)
        .map((j) => StudentModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET `/students/:id` — a single student, or `null`.
  Future<StudentModel?> fetchStudentById(int id) async {
    final resp = await _dio.get('/students/$id');
    final data = resp.data;
    final json = (data is Map && data['data'] != null) ? data['data'] : data;
    if (json is Map<String, dynamic>) return StudentModel.fromJson(json);
    return null;
  }

  /// GET `/users`.
  Future<List<UserModel>> fetchUsers({int limit = 1000}) async {
    final resp = await _dio.get('/users', queryParameters: {'limit': limit});
    return _extractList(resp.data)
        .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
