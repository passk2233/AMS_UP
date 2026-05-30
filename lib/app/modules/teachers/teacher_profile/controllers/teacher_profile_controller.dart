import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/api_client.dart';
import '../../../../services/auth_storage.dart';
import '../../../../services/fcm_service.dart';
import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// Reactive state owner for [TeacherProfileView].
///
/// Loads the signed-in user on init and exposes derived display getters
/// the view can bind directly to. Owns the multi-step logout flow
/// (FCM unsub → local auth clear → redirect to `/auth`).
class TeacherProfileController extends GetxController {
  /// Currently signed-in teacher (loaded from `GET /auth/me`).
  final Rx<UserModel?> user = Rx<UserModel?>(null);

  /// `true` while the profile fetch is in flight.
  final RxBool isLoading = false.obs;

  /// `true` while the logout flow is running.
  final RxBool isLoggingOut = false.obs;

  /// Last user-facing error from the load path; empty when none.
  final RxString errorMessage = ''.obs;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  /// Refresh handler — bound to the bottom-nav tab refresher.
  Future<void> refreshData() => fetchProfile();

  /// GET `/auth/me` and populate [user]. 401s are handled centrally by
  /// [ApiClient]; this method only sets a localized error message.
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
        'fetchProfile Dio error:\n${AppDialogs.buildDioErrorDetail(e)}',
      );
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
          : 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໂປຣໄຟລ໌ໄດ້';
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirm with the user, then unregister the device's FCM token, clear
  /// the stored JWT, and redirect to `/auth`.
  ///
  /// The FCM unsubscribe MUST run before [AuthStorage.clear] because the
  /// DELETE request still needs the auth token.
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

  // ─────────────────────────────────────────────────── display getters ──

  /// Username displayed in the profile header.
  String get displayName => user.value?.username ?? '';

  /// Email displayed in the contact section.
  String get displayEmail => user.value?.email ?? '-';

  /// Comma-joined role names.
  String get displayRoles {
    final roles = user.value?.roles;
    if (roles == null || roles.isEmpty) return '-';
    return roles.join(', ');
  }

  /// Lao label for the `users.active` flag.
  String get accountStatus {
    final active = user.value?.active;
    if (active == null) return '-';
    return active == 1 ? 'ເປີດໃຊ້ງານ' : 'ປິດໃຊ້ງານ';
  }

  /// `d/m/yyyy`-formatted member-since date.
  String get memberSince {
    final d = user.value?.createdAt;
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }
}
