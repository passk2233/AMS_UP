import 'package:get/get.dart';

import '../controllers/student_noti_controller.dart';

class StudentNotiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StudentNotiController>(
      () => StudentNotiController(),
    );
  }
}
