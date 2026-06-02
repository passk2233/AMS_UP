import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import '../../../../services/api_client.dart';
import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../../widgets/app_spacing.dart';
import '../../../data/data_exporter.dart';

/// Audience identifier accepted by the backend's `audience` parameter.
abstract class AnnouncementAudience {
  /// 0 — every active user (students + teachers).
  static const int all = 0;

  /// 1 — students only, optionally filtered by department / group / type /
  /// year.
  static const int students = 1;

  /// 2 — teachers only, optionally filtered by department.
  static const int teachers = 2;

  /// 3 — a single student looked up by primary key via [foundStudent].
  static const int individual = 3;
}

/// Sort modes for [AnnouncementController.filteredNotifications] used by the
/// history page.
abstract class AnnouncementSortMode {
  /// 0 — newest first (default).
  static const int newest = 0;

  /// 1 — oldest first.
  static const int oldest = 1;

  /// 2 — title alphabetical (A → Z).
  static const int titleAZ = 2;
}

/// Reactive state owner for the admin "Announcements" tab and its history
/// sub-screen.
///
/// Responsibilities:
/// - Compose form state (title, message, audience selector, filters).
/// - Reference-data fetches (departments, student groups, student types).
/// - Individual-student lookup for [AnnouncementAudience.individual].
/// - Send / delete / edit / resend notification flows.
/// - Paginated, search-able, filterable history list.
class AnnouncementController extends GetxController {
  /// Compose form — notification title.
  final TextEditingController titleCtrl = TextEditingController();

  /// Compose form — notification body / message.
  final TextEditingController messageCtrl = TextEditingController();

  /// Compose form — student ID typed into the individual lookup field.
  final TextEditingController individualIdCtrl = TextEditingController();

  /// Edit dialog — title field, reused via [_EditNotificationDialog].
  final TextEditingController editTitleCtrl = TextEditingController();

  /// Edit dialog — message field, reused via [_EditNotificationDialog].
  final TextEditingController editMessageCtrl = TextEditingController();

  /// History page — search field controller.
  final TextEditingController searchHistoryCtrl = TextEditingController();

  /// Active audience tab — see [AnnouncementAudience].
  final RxInt selectedAudience = AnnouncementAudience.all.obs;

  /// Display labels for each [AnnouncementAudience], in index order.
  final List<String> audienceLabels = const [
    'ທັງໝົດ',
    'ນັກສຶກສາ',
    'ອາຈານ',
    'ບຸກຄົນສະເພາະ',
  ];

  /// Departments fetched from `/departments` and used by the dropdowns.
  final RxList<DepartmentModel> departments = <DepartmentModel>[].obs;

  /// Currently selected department filter, or `null` for "all".
  final Rx<DepartmentModel?> selectedDepartment = Rx<DepartmentModel?>(null);

  /// Student groups fetched from `/student-groups`.
  final RxList<StudentGroupModel> studentGroups = <StudentGroupModel>[].obs;

  /// Currently selected student group, or `null` for "all".
  final Rx<StudentGroupModel?> selectedStudentGroup =
      Rx<StudentGroupModel?>(null);

  /// Student types fetched from `/student-types`.
  final RxList<StudentTypeModel> studentTypes = <StudentTypeModel>[].obs;

  /// Currently selected student type, or `null` for "all".
  final Rx<StudentTypeModel?> selectedStudentType =
      Rx<StudentTypeModel?>(null);

  /// Year-level filter index — 0 = all years, 1..4 = specific year.
  final RxInt selectedYear = 0.obs;

  /// Display labels for [selectedYear].
  final List<String> yearLabels = const [
    'ທຸກຊັ້ນປີ',
    'ປີ 1',
    'ປີ 2',
    'ປີ 3',
    'ປີ 4',
  ];

  /// Most recent successful result of [searchStudentById]. `null` when the
  /// search field is empty or the last lookup failed.
  final Rx<StudentModel?> foundStudent = Rx<StudentModel?>(null);

