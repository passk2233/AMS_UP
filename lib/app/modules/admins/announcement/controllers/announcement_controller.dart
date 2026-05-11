import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/data_exporter.dart';
import '../../../../widgets/app_dialogs.dart';

class AnnouncementController extends GetxController {
  // ── Form fields ───────────────────────────────────────────────────────────
  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final individualIdCtrl = TextEditingController();

  // ── Target audience ───────────────────────────────────────────────────────
  // 0=All, 1=Students, 2=Teachers, 3=Individual
  final RxInt selectedAudience = 0.obs;
  final audienceLabels = ['ທັງໝົດ', 'ນັກສຶກສາ', 'ອາຈານ', 'ບຸກຄົນສະເພາະ'];

  // ── Department filter ─────────────────────────────────────────────────────
  final RxList<DepartmentModel> departments = <DepartmentModel>[].obs;
  final Rx<DepartmentModel?> selectedDepartment = Rx<DepartmentModel?>(null);

  // ── Student Group filter ──────────────────────────────────────────────────
  final RxList<StudentGroupModel> studentGroups = <StudentGroupModel>[].obs;
  final Rx<StudentGroupModel?> selectedStudentGroup =
      Rx<StudentGroupModel?>(null);

  // ── Student Type filter ───────────────────────────────────────────────────
  final RxList<StudentTypeModel> studentTypes = <StudentTypeModel>[].obs;
  final Rx<StudentTypeModel?> selectedStudentType =
      Rx<StudentTypeModel?>(null);

  // ── Year level filter ─────────────────────────────────────────────────────
  final RxInt selectedYear = 0.obs; // 0=All Years
  final yearLabels = ['ທຸກຊັ້ນປີ', 'ປີ 1', 'ປີ 2', 'ປີ 3', 'ປີ 4'];

  // ── Individual student lookup result ──────────────────────────────────────
  final Rx<StudentModel?> foundStudent = Rx<StudentModel?>(null);
  final RxBool isSearching = false.obs;

  // ── State ─────────────────────────────────────────────────────────────────
  final RxBool isSending = false.obs;
  final RxBool isLoading = false.obs;
  


  // ── Notification history ──────────────────────────────────────────────────
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  final Dio _dio = Dio();
  String _token = '';

  @override
  void onInit() {
    super.onInit();
    _initDio();
    _loadToken().then((_) {
      fetchDepartments();
      fetchStudentGroups();
      fetchStudentTypes();
      fetchNotifications();
    });
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    messageCtrl.dispose();
    individualIdCtrl.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIO SETUP
  // ═══════════════════════════════════════════════════════════════════════════

  void _initDio() {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH REFERENCE DATA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> fetchDepartments() async {
    try {
      final response =
          await _dio.get('/departments', queryParameters: {'limit': 50});
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        departments.assignAll(
          items.map((j) => DepartmentModel.fromJson(j)).toList(),
        );
      }
    } on DioException catch (e) {
      debugPrint('fetchDepartments error: ${e.message}');
    }
  }

  Future<void> fetchStudentGroups() async {
    try {
      final response =
          await _dio.get('/student-groups', queryParameters: {'limit': 100});
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        studentGroups.assignAll(
          items.map((j) => StudentGroupModel.fromJson(j)).toList(),
        );
      }
    } on DioException catch (e) {
      debugPrint('fetchStudentGroups error: ${e.message}');
    }
  }

