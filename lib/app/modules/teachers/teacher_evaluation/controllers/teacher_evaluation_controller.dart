import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class TeacherEvaluationController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<EvaluationResultModel> results = <EvaluationResultModel>[].obs;
  final RxList<SubjectEvalGroup> subjectGroups = <SubjectEvalGroup>[].obs;
  final RxList<EvaluationQuestionModel> questions = <EvaluationQuestionModel>[].obs;

  // Current teacher info
  final Rx<TeacherModel?> currentTeacher = Rx<TeacherModel?>(null);
  int? _currentTeacherId;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_URL'] ?? '',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    },
  ));

  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _loadToken().then((_) => _loadData());
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      if (_token.isEmpty) {
        errorMessage.value = 'ບໍ່ພົບ token (ກະລຸນາ login ໃໝ່)';
        return;
      }
      // 1. Get current user to find teacher ID
      final meResp = await _dio.get('/auth/me');
      if (meResp.statusCode == 200 && meResp.data is Map<String, dynamic>) {
        final user = UserModel.fromJson(meResp.data);
        _currentTeacherId = user.teacherId;
      }

      if (_currentTeacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      // 2. Fetch teacher info
      final teacherResp = await _dio.get('/teachers/$_currentTeacherId');
      if (teacherResp.statusCode == 200) {
        currentTeacher.value = TeacherModel.fromJson(
          teacherResp.data is Map && teacherResp.data['data'] != null
              ? teacherResp.data['data']
              : teacherResp.data,
        );
      }

      // 3. Fetch study plans for this teacher (with preloads)
      final spResp = await _dio.get('/study-plans', queryParameters: {
        'teacher_id': _currentTeacherId,
        'limit': 200,
      });
      final Map<int, StudyPlanModel> spMap = {};
      if (spResp.statusCode == 200) {
        final data = spResp.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        for (final j in items) {
          final sp = StudyPlanModel.fromJson(j);
          spMap[sp.id] = sp;
        }
      }

      // 4. Fetch evaluation results
      final evalResp = await _dio.get('/evaluation-results', queryParameters: {
        'limit': 500,
      });
      if (evalResp.statusCode == 200) {
        final data = evalResp.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        final allResults =
            items.map((j) => EvaluationResultModel.fromJson(j)).toList();

        // Filter: only results for this teacher's study plans
        final myResults = allResults.where((r) {
          return spMap.containsKey(r.studyPlanId);
        }).toList();

        // Enrich with study plan data
        for (final r in myResults) {
          final sp = spMap[r.studyPlanId];
          if (sp != null) r.studyPlan = sp;
        }

        results.assignAll(myResults);
      }

      // 5. Fetch questions
      final qResp = await _dio.get('/evaluation-questions');
      if (qResp.statusCode == 200) {
        final data = qResp.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        questions.assignAll(
          items.map((j) => EvaluationQuestionModel.fromJson(j)).toList(),
        );
      }

      _buildSubjectGroups(spMap);
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('TeacherEvaluation Dio error:\n$detail');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }

      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  void _buildSubjectGroups(Map<int, StudyPlanModel> spMap) {
    final Map<int, SubjectEvalGroup> groups = {};

    for (final r in results) {
      final spId = r.studyPlanId;
      final sp = spMap[spId];
      if (sp == null) continue;

      groups.putIfAbsent(
        spId,
        () => SubjectEvalGroup(
          studyPlanId: spId,
          subjectName: sp.subject?.nameLao ?? 'ບໍ່ລະບຸ',
          subjectCode: sp.subject?.subjectCode ?? '',
          semesterLabel: sp.semaster != null
              ? 'ປີ ${sp.semaster!.year} ເທີມ ${sp.semaster!.term}'
              : '',
          semesterId: sp.semasterId,
          studentGroupName: sp.studentGroup?.stdGroupName ?? '',
          totalResponses: 0,
          totalScore: 0,
          questionScores: {},
          comments: [],
        ),
      );

      final g = groups[spId]!;
      g.totalResponses++;
      g.totalScore += (r.score ?? 0);

      final qId = r.evaQuestionId;
      g.questionScores.putIfAbsent(
        qId,
        () => _QScore(
          questionText: r.evaQuestion?.question ?? 'ຄຳຖາມ #$qId',
          totalScore: 0,
          count: 0,
        ),
      );
      g.questionScores[qId]!.totalScore += (r.score ?? 0);
      g.questionScores[qId]!.count++;

      if (r.comment != null && r.comment!.isNotEmpty) {
        g.comments.add(r.comment!);
      }
    }

    final list = groups.values.toList();
    list.sort((a, b) {
      final cmp = b.semesterId.compareTo(a.semesterId);
      if (cmp != 0) return cmp;
      return a.subjectName.compareTo(b.subjectName);
    });

    subjectGroups.assignAll(list);
  }

  // Overall average
  double get overallAverage {
    if (results.isEmpty) return 0;
    final total = results.fold<int>(0, (sum, r) => sum + (r.score ?? 0));
    return total / results.length;
  }

  int get totalEvaluations => results.length;

  int get totalSubjects => subjectGroups.length;

  Future<void> refreshData() => _loadData();
}

// Helper models
class SubjectEvalGroup {
  final int studyPlanId;
  final String subjectName;
  final String subjectCode;
  final String semesterLabel;
  final int semesterId;
  final String studentGroupName;
  int totalResponses;
  int totalScore;
  final Map<int, _QScore> questionScores;
  final List<String> comments;

  SubjectEvalGroup({
    required this.studyPlanId,
    required this.subjectName,
    required this.subjectCode,
    required this.semesterLabel,
    required this.semesterId,
    required this.studentGroupName,
    required this.totalResponses,
    required this.totalScore,
    required this.questionScores,
    required this.comments,
  });

  double get averageScore =>
      totalResponses > 0 ? totalScore / totalResponses : 0;
}

class _QScore {
  final String questionText;
  int totalScore;
  int count;
  _QScore({required this.questionText, required this.totalScore, required this.count});
  double get average => count > 0 ? totalScore / count : 0;
}
