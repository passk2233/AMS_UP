import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class TeacherProfileController extends GetxController {
  final Dio _dio = Dio();
  String _token = '';

  // ── Profile data ──────────────────────────────────────────────────────────
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initDio();
    _loadToken().then((_) => fetchProfile());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIO SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  void _initDio() {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  final RxString errorMessage = ''.obs;

  Future<void> fetchProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        user.value = UserModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('fetchProfile Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');

      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)';
        Get.offAllNamed('/auth');
        return;
      }

      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໂປຣໄຟລ໌ໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> logout() async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ອອກຈາກລະບົບ',
      message: 'ທ່ານຕ້ອງການອອກຈາກລະບົບແທ້ບໍ?',
      confirmText: 'ອອກ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: const Color(0xFFE53935),
    );
    if (confirmed != true) return;

    isLoggingOut.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      Get.offAllNamed('/auth');
    } finally {
      isLoggingOut.value = false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get displayName {
    final u = user.value;
    if (u == null) return '';
    return u.username;
  }

  String get displayEmail {
    return user.value?.email ?? '-';
  }

  String get displayRoles {
    final roles = user.value?.roles;
    if (roles == null || roles.isEmpty) return '-';
    return roles.join(', ');
  }

  String get accountStatus {
    final active = user.value?.active;
    if (active == null) return '-';
    return active == 1 ? 'ເປີດໃຊ້ງານ' : 'ປິດໃຊ້ງານ';
  }

  String get memberSince {
    final d = user.value?.createdAt;
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> refreshData() => fetchProfile();
}
