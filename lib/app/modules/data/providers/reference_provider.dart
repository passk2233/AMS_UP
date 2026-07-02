import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../data_exporter.dart';

/// Data-access layer for organizational reference / lookup data used by the
/// announcement audience selector: student groups.
///
/// Owns the endpoint paths, JSON-envelope unwrapping, and JSON → model
/// mapping. Methods throw [DioException] on failure.
class ReferenceProvider {
  ReferenceProvider({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  /// GET `/student-groups`.
  Future<List<StudentGroupModel>> fetchStudentGroups({int limit = 100}) async {
    final resp =
        await _dio.get('/student-groups', queryParameters: {'limit': limit});
    return _extractList(resp.data)
        .map((j) => StudentGroupModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}
