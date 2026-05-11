import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class TeacherHomeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxInt mySubjectsCount = 0.obs;
  final RxInt myBookingsCount = 0.obs;
  final RxInt myPendingBookingsCount = 0.obs;
  final RxInt myEvaluationsCount = 0.obs;

  final RxList<StudyPlanModel> todaySchedules = <StudyPlanModel>[].obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    fetchDashboard();
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

  Future<void> fetchDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();
      if (_token.isEmpty) {
        errorMessage.value = 'ບໍ່ພົບ token (ກະລຸນາ login ໃໝ່)';
        return;
      }
      final me = await _dio.get('/auth/me');
      if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
        currentUser.value = UserModel.fromJson(me.data);
      }

      final user = currentUser.value;
      final teacherId = user?.teacherId;
      if (teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      // Study plans of this teacher (preloads: subject/room/group/day/time)
      // Some backends may not support teacher_id filter; always fallback to
      // client-side filtering for robustness.
      final spResp = await _dio.get('/study-plans', queryParameters: {
        'teacher_id': teacherId,
        'limit': 500,
      });
      final List<dynamic> spItems = _extractList(spResp.data);
      var studyPlans = spItems.map((j) => StudyPlanModel.fromJson(j)).toList();
      if (studyPlans.isEmpty) {
        final spRespAll =
            await _dio.get('/study-plans', queryParameters: {'limit': 500});
        final allItems = _extractList(spRespAll.data);
        studyPlans = allItems
            .map((j) => StudyPlanModel.fromJson(j))
            .where((sp) => sp.teacherId == teacherId)
            .toList();
      }
      mySubjectsCount.value = studyPlans.length;

      // Today's schedules
      final todayKey = _todayKey();
      final todays = studyPlans
          .where((sp) => (sp.dayOfWeek ?? '').toLowerCase() == todayKey)
          .toList()
        ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
      todaySchedules.assignAll(todays);

      // My bookings (filter by current user id)
      final bResp = await _dio.get('/room-bookings', queryParameters: {
        'limit': 200,
      });
      final bookingsItems = _extractList(bResp.data);
      final bookings =
          bookingsItems.map((j) => RoomBookingModel.fromJson(j)).where((b) {
        return b.userId == user!.id;
      }).toList();
      myBookingsCount.value = bookings.length;
      myPendingBookingsCount.value =
          bookings.where((b) => b.status.toLowerCase() == 'pending').length;

      // My evaluations count (filter by my study plan ids)
      final spIdSet = studyPlans.map((e) => e.id).toSet();
      final evalResp = await _dio.get('/evaluation-results', queryParameters: {
        'limit': 500,
      });
      final evalItems = _extractList(evalResp.data);
      final myEvalCount = evalItems
          .map((j) => EvaluationResultModel.fromJson(j))
          .where((r) => spIdSet.contains(r.studyPlanId))
          .length;
      myEvaluationsCount.value = myEvalCount;
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('Teacher dashboard Dio error:\n$detail');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }

      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້';
    } catch (e) {
      debugPrint('Teacher dashboard error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await fetchDashboard();
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  static String _todayKey() {
    // Backend usually stores: monday..sunday (lowercase)
    const keys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final i = DateTime.now().weekday - 1;
    return keys[i.clamp(0, 6)];
  }
}
