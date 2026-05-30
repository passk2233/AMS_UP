import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/modules/student/faculty_feedback/views/faculty_model.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class FacultyFeedbackController extends GetxController {
  final RxList<Faculty> facultyList = <Faculty>[].obs;
  final RxList<EvaluationQuestionModel> questions = <EvaluationQuestionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString query = ''.obs;

  /// `true` once admin has opened the evaluation window and the current
  /// moment falls inside it. Drives the empty/closed state of the page.
  final RxBool isEvaluationOpen = false.obs;

  /// Active window row (latest `open_evalu`). Used so the closed-state UI
  /// can show the next opening time when admin has scheduled a future
  /// window.
  final Rx<OpenEvaluationModel?> activeWindow =
      Rx<OpenEvaluationModel?>(null);

  Dio get _dio => ApiClient.dio;
  int? _studentId;
  int? _stdGroupId;

  var ratings = <int>[].obs;
  var comment = "".obs;

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
      final user = UserModel.fromJson(me.data);
      _studentId = user.stdId ?? user.student?.id;
      _stdGroupId = user.student?.stdGroupId;

      if (_studentId == null || _stdGroupId == null) {
        errorMessage.value = 'Student account is not linked.';
        return;
      }

      await _fetchEvaluationWindow();
      if (!isEvaluationOpen.value) {
        facultyList.clear();
        questions.clear();
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

  /// GET `/open-evalu` and update [activeWindow] + [isEvaluationOpen].
  /// Public so the form view's poll timer can re-check the gate without
  /// going through a full [fetchData].
  Future<void> refreshEvaluationWindow() => _fetchEvaluationWindow();

  Future<void> _fetchEvaluationWindow() async {
    try {
      final resp = await _dio.get(
        '/open-evalu',
        queryParameters: {'limit': 1, 'inactive': 0},
      );
      final items = _extractList(resp.data);
      if (items.isEmpty) {
        activeWindow.value = null;
        isEvaluationOpen.value = false;
        return;
      }
      final window = OpenEvaluationModel.fromJson(items.first);
      activeWindow.value = window;
      isEvaluationOpen.value = window.inactive == 0;
    } on DioException catch (e) {
      activeWindow.value = null;
      isEvaluationOpen.value = false;
      Get.log('fetchEvaluationWindow error: ${e.message}');
    }
  }

  Future<bool> _hasSubmitted(int studyPlanId, int studentId) async {
    final r = await _dio.get('/evaluation-results', queryParameters: {
      'study_plan_id': studyPlanId,
      'student_id': studentId,
      'limit': 200,
    });
    final items = _extractList(r.data);
    // Only consider fully submitted when every active question has a result.
    // A partial submission (some POSTs failed mid-loop) must not lock the
    // student out — they should be able to re-open the form and re-submit.
    return questions.isNotEmpty && items.length >= questions.length;
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
    if (!isEvaluationOpen.value) {
      Get.snackbar('Warning', 'ໄລຍະການປະເມີນຍັງບໍ່ໄດ້ເປີດ.');
      return;
    }
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
      Future.delayed(const Duration(milliseconds: 150), () {
        Get.snackbar('ສຳເລັດ', 'ສົ່ງການປະເມີນສຳເລັດ.');
      });
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