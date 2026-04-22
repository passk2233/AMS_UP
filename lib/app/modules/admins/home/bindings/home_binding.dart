import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminHomeController>(
      () => AdminHomeController(),
    );
  }
}
