import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/app/modules/data/models/user_model.dart';


class AuthController extends GetxController {
  // Controller for receive user input
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // reactive variables for real-time update display
  final isObscured = true.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;

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

  void toggleObscured() {
    isObscured.value = !isObscured.value;
  }

  void toggleRememberMe(bool? value) {
    if (value != null) {
      rememberMe.value = value;
    }
  }

  Future<void> loadSaveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    if (savedUsername != null && savedUsername.isNotEmpty) {
      usernameController.text = savedUsername;
      rememberMe.value = true;
    }
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    try {
      isLoading.value = true;

      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Failed to get FCM token: $e");
      }

      String platform = 'unknown';
      if (GetPlatform.isAndroid) {
        platform = 'android';
      } else if (GetPlatform.isIOS) {
        platform = 'ios';
      } else if (GetPlatform.isWeb) {
        platform = 'web';
      }

      final dio = Dio();
      final String apiUrl = '${dotenv.env['API_URL']}/auth/login';
      final response = await dio.post(
        apiUrl,
        data: {
          'username': username,
          'password': password,
          'device_token': deviceToken,
          'platform': platform,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );
      if (response.statusCode == 200) {
       final data = response.data;
        final token = data['token'];
        final userModel = UserModel.fromJson(data['user']);
        final List<String> userRoles = userModel.roles ?? [];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setStringList('roles', userRoles);
        
        if (rememberMe.value) {
          await prefs.setString('saved_username', username);
        } else {
          await prefs.remove('saved_username');
        }
        Get.snackbar(
          'Success',
          'Login successful',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        bool isAdmin = userRoles.any((role) => role.toLowerCase() == 'administrator' || role.toLowerCase() == 'admin');
        bool isTeacher = userRoles.any((role) => role.toLowerCase() == 'teacher');
        bool isStudent = userRoles.any((role) => role.toLowerCase() == 'student');

        if (isAdmin) {
          Get.offAllNamed(Routes.ADMIN_HOME);
        } else if (isTeacher) {
          Get.offAllNamed(Routes.TEACHER_HOME);
        } else if (isStudent) {
          Get.offAllNamed(Routes.STUDENT_HOME);
        } else {
          Get.snackbar(
            'Error',
            'Role not recognized',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Something went wrong. Please try again.';
      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('error')) {
          errorMessage = responseData['error'];
        }
      else if (responseData is String){
        errorMessage = responseData.length > 100 ? 'Server Error: Please check Backend' : responseData;
      }
      } else if (e.type == DioExceptionType.connectionError
          ) {
        errorMessage =
            'Cannot connect to server. Please check your internet or Ngrok URL.';
      } else if(e.type == DioExceptionType.connectionTimeout){
         errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      }
      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
