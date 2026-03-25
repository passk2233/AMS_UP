import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
  // 🔄 ສ້າງໂຕປ່ຽນໄວ້ເຊັກສິດແຕ່ລະປະເພດ (ຄ່າເລີ່ມຕົ້ນແມ່ນ false)
  final isAdmin = false.obs;
  final isTeacher = false.obs;
  final isStudent = false.obs;
  
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserRoles(); // ເອີ້ນໃຊ້ຕອນເປີດໜ້າ
  }

  Future<void> _loadUserRoles() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ດຶງ List ຂອງ Roles ທີ່ບັນທຶກໄວ້ຕອນ Login ອອກມາ
    final savedRoles = prefs.getStringList('roles') ?? [];

    // 🔍 ກວດສອບ ແລະ ປ່ຽນຄ່າເປັນ true ຖ້າມີສິດນັ້ນໆ
    isAdmin.value = savedRoles.contains('admin');
    isTeacher.value = savedRoles.contains('teacher');
    isStudent.value = savedRoles.contains('student');
    // *ໝາຍເຫດ: ຖ້າ 1 ຄົນມີທັງ teacher ແລະ student, ມັນກໍຈະເປັນ true ທັງສອງອັນເລີຍ!

    isLoading.value = false;
  }
}