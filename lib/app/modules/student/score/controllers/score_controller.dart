import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class ScoreController extends GetxController {
  var selectedTermIndex = 0.obs;
  void changeTerm(int index) => selectedTermIndex.value = index;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<EnrollmentModel> enrollments = <EnrollmentModel>[].obs;

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    fetchData();
  }

  void _initDio() {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();

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
      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'Session expired. Please login again.';
        Get.offAllNamed('/auth');
        return;
      }
      errorMessage.value = 'Failed to load scores.';
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
