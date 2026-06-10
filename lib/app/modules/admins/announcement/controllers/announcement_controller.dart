import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// dio and get both export FormData / MultipartFile; hide get's so the dio
// types win for the multipart upload below.
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../../../../widgets/app_colors.dart';
import '../../../../widgets/app_dialogs.dart';
import '../../../data/data_exporter.dart';
import '../views/announcement_dialogs.dart';

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
  AnnouncementController({
    NotificationProvider? notification,
    PeopleProvider? people,
    ReferenceProvider? reference,
  })  : _noti = notification ?? NotificationProvider(),
        _people = people ?? PeopleProvider(),
        _reference = reference ?? ReferenceProvider();

  final NotificationProvider _noti;
  final PeopleProvider _people;
  final ReferenceProvider _reference;

  /// Compose form — notification title.
  final TextEditingController titleCtrl = TextEditingController();

  /// Compose form — notification body / message.
  final TextEditingController messageCtrl = TextEditingController();

  /// Compose form — student code or name typed into the individual lookup
  /// field. The numeric primary key is never typed by the admin.
  final TextEditingController individualSearchCtrl = TextEditingController();

  /// Edit dialog — title field, reused via [_EditNotificationDialog].
  final TextEditingController editTitleCtrl = TextEditingController();

  /// Edit dialog — message field, reused via [_EditNotificationDialog].
  final TextEditingController editMessageCtrl = TextEditingController();

  /// History page — search field controller.
  final TextEditingController searchHistoryCtrl = TextEditingController();

  /// Compose form — attachments the admin picked but hasn't uploaded yet.
  /// Uploaded to `/notifications/upload` at send time; empty when none.
  final RxList<PlatformFile> pickedFiles = <PlatformFile>[].obs;

  /// `true` while the picked attachments are being uploaded to the server.
  final RxBool isUploading = false.obs;

  /// Edit dialog — how many attachments the edited notification already has;
  /// drives the "remove attachments" row (0 hides it).
  final RxInt editingFilesCount = 0.obs;

  /// Edit dialog — when `true`, the existing attachments are cleared on save.
  final RxBool editRemoveFile = false.obs;

  /// Per-file size cap, mirroring the backend's MaxUploadFileBytes (10 MiB),
  /// so the picker rejects oversized files before an upload round-trip.
  static const int maxUploadFileBytes = 10 * 1024 * 1024;

  /// Max attachments per notification (mirrors the backend's MaxUploadFiles).
  static const int maxUploadFiles = 10;

  /// Extensions accepted by the picker — must stay within the backend's
  /// `allowedUploadExt` allow-list.
  static const List<String> allowedUploadExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
  ];

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
  final Rx<StudentGroupModel?> selectedStudentGroup = Rx<StudentGroupModel?>(
    null,
  );

  /// Student types fetched from `/student-types`.
  final RxList<StudentTypeModel> studentTypes = <StudentTypeModel>[].obs;

  /// Currently selected student type, or `null` for "all".
  final Rx<StudentTypeModel?> selectedStudentType = Rx<StudentTypeModel?>(null);

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

  /// The student the admin has confirmed as the individual recipient. `null`
  /// until one of [searchResults] is selected (or an exact single match is
  /// auto-selected).
  final Rx<StudentModel?> foundStudent = Rx<StudentModel?>(null);

  /// Matches returned by the last [searchStudents] call (by code or name).
  /// The admin taps one to set [foundStudent]; empty when no search has run.
  final RxList<StudentModel> searchResults = <StudentModel>[].obs;

  /// `true` while [searchStudents] is in flight.
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
    individualSearchCtrl.dispose();
    editTitleCtrl.dispose();
    editMessageCtrl.dispose();
    searchHistoryCtrl.dispose();
    super.onClose();
  }

  // ───────────────────────────────────────────── reference data ──

  /// GET `/departments` and populate [departments].
  Future<void> fetchDepartments() async {
    try {
      departments.assignAll(await _reference.fetchDepartments());
    } on DioException catch (e) {
      debugPrint('fetchDepartments error: ${e.message}');
    }
  }

  /// GET `/student-groups` and populate [studentGroups].
  Future<void> fetchStudentGroups() async {
    try {
      studentGroups.assignAll(await _reference.fetchStudentGroups());
    } on DioException catch (e) {
      debugPrint('fetchStudentGroups error: ${e.message}');
    }
  }

  /// GET `/student-types` and populate [studentTypes].
  Future<void> fetchStudentTypes() async {
    try {
      studentTypes.assignAll(await _reference.fetchStudentTypes());
    } on DioException catch (e) {
      debugPrint('fetchStudentTypes error: ${e.message}');
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
      final parsed =
          await _noti.fetchHistory(page: _currentPage, limit: _pageSize);
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
      final parsed =
          await _noti.fetchHistory(page: nextPage, limit: _pageSize);
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

  /// Search students by code or name using the term in [individualSearchCtrl].
  /// Populates [searchResults]; auto-selects [foundStudent] on a single match
  /// and surfaces a warning when nothing matches. The numeric primary key is
  /// never entered by the admin.
  Future<void> searchStudents() async {
    final term = individualSearchCtrl.text.trim();
    if (term.isEmpty) {
      searchResults.clear();
      foundStudent.value = null;
      AppDialogs.showWarning(
        title: 'ກະລຸນາໃສ່ຄຳຄົ້ນຫາ',
        message: 'ໃສ່ລະຫັດນັກສຶກສາ ຫຼື ຊື່ ເພື່ອຄົ້ນຫາ.',
      );
      return;
    }

    isSearching.value = true;
    foundStudent.value = null;
    try {
      final results = await _people.fetchStudents(
        filters: {'search': term},
        limit: 20,
      );
      searchResults.assignAll(results);
      if (results.isEmpty) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບນັກສຶກສາ',
          message: 'ບໍ່ພົບນັກສຶກສາທີ່ກົງກັບ "$term" ໃນລະບົບ.',
        );
      } else if (results.length == 1) {
        foundStudent.value = results.first;
      }
    } on DioException catch (e) {
      searchResults.clear();
      foundStudent.value = null;
      AppDialogs.showError(
        title: 'ຄົ້ນຫາລົ້ມເຫຼວ',
        message: 'ບໍ່ສາມາດຄົ້ນຫານັກສຶກສາໄດ້.',
        detail: AppDialogs.buildDioErrorDetail(e),
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Confirm [student] as the individual recipient (from a multi-match list).
  void selectStudent(StudentModel student) {
    foundStudent.value = student;
  }

  /// Clear the current individual selection and any pending search results.
  void clearIndividualSelection() {
    foundStudent.value = null;
    searchResults.clear();
    individualSearchCtrl.clear();
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
        final count = await _noti.estimateReach(params);
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

  Future<int> _countByPaginatedFallback() async {
    var total = 0;
    final audience = selectedAudience.value;
    if (audience == AnnouncementAudience.all ||
        audience == AnnouncementAudience.students) {
      total += (await _people.fetchStudents(
        filters: _buildFilters(),
        limit: 5000,
      ))
          .length;
    }
    if (audience == AnnouncementAudience.all ||
        audience == AnnouncementAudience.teachers) {
      total += (await _people.fetchTeachers(
        deptId: selectedDepartment.value?.id,
        limit: 5000,
      ))
          .length;
    }
    return total;
  }

  // ──────────────────────────────────────────────── attachment ──

  /// Open the system file picker (multi-select, restricted to
  /// [allowedUploadExtensions]) and append the chosen files to [pickedFiles].
  /// Skips files over [maxUploadFileBytes] and enforces the [maxUploadFiles]
  /// total, surfacing a warning rather than failing silently.
  Future<void> pickAttachment() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedUploadExtensions,
        allowMultiple: true,
        withData: true, // load bytes so upload works on web + in-memory paths
      );
      if (result == null || result.files.isEmpty) return;

      final tooLarge = <String>[];
      final accepted = <PlatformFile>[];
      for (final f in result.files) {
        if (f.size > maxUploadFileBytes) {
          tooLarge.add(f.name);
        } else {
          accepted.add(f);
        }
      }

      // Keep earlier picks; cap the running total at maxUploadFiles.
      final room = maxUploadFiles - pickedFiles.length;
      final overflow = accepted.length > room;
      if (room > 0) pickedFiles.addAll(accepted.take(room));

      if (tooLarge.isNotEmpty || overflow) {
        final parts = <String>[];
        if (tooLarge.isNotEmpty) {
          parts.add('ຂ້າມໄຟລ໌ໃຫຍ່ກວ່າ 10 MB: ${tooLarge.join(', ')}');
        }
        if (overflow) {
          parts.add('ແນບໄດ້ສູງສຸດ $maxUploadFiles ໄຟລ໌.');
        }
        AppDialogs.showWarning(
          title: 'ບາງໄຟລ໌ບໍ່ຖືກເພີ່ມ',
          message: parts.join('\n'),
        );
      }
    } catch (e) {
      debugPrint('pickAttachment error: $e');
      AppDialogs.showError(
        title: 'ເລືອກໄຟລ໌ບໍ່ໄດ້',
        message: 'ບໍ່ສາມາດເລືອກໄຟລ໌ໄດ້. ກະລຸນາລອງໃໝ່.',
      );
    }
  }

  /// Remove one staged attachment by index.
  void removePickedFileAt(int index) {
    if (index >= 0 && index < pickedFiles.length) pickedFiles.removeAt(index);
  }

  /// Drop all staged attachments.
  void clearPickedFiles() => pickedFiles.clear();

  /// Upload every staged file to `/notifications/upload` in one multipart
  /// request and return the list of `{path,name,mime,size}` refs to send on
  /// the notification. Returns `[]` when nothing is staged, `null` when the
  /// response was malformed. Throws [DioException] on network failure so the
  /// caller can surface a precise error.
  Future<List<Map<String, dynamic>>?> _uploadPickedFiles() async {
    if (pickedFiles.isEmpty) return const [];

    final form = FormData();
    for (final f in pickedFiles) {
      final MultipartFile part;
      if (f.bytes != null) {
        part = MultipartFile.fromBytes(f.bytes!, filename: f.name);
      } else if (f.path != null) {
        part = await MultipartFile.fromFile(f.path!, filename: f.name);
      } else {
        continue; // no readable data for this platform
      }
      form.files.add(MapEntry('files', part));
    }
    if (form.files.isEmpty) return null;

    isUploading.value = true;
    try {
      return await _noti.uploadAttachments(form);
    } finally {
      isUploading.value = false;
    }
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
      SendConfirmationDialog(controller: this),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    isSending.value = true;
    try {
      // Upload staged attachments first so their refs travel with the
      // notification. A failed upload aborts the send; the `finally` still
      // clears the sending flag.
      List<Map<String, dynamic>> fileRefs = const [];
      if (pickedFiles.isNotEmpty) {
        List<Map<String, dynamic>>? uploaded;
        try {
          uploaded = await _uploadPickedFiles();
        } on DioException catch (e) {
          _showDioError(
            'ອັບໂຫຼດໄຟລ໌ລົ້ມເຫຼວ',
            e,
            fallback: 'ບໍ່ສາມາດອັບໂຫຼດໄຟລ໌ໄດ້.',
          );
          return;
        }
        if (uploaded == null) {
          AppDialogs.showError(
            title: 'ອັບໂຫຼດໄຟລ໌ລົ້ມເຫຼວ',
            message: 'ບໍ່ສາມາດອັບໂຫຼດໄຟລ໌ໄດ້. ກະລຸນາລອງໃໝ່.',
          );
          return;
        }
        fileRefs = uploaded;
      }

      await _noti.send(
        query: _buildSendQuery(),
        data: {
          'title': titleCtrl.text.trim(),
          'message': messageCtrl.text.trim(),
          'type': buildNotificationType(),
          'files': fileRefs,
        },
      );
      _resetForm();
      fetchNotifications();
      AppDialogs.showSuccess(
        title: 'ສົ່ງສຳເລັດ',
        message: 'ການແຈ້ງເຕືອນໄດ້ຖືກສົ່ງອອກແລ້ວ.',
      );
    } on DioException catch (e) {
      _showDioError(
        'ສົ່ງລົ້ມເຫຼວ',
        e,
        fallback: 'ບໍ່ສາມາດສົ່ງການແຈ້ງເຕືອນໄດ້.',
      );
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
      await _noti.delete(notiId);
      notifications.removeWhere((n) => n.notiId == notiId);
      _applyHistoryFilters();
      AppDialogs.showSuccess(
        title: 'ລຶບສຳເລັດ',
        message: 'ການແຈ້ງເຕືອນໄດ້ຖືກລຶບແລ້ວ.',
      );
    } on DioException catch (e) {
      _showDioError('ລຶບລົ້ມເຫຼວ', e, fallback: 'ບໍ່ສາມາດລຶບການແຈ້ງເຕືອນໄດ້.');
    }
  }

  /// Open the edit dialog seeded with [noti] and, on confirm, PUT (or
  /// fall back to delete+POST when the route is missing) the new values.
  Future<void> editNotification(NotificationModel noti) async {
    editTitleCtrl.text = noti.title;
    editMessageCtrl.text = noti.message;
    editingFilesCount.value = noti.files.length;
    editRemoveFile.value = false;

    final confirmed = await Get.dialog<bool>(
      EditNotificationDialog(controller: this),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    isEditing.value = true;
    try {
      final body = {
        'title': editTitleCtrl.text.trim(),
        'message': editMessageCtrl.text.trim(),
        'type': noti.type ?? '',
        // Clear attachments when "remove" is ticked, otherwise resend the
        // existing set. Always sending `files` keeps both the PUT (replace)
        // and the delete+POST fallback paths correct.
        'files': editRemoveFile.value
            ? const []
            : noti.files.map((f) => f.toUploadRef()).toList(),
      };

      await _noti.updateOrRecreate(notiId: noti.notiId, data: body);
      await fetchNotifications();
      _applyHistoryFilters();
      AppDialogs.showSuccess(
        title: 'ແກ້ໄຂສຳເລັດ',
        message: 'ການແຈ້ງເຕືອນໄດ້ຖືກອັບເດດແລ້ວ.',
      );
    } on DioException catch (e) {
      _showDioError(
        'ແກ້ໄຂລົ້ມເຫຼວ',
        e,
        fallback: 'ບໍ່ສາມາດແກ້ໄຂການແຈ້ງເຕືອນໄດ້.',
      );
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
      await _noti.send(data: {
        'title': noti.title,
        'message': noti.message,
        'type': noti.type ?? '',
        'files': noti.files.map((f) => f.toUploadRef()).toList(),
      });
      await fetchNotifications();
      _applyHistoryFilters();
      AppDialogs.showSuccess(
        title: 'ສົ່ງຊ້ຳສຳເລັດ',
        message: 'ການແຈ້ງເຕືອນໄດ້ຖືກສົ່ງອີກຄັ້ງ.',
      );
    } on DioException catch (e) {
      _showDioError(
        'ສົ່ງຊ້ຳລົ້ມເຫຼວ',
        e,
        fallback: 'ບໍ່ສາມາດສົ່ງການແຈ້ງເຕືອນຊ້ຳໄດ້.',
      );
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
      return 'ບຸກຄົນສະເພາະ | ${s.stdCode} | ${s.nameLao} ${s.surnameLao ?? ''}'
          .trim();
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

  /// Build the audience-summary row list used by [SendConfirmationDialog].
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
            ..add(AnnouncementInfoRow('ລະຫັດ', s.stdCode))
            ..add(
              AnnouncementInfoRow('ຊື່', '${s.nameLao} ${s.surnameLao ?? ''}'),
            )
            ..add(
              AnnouncementInfoRow('ກຸ່ມ', s.studentGroup?.stdGroupName ?? '-'),
            )
            ..add(
              AnnouncementInfoRow(
                'ປະເພດ',
                s.studentType?.stdTypeNameLao ?? '-',
              ),
            );
        }
        break;
      case AnnouncementAudience.students:
        rows
          ..add(const AnnouncementInfoRow('ສົ່ງຫາ', 'ນັກສຶກສາ'))
          ..add(
            AnnouncementInfoRow(
              'ພາກວິຊາ',
              selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ',
            ),
          )
          ..add(
            AnnouncementInfoRow(
              'ກຸ່ມ',
              selectedStudentGroup.value?.stdGroupName ?? 'ທັງໝົດ',
            ),
          )
          ..add(
            AnnouncementInfoRow(
              'ປະເພດ',
              selectedStudentType.value?.stdTypeNameLao ?? 'ທັງໝົດ',
            ),
          )
          ..add(AnnouncementInfoRow('ຊັ້ນປີ', yearLabels[selectedYear.value]));
        break;
      case AnnouncementAudience.teachers:
        rows
          ..add(const AnnouncementInfoRow('ສົ່ງຫາ', 'ອາຈານ'))
          ..add(
            AnnouncementInfoRow(
              'ພາກວິຊາ',
              selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ',
            ),
          );
        break;
      default:
        rows.add(
          const AnnouncementInfoRow('ສົ່ງຫາ', 'ທັງໝົດ (ນັກສຶກສາ + ອາຈານ)'),
        );
    }
    return rows;
  }

  void _resetForm() {
    titleCtrl.clear();
    messageCtrl.clear();
    individualSearchCtrl.clear();
    searchResults.clear();
    pickedFiles.clear();
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

}

/// One row of the confirmation summary rendered by [SendConfirmationDialog].
class AnnouncementInfoRow {
  /// Left-side label.
  final String label;

  /// Right-side value.
  final String value;

  const AnnouncementInfoRow(this.label, this.value);
}

