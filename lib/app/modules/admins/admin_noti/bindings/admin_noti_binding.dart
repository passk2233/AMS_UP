import 'package:get/get.dart';

import '../controllers/admin_noti_controller.dart';

/// GetX binding for [AdminNotiView] — lazily registers
/// [AdminNotiController] on first navigation.
class AdminNotiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminNotiController>(AdminNotiController.new);
  }
}
