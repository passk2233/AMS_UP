import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class SchedulesController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<StudyPlanModel> schedules = <StudyPlanModel>[].obs;
  final RxInt selectedDay = 0.obs;

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    fetchSchedules();
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

  Future<void> fetchSchedules() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();
      if (_token.isEmpty) {
        errorMessage.value = 'ບໍ່ພົບ token (ກະລຸນາ login ໃໝ່)';
        return;
      }

      final me = await _dio.get('/auth/me');
      final user = (me.statusCode == 200 && me.data is Map<String, dynamic>)
          ? UserModel.fromJson(me.data)
          : null;
      final teacherId = user?.teacherId;
      if (teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }

      final resp = await _dio.get('/study-plans', queryParameters: {
        'teacher_id': teacherId,
        'limit': 500,
      });
      final items = _extractList(resp.data);
      var list = items.map((j) => StudyPlanModel.fromJson(j)).toList();

      // Fallback: if backend ignores teacher_id filter, fetch all then filter.
      if (list.isEmpty) {
        final respAll =
            await _dio.get('/study-plans', queryParameters: {'limit': 500});
        final allItems = _extractList(respAll.data);
        list = allItems
            .map((j) => StudyPlanModel.fromJson(j))
            .where((sp) => sp.teacherId == teacherId)
            .toList();
      }

      list
        .sort((a, b) {
          final d = _dayIndex(a.dayOfWeek).compareTo(_dayIndex(b.dayOfWeek));
          if (d != 0) return d;
          return (a.startTime ?? '').compareTo(b.startTime ?? '');
        });
      schedules.assignAll(list);
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('Schedules Dio error:\n$detail');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }

      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຕາຕະລາງໄດ້';
    } catch (e) {
      debugPrint('Schedules error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຕາຕະລາງໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() => fetchSchedules();

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  static int _dayIndex(String? day) {
    final d = (day ?? '').toLowerCase().trim();
    switch (d) {
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      case 'sunday':
        return 7;
      default:
        return 99;
    }
  }
}
