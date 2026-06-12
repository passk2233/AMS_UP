import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class FacultyFeedbackController extends GetxController {
  FacultyFeedbackController({
    AuthProvider? auth,
    AcademicProvider? academic,
    EvaluationProvider? evaluation,
  })  : _auth = auth ?? AuthProvider(),
        _academic = academic ?? AcademicProvider(),
        _eval = evaluation ?? EvaluationProvider();

  final AuthProvider _auth;
  final AcademicProvider _academic;
  final EvaluationProvider _eval;

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
      final user = await _auth.me();
      _studentId = user?.stdId ?? user?.student?.id;
      _stdGroupId = user?.student?.stdGroupId;

      if (_studentId == null || _stdGroupId == null) {
        errorMessage.value = 'ບັນຊີນັກສຶກສາຍັງບໍ່ໄດ້ເຊື່ອມຕໍ່.';
        return;
      }

      await _fetchEvaluationWindow();
      if (!isEvaluationOpen.value) {
        facultyList.clear();
        questions.clear();
        return;
      }

      questions.assignAll(await _eval.fetchQuestions(activeOnly: true));
      ratings.assignAll(List.filled(questions.length, 0));

      final plans = await _academic.fetchStudyPlans(
        studentGroupId: _stdGroupId,
        limit: 200,
      );

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
          photo: teacher.photo,
          isSubmitted: submitted,
        ));
      }
      facultyList.assignAll(list);
    } on DioException catch (e) {
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດລາຍການອາຈານໄດ້.';
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
      final window = await _eval.fetchActiveWindow();
      activeWindow.value = window;
      // isOpenNow (not just inactive == 0) so a window scheduled for the
      // future doesn't open the form early and an expired one closes itself.
      isEvaluationOpen.value = window?.isOpenNow ?? false;
    } on DioException catch (e) {
      activeWindow.value = null;
      isEvaluationOpen.value = false;
      Get.log('fetchEvaluationWindow error: ${e.message}');
    }
  }

  Future<bool> _hasSubmitted(int studyPlanId, int studentId) async {
    final items = await _eval.fetchResults(
      studyPlanId: studyPlanId,
      studentId: studentId,
      limit: 200,
    );
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
      Get.snackbar('ເຕືອນ', 'ໄລຍະການປະເມີນຍັງບໍ່ໄດ້ເປີດ.');
      return;
    }
    if (questions.isEmpty) {
      Get.snackbar('ເຕືອນ', 'ບໍ່ພົບຄໍາຖາມປະເມີນ.');
      return;
    }
    for (int i = 0; i < ratings.length; i++) {
      if (ratings[i] <= 0) {
        Get.snackbar('ເຕືອນ', 'ກະລຸນາໃຫ້ຄະແນນຄົບທຸກຄໍາຖາມ.');
        return;
      }
    }

    try {
      isLoading.value = true;
      for (int i = 0; i < questions.length; i++) {
        await _eval.submitResult(
          studyPlanId: faculty.studyPlanId,
          studentId: _studentId!,
          evaQuestionId: questions[i].evaQuestionId,
          score: ratings[i],
          comment: i == 0 ? comment.value.trim() : null,
        );
      }

      final index = facultyList.indexWhere((f) => f.studyPlanId == faculty.studyPlanId);
      if (index != -1) {
        facultyList[index] = Faculty(
          studyPlanId: faculty.studyPlanId,
          teacherId: faculty.teacherId,
          initials: faculty.initials,
          name: faculty.name,
          course: faculty.course,
          photo: faculty.photo,
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
      Get.snackbar('ຜິດພາດ', 'ສົ່ງການປະເມີນບໍ່ສຳເລັດ.');
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

}