  /// `true` while [searchStudentById] is in flight.
  final RxBool isSearching = false.obs;

  /// `true` while [sendNotification] / [resendNotification] are in flight.
  final RxBool isSending = false.obs;

  /// `true` while the initial notification-history fetch is in flight.
  final RxBool isLoading = false.obs;

  /// `true` while [_refreshEstimatedReach] is in flight.
  final RxBool isEstimatingReach = false.obs;

  /// Estimated number of recipients for the current audience configuration.
  /// `null` when not yet estimated or the estimate call failed.
  final RxnInt estimatedReach = RxnInt();

  /// `true` while [editNotification] is awaiting the backend update.
  final RxBool isEditing = false.obs;

  /// Raw notification history list (used by the history view).
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  /// User-facing error from the last history fetch; empty when none.
  final RxString historyError = ''.obs;

  /// `true` when the history sub-screen is showing instead of the composer.
  final RxBool showHistory = false.obs;

  /// History page — current search needle.
  final RxString historySearch = ''.obs;

  /// History page — active sort mode (see [AnnouncementSortMode]).
  final RxInt historySortMode = AnnouncementSortMode.newest.obs;

  /// History page — active type filter, empty string for "all".
  final RxString historyFilterType = ''.obs;

  /// Filtered + sorted projection of [notifications] for the history list.
  final RxList<NotificationModel> filteredNotifications =
      <NotificationModel>[].obs;

  /// `true` while a "load more" page is being fetched in the background.
  final RxBool isLoadingMore = false.obs;

  /// `true` while the history fetcher might still have more pages.
  final RxBool hasMore = true.obs;

  static const int _pageSize = 20;
  int _currentPage = 1;

  Dio get _dio => ApiClient.dio;

  @override
  void onInit() {
    super.onInit();
    fetchDepartments();
    fetchStudentGroups();
    fetchStudentTypes();
    fetchNotifications();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    messageCtrl.dispose();
    individualIdCtrl.dispose();
    editTitleCtrl.dispose();
    editMessageCtrl.dispose();
    searchHistoryCtrl.dispose();
    super.onClose();
  }

  // ───────────────────────────────────────────── reference data ──

  /// GET `/departments` and populate [departments].
  Future<void> fetchDepartments() => _fetchInto<DepartmentModel>(
        path: '/departments',
        queryParameters: const {'limit': 50},
        parse: DepartmentModel.fromJson,
        target: departments,
        label: 'fetchDepartments',
      );

  /// GET `/student-groups` and populate [studentGroups].
  Future<void> fetchStudentGroups() => _fetchInto<StudentGroupModel>(
        path: '/student-groups',
        queryParameters: const {'limit': 100},
        parse: StudentGroupModel.fromJson,
        target: studentGroups,
        label: 'fetchStudentGroups',
      );

  /// GET `/student-types` and populate [studentTypes].
  Future<void> fetchStudentTypes() => _fetchInto<StudentTypeModel>(
        path: '/student-types',
        parse: StudentTypeModel.fromJson,
        target: studentTypes,
        label: 'fetchStudentTypes',
      );

