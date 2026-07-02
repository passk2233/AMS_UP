import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/data/data_exporter.dart';
import '../../services/api_client.dart';

/// Shared, role-agnostic source of the active-semester label shown in
/// [AppTopBar].
///
/// Safe for admin / teacher / student alike — it reads only the public
/// `/semasters` list, never a role-scoped resource. One permanent instance is
/// shared across every top bar (see [semesterController]) so the semester is
/// fetched once and stays consistent as the user moves between tabs.
///
/// The fetch is best-effort: a failure logs and leaves [semester] at a
/// readable fallback so the bar never blocks on networking.
class SemesterController extends GetxController {
  /// Active-semester display label (e.g. `S1 (2025-2026)`).
  final RxString semester = ''.obs;

  /// Year of the active semester's label (e.g. 2025 for "2025-2"), or null
  /// until fetched / on failure. Drives the study-year computation so a
  /// student's year matches the semester label, not the calendar date.
  final Rxn<int> activeYear = Rxn<int>();

  /// `true` while [fetchActiveSemester] is in flight.
  final RxBool semesterLoading = true.obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchActiveSemester();
  }

  /// GET `/semasters` and resolve the active-semester label. Best-effort — on
  /// failure the label falls back to a generic string instead of throwing.
  Future<void> fetchActiveSemester() async {
    semesterLoading.value = true;
    try {
      final response = await _dio.get(
        '/semasters',
        queryParameters: {'limit': 10},
      );
      if (response.statusCode != 200) return;

      final all = _extractList(response.data)
          .map((json) => SemasterModel.fromJson(json))
          .toList();
      final picked = _pickActiveSemester(all);
      semester.value = picked == null ? 'No active semester' : _format(picked);
      activeYear.value = int.tryParse('${picked?.year ?? ''}');
    } on DioException catch (e) {
      debugPrint('Failed to fetch semester: ${e.message}');
      semester.value = 'Semester';
    } finally {
      semesterLoading.value = false;
    }
  }

  /// Normalize the server's two response shapes — raw array or
  /// `{ "data": [...] }` envelope — into a `List<dynamic>`.
  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const <dynamic>[];
  }

  /// Pick the semester to display using a three-tier fallback: in-range by
  /// date → flagged active → newest. Returns null when the list is empty.
  SemasterModel? _pickActiveSemester(List<SemasterModel> all) {
    if (all.isEmpty) return null;

    final now = DateTime.now();
    final byDate = all.where((s) {
      final start = s.startDate;
      final end = s.endDate;
      if (start == null || end == null) return false;
      return !now.isBefore(start) && !now.isAfter(end);
    }).toList();
    if (byDate.isNotEmpty) return byDate.first;

    final active = all.where((s) => s.status == 1).toList();
    if (active.isNotEmpty) return active.first;

    return all.first;
  }

  // Label by term/year (e.g. "ພາກຮຽນ 1/2025") rather than the raw
  // `semaster_code`, matching the semester label the schedule screens show.
  String _format(SemasterModel s) => 'ພາກຮຽນ ${s.term}/${s.year}';
}

/// Lazily resolve the shared [SemesterController], registering it (permanent)
/// on first use so every top bar across the app reads one semester.
SemesterController get semesterController {
  if (!Get.isRegistered<SemesterController>()) {
    Get.put(SemesterController(), permanent: true);
  }
  return Get.find<SemesterController>();
}
