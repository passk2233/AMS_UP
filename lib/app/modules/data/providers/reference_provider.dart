import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for organizational reference / lookup data used by the
/// announcement audience selector: departments, student groups, student types.
///
/// Owns the endpoint paths, JSON-envelope unwrapping, and JSON → model
/// mapping. Methods throw [DioException] on failure.
class ReferenceProvider {
  ReferenceProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/departments`.
  Future<List<DepartmentModel>> fetchDepartments({int limit = 50}) async {
    final resp =
        await _dio.get('/departments', queryParameters: {'limit': limit});
    return _extractList(resp.data)
        .map((j) => DepartmentModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET `/student-groups`.
  Future<List<StudentGroupModel>> fetchStudentGroups({int limit = 100}) async {
    final resp =
        await _dio.get('/student-groups', queryParameters: {'limit': limit});
    return _extractList(resp.data)
        .map((j) => StudentGroupModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// GET `/student-types`.
  Future<List<StudentTypeModel>> fetchStudentTypes() async {
    final resp = await _dio.get('/student-types');
    return _extractList(resp.data)
        .map((j) => StudentTypeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
