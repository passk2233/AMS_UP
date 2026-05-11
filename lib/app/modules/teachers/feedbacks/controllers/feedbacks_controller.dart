import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class FeedbacksController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Flattened feedback/comments from evaluation results for this teacher.
  final RxList<TeacherFeedbackItem> items = <TeacherFeedbackItem>[].obs;

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    fetchFeedbacks();
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

  Future<void> fetchFeedbacks() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();
      if (_token.isEmpty) {
        errorMessage.value = 'ບໍ່ພົບ token (ກະລຸນາ login ໃໝ່)';
        return;
      }

      final meResp = await _dio.get('/auth/me');
      final user =
          (meResp.statusCode == 200 && meResp.data is Map<String, dynamic>)
              ? UserModel.fromJson(meResp.data)
              : null;
      final teacherId = user?.teacherId;
      if (teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      // Study plans (fallback to client filter if needed)
      final spResp = await _dio.get('/study-plans', queryParameters: {
        'teacher_id': teacherId,
        'limit': 500,
      });
      var spItems = _extractList(spResp.data);
      var studyPlans = spItems.map((j) => StudyPlanModel.fromJson(j)).toList();
      if (studyPlans.isEmpty) {
        final spAll =
            await _dio.get('/study-plans', queryParameters: {'limit': 500});
        spItems = _extractList(spAll.data);
        studyPlans = spItems
            .map((j) => StudyPlanModel.fromJson(j))
            .where((sp) => sp.teacherId == teacherId)
            .toList();
      }
      final spMap = <int, StudyPlanModel>{
        for (final sp in studyPlans) sp.id: sp
      };

      // Evaluation results -> take only ones that have comments
      final evalResp = await _dio.get('/evaluation-results', queryParameters: {
        'limit': 500,
      });
      final evalItems = _extractList(evalResp.data);
      final results = evalItems.map((j) => EvaluationResultModel.fromJson(j));
      final list = <TeacherFeedbackItem>[];
      for (final r in results) {
        final c = (r.comment ?? '').trim();
        if (c.isEmpty) continue;
        final sp = spMap[r.studyPlanId];
        if (sp == null) continue;
        list.add(
          TeacherFeedbackItem(
            subjectName: sp.subject?.nameLao ?? 'ບໍ່ລະບຸວິຊາ',
            subjectCode: sp.subject?.subjectCode ?? '',
            studentGroupName: sp.studentGroup?.stdGroupName ?? '',
            semesterLabel: sp.semaster != null
                ? 'ປີ ${sp.semaster!.year} ເທີມ ${sp.semaster!.term}'
                : '',
            comment: c,
          ),
        );
      }

      items.assignAll(list.reversed.toList());
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('Feedbacks Dio error:\n$detail');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }

      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຄຳເຫັນໄດ້';
    } catch (e) {
      debugPrint('Feedbacks error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຄຳເຫັນໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() => fetchFeedbacks();

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}

class TeacherFeedbackItem {
  final String subjectName;
  final String subjectCode;
  final String studentGroupName;
  final String semesterLabel;
  final String comment;

  TeacherFeedbackItem({
    required this.subjectName,
    required this.subjectCode,
    required this.studentGroupName,
    required this.semesterLabel,
    required this.comment,
  });
}
