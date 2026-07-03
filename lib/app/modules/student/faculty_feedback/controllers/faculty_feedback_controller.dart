import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
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

  /// One text controller + key per question: the score box is typeable and
  /// submit can scroll to the first unanswered card.
  final scoreCtrls = <TextEditingController>[];
  final questionKeys = <GlobalKey>[];

  /// Set on a failed submit; unanswered cards render a red border until the
  /// student scores them (the per-card check also reads the rating).
  final showErrors = false.obs;

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
      // Rebuild per-question form state. The form view is never open while
      // fetchData runs, so disposing the old controllers is safe.
      for (final c in scoreCtrls) {
        c.dispose();
      }
      scoreCtrls
        ..clear()
        ..addAll(List.generate(questions.length, (_) => TextEditingController()));
      questionKeys
        ..clear()
        ..addAll(List.generate(questions.length, (_) => GlobalKey()));
      showErrors.value = false;

      // Scope to the current semester so the student only evaluates the
      // teachers in their active study plan — not every teacher the group
      // has ever had across past semesters. Null semester falls back to all.
      final activeSemester = await _academic.fetchActiveSemester();
      final plans = await _academic.fetchStudyPlans(
        studentGroupId: _stdGroupId,
        semesterId: activeSemester?.id,
        limit: 200,
      );

      final list = <Faculty>[];
      for (final p in plans) {
        final teacher = p.teacher;
        final subjectName = p.subject?.nameLao ?? p.subject?.nameEng ?? '-';
        if (teacher == null) continue;
        // The study plan denormalises the teacher's Lao name; prefer it and fall
        // back to English so the evaluation card never shows a blank name.
        final laoName = '${teacher.nameLao} ${teacher.surnameLao}'.trim();
        final engName = '${teacher.nameEng} ${teacher.surnameEng ?? ''}'.trim();
        final teacherName =
            laoName.isNotEmpty ? laoName : (engName.isNotEmpty ? engName : '-');
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
    // Keep the typeable box in sync with the +/- buttons. Empty when 0 so
    // the hint shows instead of a real "0".
    final ctrl = scoreCtrls[questionIndex];
    final text = rating == 0 ? '' : '$rating';
    if (ctrl.text != text) {
      ctrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  /// Digits arrive pre-filtered by the view's input formatter; here we only
  /// clamp to the 1–10 scale (typing "11".."99" snaps to 10).
  void onScoreTyped(int questionIndex, String value) {
    var n = int.tryParse(value) ?? 0;
    if (n > 10) n = 10;
    if ('$n' != value && value.isNotEmpty) {
      scoreCtrls[questionIndex].value = TextEditingValue(
        text: '$n',
        selection: TextSelection.collapsed(offset: '$n'.length),
      );
    }
    ratings[questionIndex] = n;
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
        showErrors.value = true;
        // Jump to the unanswered card so the student sees what's missing.
        final ctx =
            i < questionKeys.length ? questionKeys[i].currentContext : null;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1,
          );
        }
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
      for (final c in scoreCtrls) {
        c.clear();
      }
      showErrors.value = false;
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

  @override
  void onClose() {
    for (final c in scoreCtrls) {
      c.dispose();
    }
    super.onClose();
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

}