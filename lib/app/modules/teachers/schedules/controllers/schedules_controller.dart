import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../services/api_client.dart';
import '../../../../widgets/widget.dart';
import '../../../data/data_exporter.dart';


class SchedulesController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var currentWeek = <DateTime>[].obs;

  /// 'day' (default) shows just the selected date; 'week' shows all 7 days.
  final RxString viewMode = 'day'.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<StudyPlanModel> schedules = <StudyPlanModel>[].obs;
  final Rx<SemasterModel?> activeSemester = Rx<SemasterModel?>(null);

  Dio get _dio => ApiClient.dio;
  int? _teacherId;

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
      await _loadTeacher();
      if (_teacherId == null) {
        errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
        return;
      }
      await fetchSchedules();
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('Schedules Dio error:\n$detail');

      // 401 is handled centrally by ApiClient (it clears auth + redirects).
      if (errorMessage.value.isEmpty) {
        errorMessage.value = e.response?.statusCode == 401
            ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
            : 'ບໍ່ສາມາດໂຫຼດຕາຕະລາງໄດ້';
      }
    } catch (e) {
      debugPrint('Schedules error: $e');
      if (errorMessage.value.isEmpty) {
        errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຕາຕະລາງໄດ້';
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
          'Schedules semester Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
    } catch (e) {
      debugPrint('Schedules semester error: $e');
    }
  }

  Future<void> _loadTeacher() async {
    final me = await _dio.get('/auth/me');
    final user = (me.statusCode == 200 && me.data is Map<String, dynamic>)
        ? UserModel.fromJson(me.data)
        : null;
    _teacherId = user?.teacherId;
  }

  Future<void> fetchSchedules() async {
    final teacherId = _teacherId;
    if (teacherId == null) {
      errorMessage.value = 'ບໍ່ພົບຂໍ້ມູນອາຈານ';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final query = <String, dynamic>{
        'teacher_id': teacherId,
        'limit': 500,
      };
      final semId = activeSemester.value?.id;
      if (semId != null) query['semaster_id'] = semId;

      final resp = await _dio.get('/study-plans', queryParameters: query);
      final items = _extractList(resp.data);
      var list = items.map((j) => StudyPlanModel.fromJson(j)).toList();

      // Fallback: if backend ignores teacher_id filter, fetch all then filter.
      if (list.isEmpty) {
        final fallbackQuery = <String, dynamic>{'limit': 500};
        if (semId != null) fallbackQuery['semaster_id'] = semId;
        final respAll =
            await _dio.get('/study-plans', queryParameters: fallbackQuery);
        final allItems = _extractList(respAll.data);
        list = allItems
            .map((j) => StudyPlanModel.fromJson(j))
            .where((sp) => sp.teacherId == teacherId)
            .toList();
      }

      if (semId != null) {
        list = list.where((sp) => sp.semasterId == semId).toList();
      }

      list.sort((a, b) {
        final d = _dayOfWeekToWeekday(a.dayOfWeek)
            .compareTo(_dayOfWeekToWeekday(b.dayOfWeek));
        if (d != 0) return d;
        return (a.startTime ?? '').compareTo(b.startTime ?? '');
      });
      schedules.assignAll(list);
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      debugPrint('Schedules Dio error:\n$detail');
      // 401 is handled centrally by ApiClient.
      errorMessage.value = e.response?.statusCode == 401
          ? 'ການເຂົ້າລະບົບບໍ່ຖືກຕ້ອງ (ກະລຸນາ login ໃໝ່)'
          : 'ບໍ່ສາມາດໂຫຼດຕາຕະລາງໄດ້';
    } catch (e) {
      debugPrint('Schedules error: $e');
      errorMessage.value = 'ບໍ່ສາມາດໂຫຼດຕາຕະລາງໄດ້';
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

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
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

    final selectedWeekday = selectedDate.value.weekday;
    final selected = schedules.where((p) {
      final planWeekday = _dayOfWeekToWeekday(p.dayOfWeek);
      return planWeekday == selectedWeekday;
    }).toList()
      ..sort((a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));

    return selected
        .asMap()
        .entries
        .map((e) => _planToMap(e.value, e.key, selectedDate.value))
        .toList();
  }

  /// Schedules grouped by day for the current week. Each entry has a
  /// `dateLabel` (e.g. "ຈັນ 12") and a list of class maps.
  List<Map<String, dynamic>> get weekScheduleByDay {
    if (currentWeek.isEmpty) return const [];
    final dayLabels = <int, String>{
      DateTime.monday: 'ຈັນ',
      DateTime.tuesday: 'ອັງຄານ',
      DateTime.wednesday: 'ພຸດ',
      DateTime.thursday: 'ພະຫັດ',
      DateTime.friday: 'ສຸກ',
      DateTime.saturday: 'ເສົາ',
      DateTime.sunday: 'ອາທິດ',
    };
    final out = <Map<String, dynamic>>[];
    for (final day in currentWeek) {
      if (!isInSemester(day)) continue;
      final plans = schedules
          .where((p) => _dayOfWeekToWeekday(p.dayOfWeek) == day.weekday)
          .toList()
        ..sort((a, b) => _timeToMinutes(a.startTime)
            .compareTo(_timeToMinutes(b.startTime)));
      if (plans.isEmpty) continue;
      out.add({
        'date': day,
        'dateLabel': '${dayLabels[day.weekday] ?? ''} ${day.day}/${day.month}',
        'classes': plans
            .asMap()
            .entries
            .map((e) => _planToMap(e.value, e.key, day))
            .toList(),
      });
    }
    return out;
  }

  // One neutral brand accent for every class card. The prior rainbow reused
  // the closed status colors (amber/emerald/red) decoratively and shipped
  // off-brand purple/teal. See the status-color rule in DESIGN.md.
  static const _palette = <Color>[AppColors.info];

  Map<String, dynamic> _planToMap(StudyPlanModel sp, int index, DateTime day) {
    final subject = sp.subject?.nameLao ?? sp.subject?.nameEng ?? 'ວິຊາ';
    final code = sp.subject?.subjectCode ?? '';
    final room = sp.room?.roomCode ??
        (sp.roomId != null ? 'ຫ້ອງ ${sp.roomId}' : '-');
    final time =
        '${_formatTime(sp.startTime)} - ${_formatTime(sp.endTime)}';
    final group = sp.studentGroup?.stdGroupName ?? '';
    return {
      'date': day,
      'title': '$subject${code.isNotEmpty ? ' ($code)' : ''}',
      'subtitle': group.isNotEmpty ? group : null,
      'time': time,
      'location': room,
      'color': _palette[index % _palette.length],
    };
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
}
