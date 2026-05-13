import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/modules/student/faculty_feedback/views/faculty_model.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class FacultyFeedbackController extends GetxController {
  final RxList<Faculty> facultyList = <Faculty>[].obs;
  final RxList<EvaluationQuestionModel> questions = <EvaluationQuestionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString query = ''.obs;

  late final Dio _dio;
  String _token = '';
  int? _studentId;
  int? _stdGroupId;

  var ratings = <int>[].obs;
  var comment = "".obs;

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
      final user = UserModel.fromJson(me.data);
      _studentId = user.stdId ?? user.student?.id;
      _stdGroupId = user.student?.stdGroupId;

      if (_studentId == null || _stdGroupId == null) {
        errorMessage.value = 'Student account is not linked.';
        return;
      }

      final qResp = await _dio.get('/evaluation-questions', queryParameters: {'is_active': 1});
      final qItems = _extractList(qResp.data);
      questions.assignAll(qItems.map((e) => EvaluationQuestionModel.fromJson(e)).toList());
      ratings.assignAll(List.filled(questions.length, 0));

      final planResp = await _dio.get('/study-plans', queryParameters: {
        'std_group_id': _stdGroupId,
        'limit': 200,
      });
      final planItems = _extractList(planResp.data);
      final plans = planItems.map((e) => StudyPlanModel.fromJson(e)).toList();

      final list = <Faculty>[];
      for (final p in plans) {
        final teacher = p.teacher;
        final subjectName = p.subject?.nameEng ?? p.subject?.nameLao ?? '-';
        if (teacher == null) continue;
        final teacherName = (teacher.surnameEng != null && teacher.surnameEng!.trim().isNotEmpty)
            ? '${teacher.nameEng} ${teacher.surnameEng}'
            : teacher.nameEng;
        final initials = _initials(teacherName);
        final submitted = await _hasSubmitted(p.id, _studentId!);
        list.add(Faculty(
          studyPlanId: p.id,
          teacherId: teacher.id,
          initials: initials,
          name: teacherName,
          course: subjectName,
          isSubmitted: submitted,
        ));
      }
      facultyList.assignAll(list);
    } on DioException catch (e) {
      errorMessage.value = 'Failed to load faculty list.';
      Get.log(AppDialogs.buildDioErrorDetail(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _hasSubmitted(int studyPlanId, int studentId) async {
    final r = await _dio.get('/evaluation-results', queryParameters: {
      'study_plan_id': studyPlanId,
      'student_id': studentId,
      'limit': 1,
    });
    final items = _extractList(r.data);
    return items.isNotEmpty;
  }

  List<Faculty> get filteredFacultyList {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return facultyList;
    return facultyList.where((f) {
      return f.name.toLowerCase().contains(q) || f.course.toLowerCase().contains(q);
    }).toList();
  }

  void setRating(int questionIndex, int rating) {
    ratings[questionIndex] = rating;
  }

  Future<void> submitFeedback(Faculty faculty) async {
    if (_studentId == null) return;
    if (questions.isEmpty) {
      Get.snackbar('Warning', 'No evaluation questions found.');
      return;
    }
    for (int i = 0; i < ratings.length; i++) {
      if (ratings[i] <= 0) {
        Get.snackbar('Warning', 'Please rate all questions.');
        return;
      }
    }

    try {
      isLoading.value = true;
      for (int i = 0; i < questions.length; i++) {
        await _dio.post('/evaluation-results', data: {
          'study_plan_id': faculty.studyPlanId,
          'student_id': _studentId,
          'eva_question_id': questions[i].evaQuestionId,
          'score': ratings[i],
          'comment': i == 0 ? comment.value.trim() : null,
        });
      }

      final index = facultyList.indexWhere((f) => f.studyPlanId == faculty.studyPlanId);
      if (index != -1) {
        facultyList[index] = Faculty(
          studyPlanId: faculty.studyPlanId,
          teacherId: faculty.teacherId,
          initials: faculty.initials,
          name: faculty.name,
          course: faculty.course,
          isSubmitted: true,
        );
      }
      ratings.assignAll(List.filled(questions.length, 0));
      comment.value = '';
      Get.back();
      Get.snackbar('Success', 'Feedback submitted.');
    } on DioException catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback.');
      Get.log(AppDialogs.buildDioErrorDetail(e));
    } finally {
      isLoading.value = false;
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}