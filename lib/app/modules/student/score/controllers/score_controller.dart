import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class ScoreController extends GetxController {
  var selectedTermIndex = 0.obs;
  void changeTerm(int index) => selectedTermIndex.value = index;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<EnrollmentModel> enrollments = <EnrollmentModel>[].obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final me = await _dio.get('/auth/me');
      if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
        currentUser.value = UserModel.fromJson(me.data);
      }
      final stdId = currentUser.value?.stdId ?? currentUser.value?.student?.id;
      if (stdId == null) {
        errorMessage.value = 'Student account not linked.';
        return;
      }

      final resp = await _dio.get('/enrollments', queryParameters: {
        'std_id': stdId,
        'limit': 200,
      });
      final items = _extractList(resp.data);
      enrollments.assignAll(items.map((j) => EnrollmentModel.fromJson(j)).toList());
    } on DioException catch (e) {
      debugPrint('ScoreController Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      errorMessage.value = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : 'Failed to load scores.';
    } catch (e) {
      debugPrint('ScoreController error: $e');
      errorMessage.value = 'Failed to load scores.';
    } finally {
      isLoading.value = false;
    }
  }

  String get displayName {
    final s = currentUser.value?.student;
    if (s == null) return currentUser.value?.username ?? '';
    final surname = (s.surnameEng ?? '').trim();
    final name = s.nameEng.trim();
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get studentCode => currentUser.value?.student?.stdCode ?? '-';

  double get gpa {
    double totalPoints = 0;
    int totalCredits = 0;
    for (final e in enrollments) {
      final grade = e.grade?.trim();
      if (grade == null || grade.isEmpty) continue;
      final credit = e.studyPlan?.subject?.credit ?? 0;
      final gp = _gradePoint(grade);
      if (gp == null || credit <= 0) continue;
      totalCredits += credit;
      totalPoints += gp * credit;
    }
    if (totalCredits == 0) return 0;
    return totalPoints / totalCredits;
  }

  int get earnedCredits {
    int sum = 0;
    for (final e in enrollments) {
      final credit = e.studyPlan?.subject?.credit ?? 0;
      if (credit <= 0) continue;
      sum += credit;
    }
    return sum;
  }

  /// GPA computed per semester (term-weighted average of grade points), in
  /// chronological order by semesterId. Each entry is `(semesterId, gpa)`.
  /// Semesters with no graded credits are skipped.
  List<({int semesterId, double gpa})> get gpaTrend {
    final acc = <int, ({double points, int credits})>{};
    for (final e in enrollments) {
      final semId = e.studyPlan?.semasterId;
      if (semId == null) continue;
      final grade = e.grade?.trim();
      if (grade == null || grade.isEmpty) continue;
      final credit = e.studyPlan?.subject?.credit ?? 0;
      final gp = _gradePoint(grade);
      if (gp == null || credit <= 0) continue;
      final entry = acc[semId] ?? (points: 0.0, credits: 0);
      acc[semId] = (
        points: entry.points + gp * credit,
        credits: entry.credits + credit,
      );
    }
    final out = acc.entries
        .where((e) => e.value.credits > 0)
        .map((e) => (
              semesterId: e.key,
              gpa: e.value.points / e.value.credits,
            ))
        .toList();
    out.sort((a, b) => a.semesterId.compareTo(b.semesterId));
    return out;
  }

  static double? _gradePoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 4.0;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.5;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return null;
    }
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
