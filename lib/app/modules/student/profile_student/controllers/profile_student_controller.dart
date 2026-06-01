import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/services/auth_storage.dart';
import 'package:frontend/app/services/fcm_service.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

import '../../../../widgets/widget.dart';

class ProfileStudentController extends GetxController {
  Dio get _dio => ApiClient.dio;

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggingOut = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        user.value = UserModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint(
        'ProfileStudent fetchProfile Dio error:\n${AppDialogs.buildDioErrorDetail(e)}',
      );
      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      errorMessage.value = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : 'Failed to load profile.';
    } catch (e) {
      debugPrint('ProfileStudent fetchProfile error: $e');
      errorMessage.value = 'Failed to load profile.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ອອກຈາກລະບົບ',
      message: 'ທ່ານຕ້ອງການອອກຈາກລະບົບແທ້ບໍ?',
      confirmText: 'ອອກ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: AppColors.rejectRed,
    );
    if (confirmed != true) return;

    isLoggingOut.value = true;
    try {
      await FCMService.clearTokenOnLogout();
      await AuthStorage.clear();
      Get.offAllNamed('/auth');
    } finally {
      isLoggingOut.value = false;
    }
  }

  UserModel? get _u => user.value;
  StudentModel? get student => _u?.student;

  String get displayName {
    final s = student;
    if (s == null) return _u?.username ?? '';
    final title = s.nameTitle.trim();
    final name = s.nameLao.trim();
    final surname = (s.surnameLao ?? '').trim();
    final fullName = surname.isEmpty ? name : '$name $surname';
    return title.isNotEmpty ? '$title $fullName' : fullName;
  }

  String get nameEng {
    final s = student;
    if (s == null) return '-';
    final name = s.nameEng.trim();
    final surname = (s.surnameEng ?? '').trim();
    return surname.isEmpty ? name : '$name $surname';
  }

  String get studentCode => student?.stdCode ?? '-';
  String get gender => student?.gender ?? '-';
  String get email => student?.email ?? _u?.email ?? '-';
  String get phone => student?.telephone ?? '-';
  DateTime? get dob => student?.dateofbirth;
  String get nationality => student?.nationality ?? '-';
  String get ethnic => student?.ethnic ?? '-';
  String get race => student?.race ?? '-';
  String get tribe => student?.tribe ?? '-';
  String get religion => student?.religion ?? '-';
  String get maritalStatus => student?.maritalStatus ?? '-';
  String get healthStatus => student?.healthStatus ?? '-';
  String get jobTitle => student?.jobTitle ?? '-';
  String get school => student?.school ?? '-';
  String get studentTypeName {
    final name = student?.studentType?.stdTypeNameLao ?? '';
    return name.isNotEmpty ? name : '-';
  }

  String get studentGroupName {
    final name = student?.studentGroup?.stdGroupName ?? '';
    return name.isNotEmpty
        ? name
        : (student?.studentGroup?.stdGroupCode ?? '-');
  }

  String get program {
    final cur = student?.curriculum;
    if (cur == null) return '-';
    return (cur.curriNameEng != null && cur.curriNameEng!.trim().isNotEmpty)
        ? cur.curriNameEng!.trim()
        : cur.curriNameLao;
  }
}