  Future<void> _fetchInto<T>({
    required String path,
    required T Function(Map<String, dynamic>) parse,
    required RxList<T> target,
    required String label,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (response.statusCode != 200) return;
      target.assignAll(
        _extractList(response.data)
            .map((j) => parse(j as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      debugPrint('$label error: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────── history fetch ──

  /// (Re)fetch the first page of history and reset pagination state.
  Future<void> fetchNotifications() async {
    isLoading.value = true;
    historyError.value = '';
    _currentPage = 1;
    hasMore.value = true;
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'limit': _pageSize, 'page': _currentPage},
      );
      if (response.statusCode != 200) return;

      final parsed = _extractList(response.data)
          .map((j) => NotificationModel.fromJson(j))
          .toList();
      notifications.assignAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
      _applyHistoryFilters();
    } on DioException catch (e) {
      debugPrint('fetchNotifications error: ${e.message}');
      historyError.value = e.type == DioExceptionType.connectionError
          ? 'ບໍ່ສາມາດເຊື່ອມຕໍ່ກັບເຊີບເວີ.'
          : 'ບໍ່ສາມາດໂຫຼດປະຫວັດການແຈ້ງເຕືອນໄດ້.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch the next page of notifications and append on success. No-op when
  /// already loading or when the previous page returned fewer than
  /// [_pageSize] items.
  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'limit': _pageSize, 'page': nextPage},
      );
      if (response.statusCode != 200) return;

      final parsed = _extractList(response.data)
          .map((j) => NotificationModel.fromJson(j))
          .toList();
      if (parsed.isEmpty) {
        hasMore.value = false;
      } else {
        notifications.addAll(parsed);
        _currentPage = nextPage;
        hasMore.value = parsed.length >= _pageSize;
        _applyHistoryFilters();
      }
    } on DioException catch (e) {
      debugPrint('loadMoreNotifications error: ${e.message}');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ──────────────────────────────────── individual student lookup ──

  /// Look up a single student by ID typed into [individualIdCtrl]. Updates
  /// [foundStudent] on success; clears it (and surfaces a warning) on 404.
  Future<void> searchStudentById() async {
    final idText = individualIdCtrl.text.trim();
    if (idText.isEmpty) {
      foundStudent.value = null;
      return;
    }

    final id = int.tryParse(idText);
    if (id == null) {
      AppDialogs.showWarning(
        title: 'ID ບໍ່ຖືກຕ້ອງ',
        message: 'ກະລຸນາໃສ່ ID ເປັນຕົວເລກ.',
      );
      return;
    }

    isSearching.value = true;
    try {
      final response = await _dio.get('/students/$id');
      if (response.statusCode != 200) return;
      foundStudent.value = _parseStudent(response.data);
    } on DioException catch (e) {
      foundStudent.value = null;
      if (e.response?.statusCode == 404) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບນັກສຶກສາ',
          message: 'ບໍ່ພົບນັກສຶກສາ ID: $id ໃນລະບົບ.',
        );
      } else {
        AppDialogs.showError(
          title: 'ຄົ້ນຫາລົ້ມເຫຼວ',
          message: 'ບໍ່ສາມາດຄົ້ນຫານັກສຶກສາໄດ້.',
          detail: AppDialogs.buildDioErrorDetail(e),
        );
      }
    } finally {
      isSearching.value = false;
    }
  }

  StudentModel? _parseStudent(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return StudentModel.fromJson(inner);
    return StudentModel.fromJson(data);
  }

  // ─────────────────────────────────────────────── reach estimate ──

  /// Estimate how many users the current audience configuration matches.
  ///
  /// Prefers the backend's `/notifications/estimate-reach` endpoint (a
  /// single COUNT(*)). Falls back to counting paginated lists only when the
  /// endpoint is missing (404/405). Network failures leave [estimatedReach]
  /// at `null` so the UI can render '?'.
  Future<void> _refreshEstimatedReach() async {
    isEstimatingReach.value = true;
    estimatedReach.value = null;
    try {
      if (selectedAudience.value == AnnouncementAudience.individual) {
        estimatedReach.value = foundStudent.value == null ? 0 : 1;
        return;
      }

      final params = <String, dynamic>{'audience': _audienceCode()};
      params.addAll(_buildFilters());

      try {
        final resp = await _dio.get(
          '/notifications/estimate-reach',
          queryParameters: params,
        );
        final count = _extractReachCount(resp.data);
        if (count != null) {
          estimatedReach.value = count;
          return;
        }
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code != 404 && code != 405) rethrow;
      }

      estimatedReach.value = await _countByPaginatedFallback();
    } catch (e) {
      debugPrint('reach estimate error: $e');
    } finally {
      isEstimatingReach.value = false;
    }
  }

