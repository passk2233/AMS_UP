import 'package:get/get.dart';

import '../controllers/student_home_controller.dart';

class HomeStudentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeStudentController>(
      () => HomeStudentController(),
    );
  }
}
