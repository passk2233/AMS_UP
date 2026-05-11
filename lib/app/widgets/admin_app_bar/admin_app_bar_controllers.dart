import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/data/data_exporter.dart';

class AdminAppBarControllers extends GetxController {
  final RxString semester = ''.obs;
  final RxBool semesterLoading = true.obs;
  final RxInt pendingRequestCount = 0.obs;
  late final Dio _dio;
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    _loadToken().then((_) {
      _fetchActiveSemester();
      _fetchPendingRequests();
    });
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

  Future<void> _fetchActiveSemester() async {
    semesterLoading.value = true;
    try {
      final response = await _dio.get('/semasters', queryParameters: {
        'limit': 10,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }

        final allSemesters = items.map((json) => SemasterModel.fromJson(json)).toList();
        final now = DateTime.now();

        // 1. Try to find semester matching current time
        final currentSemesters = allSemesters.where((s) {
          if (s.startDate != null && s.endDate != null) {
            return now.compareTo(s.startDate!) >= 0 && now.compareTo(s.endDate!) <= 0;
          }
          return false;
        }).toList();

        if (currentSemesters.isNotEmpty) {
          final s = currentSemesters.first;
          semester.value = '${s.semasterCode} (${s.year})';
        } else {
          // 2. Fallback to active semester (status == 1)
          final activeSemesters = allSemesters.where((s) => s.status == 1).toList();
          if (activeSemesters.isNotEmpty) {
            final s = activeSemesters.first;
            semester.value = '${s.semasterCode} (${s.year})';
          } else if (allSemesters.isNotEmpty) {
            // 3. Fallback to latest semester
            final s = allSemesters.first;
            semester.value = '${s.semasterCode} (${s.year})';
          } else {
            semester.value = 'No active semester';
          }
        }
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch semester: ${e.message}');
      semester.value = 'Semester';
    } finally {
      semesterLoading.value = false;
    }
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final response = await _dio.get('/room-bookings', queryParameters: {
        'limit': 100,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }

        final pending = items
            .map((json) => RoomBookingModel.fromJson(json))
            .where((b) => b.status == 'pending')
            .length;

        pendingRequestCount.value = pending;
      }
    } on DioException catch (e) {
      debugPrint('Failed to fetch pending requests: ${e.message}');
    }
  }

  /// Call this to refresh both semester and pending count (e.g. on tab switch).
  Future<void> refreshData() async {
    await Future.wait([
      _fetchActiveSemester(),
      _fetchPendingRequests(),
    ]);
  }
}
