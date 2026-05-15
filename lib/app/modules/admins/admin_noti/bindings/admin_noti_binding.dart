import 'package:get/get.dart';

import '../controllers/admin_noti_controller.dart';

class AdminNotiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminNotiController>(
      () => AdminNotiController(),
    );
  }
}
