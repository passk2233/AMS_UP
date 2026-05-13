import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class ScheduleStudentController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var currentWeek = <DateTime>[].obs;

  final RxList<StudyPlanModel> studyPlans = <StudyPlanModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  late final Dio _dio;
  String _token = '';
  int? _stdGroupId;

  @override
  void onInit() {
    super.onInit();
    _generateWeek(DateTime.now());
    _initDio();
    _loadToken().then((_) => _loadStudentGroupAndFetch());
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

  Future<void> _loadStudentGroupAndFetch() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _loadToken();
      final me = await _dio.get('/auth/me');
      if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
        final u = UserModel.fromJson(me.data);
        _stdGroupId = u.student?.stdGroupId;
      }
      await fetchStudyPlans();
    } on DioException catch (e) {
      debugPrint('ScheduleStudent load profile Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      errorMessage.value = 'Failed to load schedule.';
    } catch (e) {
      debugPrint('ScheduleStudent load profile error: $e');
      errorMessage.value = 'Failed to load schedule.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStudyPlans() async {
    final gid = _stdGroupId;
    if (gid == null) {
      studyPlans.clear();
      errorMessage.value = 'Student group not found.';
      return;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final resp = await _dio.get('/study-plans', queryParameters: {
        'std_group_id': gid,
        'limit': 200,
      });
      final items = _extractList(resp.data);
      studyPlans.assignAll(items.map((j) => StudyPlanModel.fromJson(j)).toList());
    } on DioException catch (e) {
      debugPrint('ScheduleStudent fetchStudyPlans Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      errorMessage.value = 'Failed to load schedule.';
    } finally {
      isLoading.value = false;
    }
  }

  void _generateWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    // Start week on Monday.
    int daysToSubtract = normalized.weekday - DateTime.monday;
    DateTime firstDay = date.subtract(Duration(days: daysToSubtract));
    currentWeek.assignAll(List.generate(7, (i) => firstDay.add(Duration(days: i))));
  }

  void changeWeek(int days) {
    if (currentWeek.isEmpty) {
      _generateWeek(selectedDate.value);
      return;
    }
    final selectedWeekdayIndex = selectedDate.value.weekday - DateTime.monday;
    final nextWeekAnchor = currentWeek.first.add(Duration(days: days));
    _generateWeek(nextWeekAnchor);
    selectedDate.value = currentWeek[(selectedWeekdayIndex).clamp(0, 6)];
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    selectedDate.value = normalized;

    if (currentWeek.isEmpty) {
      _generateWeek(normalized);
      return;
    }
    final inCurrentWeek = currentWeek.any((d) =>
        d.year == normalized.year &&
        d.month == normalized.month &&
        d.day == normalized.day);
    if (!inCurrentWeek) {
      _generateWeek(normalized);
    }
  }

  List<Map<String, dynamic>> get filteredSchedules {
    final palette = <Color>[
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.redAccent,
      Colors.teal,
    ];

    final selectedWeekday = selectedDate.value.weekday;
    final selected = studyPlans.where((p) {
      final planWeekday = _dayOfWeekToWeekday(p.dayOfWeek);
      return planWeekday == selectedWeekday;
    }).toList()
      ..sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

    return List.generate(selected.length, (i) {
      final p = selected[i];
      final subject = p.subject?.nameEng ?? p.subject?.nameLao ?? 'Subject';
      final group = p.studentGroup?.stdGroupName ?? 'Group';
      final teacher = p.teacher?.nameEng ?? p.teacher?.nameLao ?? '-';
      final room = p.room?.roomCode ?? '-';
      final start = _formatTime(p.startTime);
      final end = _formatTime(p.endTime);
      return {
        'date': selectedDate.value,
        'title': subject,
        'subtitle': group,
        'time': '$start - $end',
        'instructor': teacher,
        'location': room,
        'color': palette[i % palette.length],
      };
    });
  }

  String get currentMonthYear => DateFormat('MMMM yyyy').format(selectedDate.value);

  int _dayOfWeekToWeekday(String? rawDay) {
    if (rawDay == null || rawDay.trim().isEmpty) return -1;
    final d = rawDay.trim().toLowerCase();
    switch (d) {
      case 'monday':
      case 'mon':
      case '1':
        return DateTime.monday;
      case 'tuesday':
      case 'tue':
      case '2':
        return DateTime.tuesday;
      case 'wednesday':
      case 'wed':
      case '3':
        return DateTime.wednesday;
      case 'thursday':
      case 'thu':
      case '4':
        return DateTime.thursday;
      case 'friday':
      case 'fri':
      case '5':
        return DateTime.friday;
      case 'saturday':
      case 'sat':
      case '6':
        return DateTime.saturday;
      case 'sunday':
      case 'sun':
      case '0':
      case '7':
        return DateTime.sunday;
      default:
        return -1;
    }
  }

  int _timeToMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    final t = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
    if (match == null) return 0;
    final h = int.tryParse(match.group(1) ?? '') ?? 0;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    return (h * 60) + m;
  }

  String _formatTime(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final t = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
    if (match == null) return t;
    final h = int.tryParse(match.group(1) ?? '') ?? 0;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat('HH:mm').format(dt);
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}