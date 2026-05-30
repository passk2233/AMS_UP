import 'package:get/get.dart';

import '../controllers/teacher_home_controller.dart';

/// GetX binding for [TeacherHomeView] — lazily registers
/// [TeacherHomeController] on first navigation.
class TeacherHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherHomeController>(TeacherHomeController.new);
  }
}