  Future<void> fetchStudentTypes() async {
    try {
      final response = await _dio.get('/student-types');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        studentTypes.assignAll(
          items.map((j) => StudentTypeModel.fromJson(j)).toList(),
        );
      }
    } on DioException catch (e) {
      debugPrint('fetchStudentTypes error: ${e.message}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH NOTIFICATIONS HISTORY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final response =
          await _dio.get('/notifications', queryParameters: {'limit': 20});
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['data'] != null) {
          items = data['data'];
        }
        notifications.assignAll(
          items.map((j) => NotificationModel.fromJson(j)).toList(),
        );
      }
    } on DioException catch (e) {
      debugPrint('fetchNotifications error: ${e.message}');
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH INDIVIDUAL STUDENT BY ID
  // ═══════════════════════════════════════════════════════════════════════════

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
      if (response.statusCode == 200) {
        final data = response.data;
        // Handle both { data: {...} } and direct object
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            foundStudent.value = StudentModel.fromJson(data['data']);
          } else {
            foundStudent.value = StudentModel.fromJson(data);
          }
        }
      }
    } on DioException catch (e) {
      foundStudent.value = null;
      if (e.response?.statusCode == 404) {
        AppDialogs.showWarning(
          title: 'ບໍ່ພົບນັກສຶກສາ',
          message: 'ບໍ່ພົບນັກສຶກສາ ID: $id ໃນລະບົບ.',
        );
      } else {
        final detail = AppDialogs.buildDioErrorDetail(e);
        AppDialogs.showError(
          title: 'ຄົ້ນຫາລົ້ມເຫຼວ',
          message: 'ບໍ່ສາມາດຄົ້ນຫານັກສຶກສາໄດ້.',
          detail: detail,
        );
      }
    } finally {
      isSearching.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD NOTIFICATION TYPE & CONFIRMATION SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  String _buildNotificationType() {
    final audience = audienceLabels[selectedAudience.value];

    if (selectedAudience.value == 3 && foundStudent.value != null) {
      final s = foundStudent.value!;
      return 'ບຸກຄົນສະເພາະ | ID: ${s.id} | ${s.nameLao}';
    }

    final dept = selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ';
    final group = selectedStudentGroup.value?.stdGroupName ?? 'ທັງໝົດ';
    final type = selectedStudentType.value?.stdTypeNameLao ?? 'ທັງໝົດ';
    final year = yearLabels[selectedYear.value];

    if (selectedAudience.value == 1) {
      // Students
      return '$audience | ພາກ: $dept | ກຸ່ມ: $group | ປະເພດ: $type | $year';
    } else if (selectedAudience.value == 2) {
      // Teachers
      return '$audience | ພາກ: $dept';
    }
    return audience; // All
  }

  /// Builds a user-readable summary of WHO the notification goes to.
  Widget buildConfirmationContent() {
    final rows = <_InfoRow>[];

    rows.add(_InfoRow('ຫົວຂໍ້', titleCtrl.text.trim()));

    if (selectedAudience.value == 3) {
      // ── Individual ──
      final s = foundStudent.value;
      if (s != null) {
        rows.add(_InfoRow('ສົ່ງຫາ', 'ບຸກຄົນສະເພາະ'));
        rows.add(_InfoRow('ID', '${s.id}'));
        rows.add(_InfoRow('ລະຫັດ', s.stdCode));
        rows.add(_InfoRow('ຊື່', '${s.nameLao} ${s.surnameLao ?? ''}'));
        rows.add(_InfoRow('ກຸ່ມ', s.studentGroup?.stdGroupName ?? '-'));
        rows.add(_InfoRow('ປະເພດ', s.studentType?.stdTypeNameLao ?? '-'));
      }
    } else if (selectedAudience.value == 1) {
      // ── Students group ──
      rows.add(_InfoRow('ສົ່ງຫາ', 'ນັກສຶກສາ'));
      rows.add(_InfoRow(
          'ພາກວິຊາ', selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ'));
      rows.add(_InfoRow(
          'ກຸ່ມ', selectedStudentGroup.value?.stdGroupName ?? 'ທັງໝົດ'));
      rows.add(_InfoRow(
          'ປະເພດ', selectedStudentType.value?.stdTypeNameLao ?? 'ທັງໝົດ'));
      rows.add(_InfoRow('ຊັ້ນປີ', yearLabels[selectedYear.value]));
    } else if (selectedAudience.value == 2) {
      // ── Teachers ──
      rows.add(_InfoRow('ສົ່ງຫາ', 'ອາຈານ'));
      rows.add(_InfoRow(
          'ພາກວິຊາ', selectedDepartment.value?.deptNameLao ?? 'ທັງໝົດ'));
    } else {
      rows.add(_InfoRow('ສົ່ງຫາ', 'ທັງໝົດ (ນັກສຶກສາ + ອາຈານ)'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map((r) => Padding(
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
              ))
          .toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> sendNotification() async {
    // ── Validation ──
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
    if (selectedAudience.value == 3 && foundStudent.value == null) {
      AppDialogs.showWarning(
        title: 'ຍັງບໍ່ໄດ້ເລືອກບຸກຄົນ',
        message: 'ກະລຸນາຄົ້ນຫາ ແລະ ຢືນຢັນນັກສຶກສາກ່ອນ.',
      );
      return;
    }

    // ── Confirmation with details ──
    final confirmed = await _showDetailedConfirmation();
    if (confirmed != true) return;

    isSending.value = true;
    try {
      final response = await _dio.post('/notifications', data: {
        'title': titleCtrl.text.trim(),
        'message': messageCtrl.text.trim(),
        'type': _buildNotificationType(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetForm();
        fetchNotifications();
        AppDialogs.showSuccess(
          title: 'ສົ່ງສຳເລັດ',
          message: 'ການແຈ້ງເຕືອນໄດ້ຖືກສົ່ງອອກແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      String message = 'ບໍ່ສາມາດສົ່ງການແຈ້ງເຕືອນໄດ້.';
      if (e.response?.data is Map<String, dynamic>) {
        message = e.response?.data['error'] ?? message;
      }
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'ສົ່ງລົ້ມເຫຼວ',
        message: message,
        detail: detail,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Shows a detailed confirmation dialog with target audience summary.
  Future<bool?> _showDetailedConfirmation() {
    return Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C4DDC).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Color(0xFF4C4DDC),
                  size: 36,
                ),
              ),
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
              // Details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: buildConfirmationContent(),
              ),
              const SizedBox(height: 18),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ຍົກເລີກ',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(result: true),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('ສົ່ງ',
                          style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C4DDC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _resetForm() {
    titleCtrl.clear();
    messageCtrl.clear();
    individualIdCtrl.clear();
    selectedAudience.value = 0;
    selectedDepartment.value = null;
    selectedStudentGroup.value = null;
    selectedStudentType.value = null;
    selectedYear.value = 0;
    foundStudent.value = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> deleteNotification(int notiId) async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ລຶບການແຈ້ງເຕືອນ',
      message: 'ທ່ານຕ້ອງການລຶບການແຈ້ງເຕືອນນີ້ແທ້ບໍ?',
      confirmText: 'ລຶບ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: const Color(0xFFE53935),
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
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'ລຶບລົ້ມເຫຼວ',
        message: 'ບໍ່ສາມາດລຶບການແຈ້ງເຕືອນໄດ້.',
        detail: detail,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HISTORY PAGE STATE
  // ═══════════════════════════════════════════════════════════════════════════

  final RxBool showHistory = false.obs;
  final searchHistoryCtrl = TextEditingController();
  final RxString historySearch = ''.obs;
  final RxInt historySortMode = 0.obs; // 0=newest, 1=oldest, 2=title A-Z
  final RxString historyFilterType = ''.obs; // '' = all
  final RxList<NotificationModel> filteredNotifications =
      <NotificationModel>[].obs;

  void openHistory() {
    showHistory.value = true;
    _applyHistoryFilters();
  }

  void closeHistory() {
    showHistory.value = false;
    searchHistoryCtrl.clear();
    historySearch.value = '';
  }

  void onHistorySearchChanged(String val) {
    historySearch.value = val;
    _applyHistoryFilters();
  }

  void setHistorySortMode(int mode) {
    historySortMode.value = mode;
    _applyHistoryFilters();
  }

  void setHistoryFilterType(String type) {
    historyFilterType.value = type;
    _applyHistoryFilters();
  }

  /// Get unique type values from notifications for the filter chips.
  List<String> get uniqueTypes {
    final types = notifications
        .where((n) => n.type != null && n.type!.isNotEmpty)
        .map((n) => n.type!)
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  void _applyHistoryFilters() {
    var list = List<NotificationModel>.from(notifications);

    // Search
    final q = historySearch.value.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.message.toLowerCase().contains(q) ||
            (n.type ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // Filter by type
    if (historyFilterType.value.isNotEmpty) {
      list = list
          .where((n) => n.type == historyFilterType.value)
          .toList();
    }

    // Sort
    switch (historySortMode.value) {
      case 0: // newest
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
      case 1: // oldest
        list.sort((a, b) =>
            (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000)));
        break;
      case 2: // title A-Z
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    filteredNotifications.assignAll(list);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  final editTitleCtrl = TextEditingController();
  final editMessageCtrl = TextEditingController();
  final RxBool isEditing = false.obs;

  Future<void> editNotification(NotificationModel noti) async {
    editTitleCtrl.text = noti.title;
    editMessageCtrl.text = noti.message;

    final confirmed = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ແກ້ໄຂການແຈ້ງເຕືອນ',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              const Text('ຫົວຂໍ້',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              TextField(
                controller: editTitleCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              const Text('ເນື້ອຫາ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              TextField(
                controller: editMessageCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ຍົກເລີກ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C4DDC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ບັນທຶກ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    isEditing.value = true;
    try {
      // Backend doesn't have PUT for notifications, so we delete and recreate
      await _dio.delete('/notifications/${noti.notiId}');
      final response = await _dio.post('/notifications', data: {
        'title': editTitleCtrl.text.trim(),
        'message': editMessageCtrl.text.trim(),
        'type': noti.type ?? '',
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchNotifications();
        _applyHistoryFilters();
        AppDialogs.showSuccess(
          title: 'ແກ້ໄຂສຳເລັດ',
          message: 'ການແຈ້ງເຕືອນໄດ້ຖືກອັບເດດແລ້ວ.',
        );
      }
    } on DioException catch (e) {
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'ແກ້ໄຂລົ້ມເຫຼວ',
        message: 'ບໍ່ສາມາດແກ້ໄຂການແຈ້ງເຕືອນໄດ້.',
        detail: detail,
      );
    } finally {
      isEditing.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESEND NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> resendNotification(NotificationModel noti) async {
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ສົ່ງຊ້ຳ',
      message: 'ຕ້ອງການສົ່ງການແຈ້ງເຕືອນ\n"${noti.title}"\nອີກຄັ້ງບໍ?',
      confirmText: 'ສົ່ງຊ້ຳ',
      cancelText: 'ຍົກເລີກ',
      confirmColor: const Color(0xFF4C4DDC),
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
      final detail = AppDialogs.buildDioErrorDetail(e);
      AppDialogs.showError(
        title: 'ສົ່ງຊ້ຳລົ້ມເຫຼວ',
        message: 'ບໍ່ສາມາດສົ່ງການແຈ້ງເຕືອນຊ້ຳໄດ້.',
        detail: detail,
      );
    } finally {
      isSending.value = false;
    }
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> refreshData() async {
    await fetchNotifications();
    _applyHistoryFilters();
  }
}

/// Helper class for confirmation detail rows.
class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}
