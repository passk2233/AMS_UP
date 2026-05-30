import 'package:get/get.dart';

import '../controllers/admin_profile_controller.dart';

/// GetX binding for [AdminProfileView] — lazily registers
/// [AdminProfileController] on first navigation.
class AdminProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminProfileController>(AdminProfileController.new);
  }
}
