import 'package:get/get.dart';

import '../controllers/teacher_noti_controller.dart';

class TeacherNotiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeacherNotiController>(
      () => TeacherNotiController(),
    );
  }
}
