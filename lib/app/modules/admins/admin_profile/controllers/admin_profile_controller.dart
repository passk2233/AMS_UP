import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/auth_storage.dart';
import '../../../../services/fcm_service.dart';
import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';

/// Reactive state owner for [AdminProfileView].
///
/// Loads the signed-in user on init and exposes derived display strings the
/// view can bind directly to. Owns the multi-step logout flow (FCM unsub →
/// local auth clear → redirect to `/auth`).
class AdminProfileController extends GetxController {
  AdminProfileController({AuthProvider? auth})
      : _auth = auth ?? AuthProvider();

  /// Data-access seam for `/auth/*`.
  final AuthProvider _auth;

  /// Currently signed-in admin (loaded from `GET /auth/me`).
  final Rx<UserModel?> user = Rx<UserModel?>(null);

  /// `true` while the profile fetch is in flight.
  final RxBool isLoading = false.obs;

  /// `true` while the logout flow is running.
  final RxBool isLoggingOut = false.obs;

  /// User-facing error message from the last fetch; empty when there is none.
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  /// Force a re-fetch — used by the bottom nav refresher.
  Future<void> refreshData() => fetchProfile();

  /// GET `/auth/me` and populate [user]. 401s are handled centrally by
  /// [ApiClient]; this method only sets a localized error message.
  Future<void> fetchProfile() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _auth.me();
      if (result != null) user.value = result;
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

  /// Confirm with the user, then unregister the device's FCM token, revoke
  /// the refresh token server-side, clear the stored JWT, and redirect to
  /// `/auth`.
  ///
  /// The FCM unsubscribe and the server-side revoke MUST run before
  /// [AuthStorage.clear] because both requests still need the auth token.
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
      await _auth.logout(); // best-effort server-side session revoke
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
