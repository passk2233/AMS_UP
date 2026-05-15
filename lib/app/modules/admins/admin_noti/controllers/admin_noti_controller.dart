import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class AdminNotiController extends GetxController {
  var selectedFilterIndex = 0.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    fetchNotifications();
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

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadToken();
      final resp = await _dio.get('/notifications', queryParameters: {'limit': 100});
      final items = _extractList(resp.data);
      notifications.assignAll(items.map((j) => NotificationModel.fromJson(j)).toList());
    } on DioException catch (e) {
      debugPrint('AdminNoti Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        errorMessage.value = 'Session expired. Please login again.';
        Get.offAllNamed('/auth');
        return;
      }
      errorMessage.value = 'Failed to load notifications.';
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredNotifications {
    final all = notifications.map(_toViewItem).toList();
    if (selectedFilterIndex.value == 0) return all;

    final category = selectedFilterIndex.value == 1 ? "Academic" : "Room Booking";
    return all.where((n) => n['category'] == category).toList();
  }

  Map<String, dynamic> _toViewItem(NotificationModel n) {
    final typeRaw = (n.type ?? '').toLowerCase();
    final isUrgent = typeRaw == 'urgent';
    final category = typeRaw.contains('booking') ? 'Room Booking' : 'Academic';

    final ts = n.createdAt;
    final time = ts == null ? '-' : DateFormat('yyyy-MM-dd HH:mm').format(ts.toLocal());

    if (isUrgent) {
      return {
        'type': 'Urgent',
        'category': category,
        'title': n.title,
        'sub': n.message,
        'status': 'Urgent',
        'time': time,
      };
    }

    return {
      'type': 'Normal',
      'category': category,
      'title': n.title,
      'desc': n.message,
      'time': time,
    };
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
