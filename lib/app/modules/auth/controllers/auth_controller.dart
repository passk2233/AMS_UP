import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/app/routes/app_pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final dio = Dio();
      final String apiUrl = '${dotenv.env['API_URL']}/auth/login';
      final response = await dio.post(
        apiUrl,
        data: {'username': username, 'password': password},
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
        final user = data['user'];
        final List<dynamic> roles = user['roles'] ?? [];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        List<String> userRoles = roles.map((role) => role.toString()).toList();
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

        Get.offAllNamed(Routes.HOME);
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
        errorMessage = responseData.length > 100 ? 'Server Error: Please check Ngrok or Backend' : responseData;
      }
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            'Cannot connect to server. Please check your internet or Ngrok URL.';
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