  int? _extractReachCount(dynamic data) {
    if (data is int) return data;
    if (data is Map) {
      final raw = data['count'] ?? data['total'] ?? data['data'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
    }
    return null;
  }

  Future<int> _countByPaginatedFallback() async {
    var total = 0;
    final audience = selectedAudience.value;
    if (audience == AnnouncementAudience.all ||
        audience == AnnouncementAudience.students) {
      final p = <String, dynamic>{'limit': 5000, ..._buildFilters()};
      final resp = await _dio.get('/students', queryParameters: p);
      total += _extractList(resp.data).length;
    }
    if (audience == AnnouncementAudience.all ||
        audience == AnnouncementAudience.teachers) {
      final p = <String, dynamic>{'limit': 5000};
      final deptId = selectedDepartment.value?.id;
      if (deptId != null) p['dept_id'] = deptId;
      final resp = await _dio.get('/teachers', queryParameters: p);
      total += _extractList(resp.data).length;
    }
    return total;
  }

  // ────────────────────────────────────────── send / delete flow ──

  /// Validate the compose form, show a confirmation dialog with reach
  /// estimate, then POST `/notifications`. Surfaces success / failure via
  /// [AppDialogs].
  Future<void> sendNotification() async {
    if (titleCtrl.text.trim().isEmpty) {
      AppDialogs.showWarning(
        title: 'ກະລຸນາໃສ່ຫົວຂໍ້',
        message: 'ຫົວຂໍ້ການແຈ້ງເຕືອນບໍ່ສາມາດເປົ່າວ່າງໄດ້.',
      );
      return;
    }
    if (messageCtrl.text.trim().isEmpty) {
      AppDialogs.showWarning(
        title: 'ກະລຸນາໃສ່ເນື້ອຫາ',
        message: 'ເນື້ອຫາການແຈ້ງເຕືອນບໍ່ສາມາດເປົ່າວ່າງໄດ້.',
      );
      return;
    }
    if (selectedAudience.value == AnnouncementAudience.individual &&
        foundStudent.value == null) {
      AppDialogs.showWarning(
        title: 'ຍັງບໍ່ໄດ້ເລືອກບຸກຄົນ',
        message: 'ກະລຸນາຄົ້ນຫາ ແລະ ຢືນຢັນນັກສຶກສາກ່ອນ.',
      );
      return;
    }

    await _refreshEstimatedReach();
    final confirmed = await Get.dialog<bool>(
      _SendConfirmationDialog(controller: this),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    isSending.value = true;
    try {
      final response = await _dio.post(
        '/notifications',
        queryParameters: _buildSendQuery(),
        data: {
          'title': titleCtrl.text.trim(),
          'message': messageCtrl.text.trim(),
          'type': buildNotificationType(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        fetchNotifications();
        AppDialogs.showSuccess(
          title: 'ສົ່ງສຳເລັດ',
          message: 'ການແຈ້ງເຕືອນໄດ້ຖືກສົ່ງອອກແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ສົ່ງລົ້ມເຫຼວ', e,
          fallback: 'ບໍ່ສາມາດສົ່ງການແຈ້ງເຕືອນໄດ້.');
    } finally {
      isSending.value = false;
    }
  }

  /// Delete a notification after a confirmation dialog. Removes the
  /// notification from local state immediately on success.
  Future<void> deleteNotification(int notiId) async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ລຶບການແຈ້ງເຕືອນ',
      message: 'ທ່ານຕ້ອງການລຶບການແຈ້ງເຕືອນນີ້ແທ້ບໍ?',
      confirmText: 'ລຶບ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: AppColors.rejectRed,
    );
    if (confirmed != true) return;

    try {
      await _dio.delete('/notifications/$notiId');
      notifications.removeWhere((n) => n.notiId == notiId);
      _applyHistoryFilters();
      AppDialogs.showSuccess(
        title: 'ລຶບສຳເລັດ',
        message: 'ການແຈ້ງເຕືອນໄດ້ຖືກລຶບແລ້ວ.',
      );
    } on DioException catch (e) {
      _showDioError('ລຶບລົ້ມເຫຼວ', e,
          fallback: 'ບໍ່ສາມາດລຶບການແຈ້ງເຕືອນໄດ້.');
    }
  }

  /// Open the edit dialog seeded with [noti] and, on confirm, PUT (or
  /// fall back to delete+POST when the route is missing) the new values.
  Future<void> editNotification(NotificationModel noti) async {
    editTitleCtrl.text = noti.title;
    editMessageCtrl.text = noti.message;

    final confirmed = await Get.dialog<bool>(
      _EditNotificationDialog(controller: this),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    isEditing.value = true;
    try {
      final body = {
        'title': editTitleCtrl.text.trim(),
        'message': editMessageCtrl.text.trim(),
        'type': noti.type ?? '',
      };

      Response? response;
      try {
        response = await _dio.put('/notifications/${noti.notiId}', data: body);
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) {
          await _dio.delete('/notifications/${noti.notiId}');
          response = await _dio.post('/notifications', data: body);
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchNotifications();
        _applyHistoryFilters();
        AppDialogs.showSuccess(
          title: 'ແກ້ໄຂສຳເລັດ',
          message: 'ການແຈ້ງເຕືອນໄດ້ຖືກອັບເດດແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ແກ້ໄຂລົ້ມເຫຼວ', e,
          fallback: 'ບໍ່ສາມາດແກ້ໄຂການແຈ້ງເຕືອນໄດ້.');
    } finally {
      isEditing.value = false;
    }
  }

  /// Re-send an existing notification's title/message/type without changes.
  Future<void> resendNotification(NotificationModel noti) async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ສົ່ງຊ້ຳ',
      message: 'ຕ້ອງການສົ່ງການແຈ້ງເຕືອນ\n"${noti.title}"\nອີກຄັ້ງບໍ?',
      confirmText: 'ສົ່ງຊ້ຳ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: AppColors.laoBlue,
    );
    if (confirmed != true) return;

    isSending.value = true;
    try {
      final response = await _dio.post('/notifications', data: {
        'title': noti.title,
        'message': noti.message,
        'type': noti.type ?? '',
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchNotifications();
        _applyHistoryFilters();
        AppDialogs.showSuccess(
          title: 'ສົ່ງຊ້ຳສຳເລັດ',
          message: 'ການແຈ້ງເຕືອນໄດ້ຖືກສົ່ງອີກຄັ້ງ.',
        );
      }
    } on DioException catch (e) {
      _showDioError('ສົ່ງຊ້ຳລົ້ມເຫຼວ', e,
          fallback: 'ບໍ່ສາມາດສົ່ງການແຈ້ງເຕືອນຊ້ຳໄດ້.');
    } finally {
      isSending.value = false;
    }
  }

  // ───────────────────────────────────────────── history filters ──

  /// Show the history sub-screen and apply current filters.
  void openHistory() {
    showHistory.value = true;
    _applyHistoryFilters();
  }

  /// Hide the history sub-screen and clear the local search term.
  void closeHistory() {
    showHistory.value = false;
    searchHistoryCtrl.clear();
    historySearch.value = '';
  }

  /// Bound to the history search field's `onChanged`.
  void onHistorySearchChanged(String val) {
    historySearch.value = val;
    _applyHistoryFilters();
  }

  /// Switch history sort mode (see [AnnouncementSortMode]).
  void setHistorySortMode(int mode) {
    historySortMode.value = mode;
    _applyHistoryFilters();
  }

  /// Switch the history type filter — pass `''` to remove the filter.
  void setHistoryFilterType(String type) {
    historyFilterType.value = type;
    _applyHistoryFilters();
  }

  /// Unique non-empty type values across [notifications], sorted A→Z.
  /// Drives the chips at the top of the history page.
  List<String> get uniqueTypes {
    final types = notifications
        .where((n) => n.type != null && n.type!.isNotEmpty)
        .map((n) => n.type!)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  /// Refresh handler — bound to the bottom-nav tab refresher and to
  /// `RefreshIndicator.onRefresh` in the history view.
  Future<void> refreshData() async {
    await fetchNotifications();
    _applyHistoryFilters();
  }

  void _applyHistoryFilters() {
    var list = List<NotificationModel>.from(notifications);

    final q = historySearch.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.message.toLowerCase().contains(q) ||
            (n.type ?? '').toLowerCase().contains(q);
      }).toList();
    }

    if (historyFilterType.value.isNotEmpty) {
      list = list.where((n) => n.type == historyFilterType.value).toList();
    }

    final epoch = DateTime(2000);
    switch (historySortMode.value) {
      case AnnouncementSortMode.oldest:
        list.sort(
          (a, b) => (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch),
        );
        break;
      case AnnouncementSortMode.titleAZ:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case AnnouncementSortMode.newest:
      default:
        list.sort(
          (a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch),
        );
    }

    filteredNotifications.assignAll(list);
  }

  // ────────────────────────────────────────────────── payload + ui ──

  /// Build the audience + filter **query parameters** for `POST /notifications`.
  ///
  /// The backend resolves the recipient set from the query string (see
  /// `resolveAudienceUserIDs`), not the JSON body — so audience, group/type/
  /// department filters, and the individual `std_id` all travel here. The body
  /// carries only title/message/type. This also keeps the send aligned with the
  /// reach-estimate call, which already uses query params.
  Map<String, dynamic> _buildSendQuery() {
    final q = <String, dynamic>{'audience': _audienceCode()};
    if (selectedAudience.value == AnnouncementAudience.individual) {
      final s = foundStudent.value;
      if (s != null) q['std_id'] = s.id;
    } else {
      q.addAll(_buildFilters());
    }
    return q;
  }

  /// Human-readable audience description stored as the notification's
  /// `type` and shown in history.
  String buildNotificationType() {
    final audience = audienceLabels[selectedAudience.value];

    if (selectedAudience.value == AnnouncementAudience.individual &&
        foundStudent.value != null) {
      final s = foundStudent.value!;
      return 'ບຸກຄົນສະເພາະ | ID: ${s.id} | ${s.nameLao}';
    }

    final dept = selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ';
    final group = selectedStudentGroup.value?.stdGroupName ?? 'ທັງໝົດ';
    final type = selectedStudentType.value?.stdTypeNameLao ?? 'ທັງໝົດ';
    final year = yearLabels[selectedYear.value];

    if (selectedAudience.value == AnnouncementAudience.students) {
      return '$audience | ພາກ: $dept | ກຸ່ມ: $group | ປະເພດ: $type | $year';
    }
    if (selectedAudience.value == AnnouncementAudience.teachers) {
      return '$audience | ພາກ: $dept';
    }
    return audience;
  }

  /// Stringified audience identifier accepted by the backend.
  String _audienceCode() {
    switch (selectedAudience.value) {
      case AnnouncementAudience.students:
        return 'students';
      case AnnouncementAudience.teachers:
        return 'teachers';
      case AnnouncementAudience.individual:
        return 'individual';
      default:
        return 'all';
    }
  }

  Map<String, dynamic> _buildFilters() {
    final f = <String, dynamic>{};
    final deptId = selectedDepartment.value?.id;
    if (deptId != null) f['dept_id'] = deptId;
    if (selectedAudience.value == AnnouncementAudience.students) {
      final groupId = selectedStudentGroup.value?.id;
      final typeId = selectedStudentType.value?.id;
      if (groupId != null) f['std_group_id'] = groupId;
      if (typeId != null) f['std_type_id'] = typeId;
      if (selectedYear.value > 0) f['year'] = selectedYear.value;
    }
    return f;
  }

  /// Build the audience-summary row list used by [_SendConfirmationDialog].
  /// Exposed (not private) so the dialog widget can render it without
  /// coupling to controller internals.
  List<AnnouncementInfoRow> buildConfirmationRows() {
    final rows = <AnnouncementInfoRow>[
      AnnouncementInfoRow('ຫົວຂໍ້', titleCtrl.text.trim()),
    ];

    switch (selectedAudience.value) {
      case AnnouncementAudience.individual:
        final s = foundStudent.value;
        if (s != null) {
          rows
            ..add(const AnnouncementInfoRow('ສົ່ງຫາ', 'ບຸກຄົນສະເພາະ'))
            ..add(AnnouncementInfoRow('ID', '${s.id}'))
            ..add(AnnouncementInfoRow('ລະຫັດ', s.stdCode))
            ..add(AnnouncementInfoRow(
                'ຊື່', '${s.nameLao} ${s.surnameLao ?? ''}'))
            ..add(AnnouncementInfoRow(
                'ກຸ່ມ', s.studentGroup?.stdGroupName ?? '-'))
            ..add(AnnouncementInfoRow(
                'ປະເພດ', s.studentType?.stdTypeNameLao ?? '-'));
        }
        break;
      case AnnouncementAudience.students:
        rows
          ..add(const AnnouncementInfoRow('ສົ່ງຫາ', 'ນັກສຶກສາ'))
          ..add(AnnouncementInfoRow(
              'ພາກວິຊາ', selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ'))
          ..add(AnnouncementInfoRow(
              'ກຸ່ມ', selectedStudentGroup.value?.stdGroupName ?? 'ທັງໝົດ'))
          ..add(AnnouncementInfoRow('ປະເພດ',
              selectedStudentType.value?.stdTypeNameLao ?? 'ທັງໝົດ'))
          ..add(AnnouncementInfoRow(
              'ຊັ້ນປີ', yearLabels[selectedYear.value]));
        break;
      case AnnouncementAudience.teachers:
        rows
          ..add(const AnnouncementInfoRow('ສົ່ງຫາ', 'ອາຈານ'))
          ..add(AnnouncementInfoRow(
              'ພາກວິຊາ', selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ'));
        break;
      default:
        rows.add(const AnnouncementInfoRow('ສົ່ງຫາ', 'ທັງໝົດ (ນັກສຶກສາ + ອາຈານ)'));
    }
    return rows;
  }

  void _resetForm() {
    titleCtrl.clear();
    messageCtrl.clear();
    individualIdCtrl.clear();
    selectedAudience.value = AnnouncementAudience.all;
    selectedDepartment.value = null;
    selectedStudentGroup.value = null;
    selectedStudentType.value = null;
    selectedYear.value = 0;
    foundStudent.value = null;
  }

  void _showDioError(String title, DioException e, {required String fallback}) {
    var message = fallback;
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      message = data['error'].toString();
    }
    AppDialogs.showError(
      title: title,
      message: message,
      detail: AppDialogs.buildDioErrorDetail(e),
    );
  }

  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const <dynamic>[];
  }
}

/// One row of the confirmation summary rendered by [_SendConfirmationDialog].
class AnnouncementInfoRow {
  /// Left-side label.
  final String label;

  /// Right-side value.
  final String value;

  const AnnouncementInfoRow(this.label, this.value);
}

/// Confirmation dialog rendered before [AnnouncementController.sendNotification]
/// POSTs the payload.
class _SendConfirmationDialog extends StatelessWidget {
  /// Source of reactive state — provides the rows + reach estimate.
  final AnnouncementController controller;

  const _SendConfirmationDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SendIconBadge(),
            const SizedBox(height: 14),
            const Text(
              'ຢືນຢັນການສົ່ງ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ກະລຸນາກວດສອບລາຍລະອຽດ',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 14),
            _ConfirmationRows(rows: controller.buildConfirmationRows()),
            const SizedBox(height: 10),
            Obx(
              () => _EstimatedReachPill(
                count: controller.estimatedReach.value,
                loading: controller.isEstimatingReach.value,
              ),
            ),
            const SizedBox(height: 18),
            _DialogFooter(
              cancelLabel: 'ຍົກເລີກ',
              confirmLabel: 'ສົ່ງ',
              confirmIcon: Icons.send_rounded,
              confirmColor: AppColors.laoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Indigo icon badge at the top of [_SendConfirmationDialog].
class _SendIconBadge extends StatelessWidget {
  const _SendIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.send_rounded,
        color: AppColors.laoBlue,
        size: 36,
      ),
    );
  }
}

/// Boxed list of `label : value` rows inside [_SendConfirmationDialog].
class _ConfirmationRows extends StatelessWidget {
  /// Pre-built label/value rows from [AnnouncementController.buildConfirmationRows].
  final List<AnnouncementInfoRow> rows;

  const _ConfirmationRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${r.label}:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill below the confirmation rows that announces the estimated recipient
/// count, or a loading placeholder while the count is being fetched.
class _EstimatedReachPill extends StatelessWidget {
  /// Last computed count; `null` means "couldn't estimate".
  final int? count;

  /// Whether the estimate is currently in flight.
  final bool loading;

  const _EstimatedReachPill({required this.count, required this.loading});

  @override
  Widget build(BuildContext context) {
    final label = loading
        ? 'ກຳລັງປະເມີນຜູ້ຮັບ...'
        : (count == null ? 'ປະເມີນຜູ້ຮັບບໍ່ໄດ້' : 'ຈະສົ່ງຫາປະມານ $count ຄົນ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.laoBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_2_rounded,
              color: AppColors.laoBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.laoBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edit-notification dialog rendered by [AnnouncementController.editNotification].
class _EditNotificationDialog extends StatelessWidget {
  /// Source of the title / message text controllers.
  final AnnouncementController controller;

  const _EditNotificationDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ແກ້ໄຂການແຈ້ງເຕືອນ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('ຫົວຂໍ້'),
            const SizedBox(height: 4),
            _DialogTextField(controller: controller.editTitleCtrl),
            const SizedBox(height: 10),
            const _FieldLabel('ເນື້ອຫາ'),
            const SizedBox(height: 4),
            _DialogTextField(
              controller: controller.editMessageCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _DialogFooter(
              cancelLabel: 'ຍົກເລີກ',
              confirmLabel: 'ບັນທຶກ',
              confirmColor: AppColors.laoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small caption used as a field label inside [_EditNotificationDialog].
class _FieldLabel extends StatelessWidget {
  /// Caption text.
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

/// Filled, rounded text field used inside [_EditNotificationDialog].
class _DialogTextField extends StatelessWidget {
  /// Backing text controller.
  final TextEditingController controller;

  /// Vertical line count.
  final int maxLines;

  const _DialogTextField({
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 10,
        ),
      ),
    );
  }
}

/// Two-button footer (cancel + confirm) reused by both dialogs.
class _DialogFooter extends StatelessWidget {
  /// Cancel button caption — returns `false`.
  final String cancelLabel;

  /// Confirm button caption — returns `true`.
  final String confirmLabel;

  /// Tint applied to the confirm button.
  final Color confirmColor;

  /// Optional leading icon for the confirm button.
  final IconData? confirmIcon;

  const _DialogFooter({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmColor,
    this.confirmIcon,
  });

  @override
  Widget build(BuildContext context) {
    final confirmChild = confirmIcon == null
        ? Text(confirmLabel, style: const TextStyle(fontSize: 15))
        : null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(result: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(cancelLabel, style: const TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: confirmIcon == null
              ? ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: confirmChild!,
                )
              : ElevatedButton.icon(
                  onPressed: () => Get.back(result: true),
                  icon: Icon(confirmIcon, size: 18),
                  label: Text(confirmLabel,
                      style: const TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
