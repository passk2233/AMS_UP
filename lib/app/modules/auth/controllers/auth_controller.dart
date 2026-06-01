import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_storage.dart';
import '../../../services/fcm_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../data/models/user_model.dart';

/// Reactive state owner for [AuthView].
///
/// Owns the login form's text controllers and `remember me` / `obscure
/// password` toggles, and implements the full sign-in pipeline:
/// 1. Fetch a FCM device token (best-effort).
/// 2. POST `/auth/login` and persist the returned JWT + roles into secure
///    storage.
/// 3. Sync the FCM device with the backend and subscribe role topics.
/// 4. Route to the correct role landing page.
class AuthController extends GetxController {
  /// Username input controller.
  final TextEditingController usernameController = TextEditingController();

  /// Password input controller.
  final TextEditingController passwordController = TextEditingController();

  /// `true` when the password field hides its content (default).
  final RxBool isObscured = true.obs;

  /// `true` when "remember me" is checked — the username will be restored
  /// on next launch.
  final RxBool rememberMe = false.obs;

  /// `true` while [login] is in flight.
  final RxBool isLoading = false.obs;

  static const _savedUsernameKey = 'saved_username';
  static const _rememberUntilKey = 'remember_until';
  static const _rememberDurationDays = 30;

  @override
  void onInit() {
    super.onInit();
    loadSaveUser();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Flip the password-field visibility.
  void toggleObscured() => isObscured.value = !isObscured.value;

  /// Bound to the "remember me" checkbox.
  void toggleRememberMe(bool? value) {
    if (value != null) rememberMe.value = value;
  }

  /// Restore the persisted username (if any) on first build so the user
  /// only needs to re-enter the password.
  Future<void> loadSaveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(_savedUsernameKey);
    if (savedUsername != null && savedUsername.isNotEmpty) {
      usernameController.text = savedUsername;
      rememberMe.value = true;
    }
  }

  /// Run the full sign-in pipeline. Surfaces validation / network errors
  /// via [AppSnackbar] and clears [isLoading] in `finally`.
  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      AppSnackbar.warning('ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້ ແລະ ລະຫັດຜ່ານ');
      return;
    }

    isLoading.value = true;
    try {
      final deviceToken = await _safeDeviceToken();

      // The shared ApiClient skips the auth header on /auth/login, so this
      // call goes out unauthenticated even if a stale token is sitting in
      // secure storage.
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'device_token': deviceToken,
          'platform': _platformId(),
        },
      );
      if (response.statusCode != 200) return;

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);
      final roles = user.roles ?? const <String>[];

      // Token + roles live in Keychain/Keystore-backed secure storage —
      // SharedPreferences is plain XML in the app sandbox and is readable
      // on rooted devices.
      await AuthStorage.writeToken(token);
      await AuthStorage.writeRoles(roles);
      await _persistRememberMe(username);

      AppSnackbar.success('ເຂົ້າສູ່ລະບົບສຳເລັດ');

      // Push notification setup — fire-and-forget so it doesn't delay the
      // home redirect. Belt-and-braces in case getToken() at the top of
      // this method returned null.
      unawaited(FCMService.syncTokenIfNeeded());
      unawaited(FCMService.subscribeRoleTopics(roles));

      final destination = _routeForRoles(roles);
      if (destination == null) {
        AppSnackbar.error('ບໍ່ສາມາດກວດສອບສິດເຂົ້າໃຊ້ໄດ້');
        return;
      }
      Get.offAllNamed(destination);
    } on DioException catch (e) {
      AppSnackbar.error(_mapDioError(e), title: 'ເຂົ້າສູ່ລະບົບລົ້ມເຫລວ');
    } finally {
      isLoading.value = false;
    }
  }

  /// Try to fetch the device's FCM token; never throws. Returning `null`
  /// just means the backend will not persist a device row for this login.
  Future<String?> _safeDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Persist or clear the "remember me" prefs.
  Future<void> _persistRememberMe(String username) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe.value) {
      final expires = DateTime.now()
          .add(const Duration(days: _rememberDurationDays))
          .millisecondsSinceEpoch;
      await prefs.setString(_savedUsernameKey, username);
      await prefs.setInt(_rememberUntilKey, expires);
    } else {
      await prefs.remove(_savedUsernameKey);
      await prefs.remove(_rememberUntilKey);
    }
  }

  /// Short platform identifier sent to the backend so it can fan out FCM
  /// payloads with the correct schema (`apns` vs `gcm`).
  String _platformId() {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    if (GetPlatform.isWeb) return 'web';
    return 'unknown';
  }

  /// Pick the landing page for the highest-priority role the user has, or
  /// `null` when no recognized role is present.
  String? _routeForRoles(List<String> roles) {
    final lower = roles.map((r) => r.toLowerCase()).toSet();
    if (lower.contains('administrator') || lower.contains('admin')) {
      return Routes.ADMIN_HOME;
    }
    if (lower.contains('teacher')) return Routes.TEACHER_HOME;
    if (lower.contains('student')) return Routes.HOME_STUDENT;
    return null;
  }

  /// Map a [DioException] to a user-facing error message.
  String _mapDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final body = response.data;
      if (body is Map<String, dynamic> && body['error'] != null) {
        return body['error'].toString();
      }
      if (body is String) {
        return body.length > 100 ? 'Server Error: Please check Backend' : body;
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your internet.';
      case DioExceptionType.connectionTimeout:
        return 'Cannot connect to server. Please check your internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
