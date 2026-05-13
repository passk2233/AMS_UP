import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class ProfileStudentController extends GetxController {
  late final Dio _dio;
  String _token = '';

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initDio();
    _loadToken().then((_) => fetchProfile());
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

  Future<void> fetchProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        user.value = UserModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('ProfileStudent fetchProfile Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'Session expired. Please login again.';
        Get.offAllNamed('/auth');
        return;
      }
      errorMessage.value = 'Failed to load profile.';
    } catch (e) {
      debugPrint('ProfileStudent fetchProfile error: $e');
      errorMessage.value = 'Failed to load profile.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'Sign out',
      message: 'Do you want to sign out?',
      confirmText: 'Sign out',
      cancelText: 'Cancel',
      confirmColor: const Color(0xFFE53935),
    );
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    Get.offAllNamed('/auth');
  }

  UserModel? get _u => user.value;
  StudentModel? get student => _u?.student;

  String get displayName {
    final s = student;
    if (s == null) return _u?.username ?? '';
    final surname = (s.surnameEng ?? '').trim();
    final name = s.nameEng.trim();
    if (surname.isEmpty) return name;
    return '$name $surname';
  }

  String get studentCode => student?.stdCode ?? '-';
  String get gender => student?.gender ?? '-';
  String get email => student?.email ?? _u?.email ?? '-';
  String get phone => student?.telephone ?? '-';
  DateTime? get dob => student?.dateofbirth;
  String get nationality => student?.nationality ?? '-';
  String get address => '-';
  String get program {
    final cur = student?.curriculum;
    if (cur == null) return '-';
    return (cur.curriNameEng != null && cur.curriNameEng!.trim().isNotEmpty)
        ? cur.curriNameEng!.trim()
        : cur.curriNameLao;
  }
}
