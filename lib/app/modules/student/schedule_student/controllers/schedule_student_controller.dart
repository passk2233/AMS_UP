import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/services/api_client.dart';
import 'package:frontend/app/widgets/app_colors.dart';
import 'package:frontend/app/widgets/app_dialogs.dart';

class ScheduleStudentController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var currentWeek = <DateTime>[].obs;

  final RxList<StudyPlanModel> studyPlans = <StudyPlanModel>[].obs;
  final Rx<SemasterModel?> activeSemester = Rx<SemasterModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Dio get _dio => ApiClient.dio;
  int? _stdGroupId;

  @override
  void onInit() {
    super.onInit();
    _generateWeek(DateTime.now());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loadActiveSemester();
      _initSelectionForSemester();
      await _loadStudentGroup();
      await fetchStudyPlans();
    } on DioException catch (e) {
      debugPrint(
          'ScheduleStudent bootstrap Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      if (errorMessage.value.isEmpty) {
        errorMessage.value = 'Failed to load schedule.';
      }
    } catch (e) {
      debugPrint('ScheduleStudent bootstrap error: $e');
      if (errorMessage.value.isEmpty) {
        errorMessage.value = 'Failed to load schedule.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadActiveSemester() async {
    try {
      final resp = await _dio.get('/semasters', queryParameters: {'limit': 20});
      final items = _extractList(resp.data);
      final all = items.map((j) => SemasterModel.fromJson(j)).toList();
      if (all.isEmpty) return;

      final now = DateTime.now();
      final containing = all.where((s) =>
          s.startDate != null &&
          s.endDate != null &&
          !now.isBefore(_dateOnly(s.startDate!)) &&
          !now.isAfter(_dateOnly(s.endDate!).add(const Duration(days: 1))));
      if (containing.isNotEmpty) {
        activeSemester.value = containing.first;
        return;
      }

      final active = all.where((s) => s.status == 1);
      activeSemester.value = active.isNotEmpty ? active.first : all.first;
    } on DioException catch (e) {
      debugPrint(
          'ScheduleStudent semester Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
    } catch (e) {
      debugPrint('ScheduleStudent semester error: $e');
    }
  }

  Future<void> _loadStudentGroup() async {
    final me = await _dio.get('/auth/me');
    if (me.statusCode == 200 && me.data is Map<String, dynamic>) {
      final u = UserModel.fromJson(me.data);
      _stdGroupId = u.student?.stdGroupId;
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
      final query = <String, dynamic>{
        'std_group_id': gid,
        'limit': 200,
      };
      final semId = activeSemester.value?.id;
      if (semId != null) query['semaster_id'] = semId;
      final resp = await _dio.get('/study-plans', queryParameters: query);
      final items = _extractList(resp.data);
      var list = items.map((j) => StudyPlanModel.fromJson(j)).toList();
      if (semId != null) {
        list = list.where((sp) => sp.semasterId == semId).toList();
      }
      studyPlans.assignAll(list);
    } on DioException catch (e) {
      debugPrint(
          'ScheduleStudent fetchStudyPlans Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      errorMessage.value = 'Failed to load schedule.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() => _bootstrap();

  void _initSelectionForSemester() {
    final sem = activeSemester.value;
    final start = sem?.startDate;
    final end = sem?.endDate;
    final today = _dateOnly(DateTime.now());
    DateTime initial = today;
    if (start != null && today.isBefore(_dateOnly(start))) {
      initial = _dateOnly(start);
    } else if (end != null && today.isAfter(_dateOnly(end))) {
      initial = _dateOnly(end);
    }
    selectedDate.value = initial;
    _generateWeek(initial);
  }

  void _generateWeek(DateTime date) {
    final normalized = _dateOnly(date);
    // Start week on Sunday: Sunday.weekday=7, 7%7=0 so no subtraction.
    int daysToSubtract = normalized.weekday % 7;
    DateTime firstDay = normalized.subtract(Duration(days: daysToSubtract));
    currentWeek
        .assignAll(List.generate(7, (i) => firstDay.add(Duration(days: i))));
  }

  void changeWeek(int days) {
    if (currentWeek.isEmpty) {
      _generateWeek(selectedDate.value);
      return;
    }
    if (days < 0 && !canGoPrevWeek) return;
    if (days > 0 && !canGoNextWeek) return;

    final selectedWeekdayIndex = selectedDate.value.weekday % 7;
    final nextWeekAnchor = currentWeek.first.add(Duration(days: days));
    _generateWeek(nextWeekAnchor);
    final candidate = currentWeek[selectedWeekdayIndex.clamp(0, 6)];
    selectedDate.value = _clampToSemester(candidate);
  }

  void selectDate(DateTime date) {
    final normalized = _clampToSemester(_dateOnly(date));
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

  bool isInSemester(DateTime date) {
    final sem = activeSemester.value;
    final start = sem?.startDate;
    final end = sem?.endDate;
    final d = _dateOnly(date);
    if (start != null && d.isBefore(_dateOnly(start))) return false;
    if (end != null && d.isAfter(_dateOnly(end))) return false;
    return true;
  }

  bool get canGoPrevWeek {
    final sem = activeSemester.value;
    final start = sem?.startDate;
    if (start == null || currentWeek.isEmpty) return true;
    return currentWeek.first.isAfter(_dateOnly(start));
  }

  bool get canGoNextWeek {
    final sem = activeSemester.value;
    final end = sem?.endDate;
    if (end == null || currentWeek.isEmpty) return true;
    return currentWeek.last.isBefore(_dateOnly(end));
  }

  DateTime _clampToSemester(DateTime date) {
    final sem = activeSemester.value;
    final start = sem?.startDate;
    final end = sem?.endDate;
    final d = _dateOnly(date);
    if (start != null && d.isBefore(_dateOnly(start))) return _dateOnly(start);
    if (end != null && d.isAfter(_dateOnly(end))) return _dateOnly(end);
    return d;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<Map<String, dynamic>> get filteredSchedules {
    if (!isInSemester(selectedDate.value)) return const [];

    // Class cards use one neutral brand accent. The prior rainbow tinted
    // cards in the reserved status colors (amber/emerald/red) and off-brand
    // purple, which collided with the closed status vocabulary. See DESIGN.md.
    final palette = <Color>[AppColors.info];

    final selectedWeekday = selectedDate.value.weekday;
    final selected = studyPlans.where((p) {
      final planWeekday = _dayOfWeekToWeekday(p.dayOfWeek);
      return planWeekday == selectedWeekday;
    }).toList()
      ..sort((a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

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
        // Full record so the detail sheet can surface subject / teacher / room.
        'plan': p,
      };
    });
  }

  String get currentMonthYear =>
      DateFormat('MMMM yyyy').format(selectedDate.value);

  String get semesterLabel {
    final s = activeSemester.value;
    if (s == null) return '';
    return 'ພາກຮຽນ ${s.term}/${s.year}';
  }

  String get semesterDateRange {
    final s = activeSemester.value;
    if (s == null || s.startDate == null || s.endDate == null) return '';
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(s.startDate!)} - ${fmt.format(s.endDate!)}';
  }

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
