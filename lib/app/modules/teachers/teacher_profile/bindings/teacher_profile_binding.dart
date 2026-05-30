import 'package:get/get.dart';

import '../controllers/teacher_profile_controller.dart';

/// GetX binding for [TeacherProfileView] — lazily registers
/// [TeacherProfileController] on first navigation.
class TeacherProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherProfileController>(TeacherProfileController.new);
  }
}
