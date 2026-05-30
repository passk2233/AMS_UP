import 'package:get/get.dart';

import '../controllers/teacher_noti_controller.dart';

/// GetX binding for [TeacherNotiView] — lazily registers
/// [TeacherNotiController] on first navigation.
class TeacherNotiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherNotiController>(TeacherNotiController.new);
  }
}
