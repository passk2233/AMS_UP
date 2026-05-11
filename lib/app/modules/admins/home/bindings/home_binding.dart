import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../admin_navigator_bar/bottom_nav_controller.dart';

class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    // Shared bottom nav controller — kept alive across admin pages
    if (!Get.isRegistered<BottomNavController>()) {
      Get.put(BottomNavController(), permanent: true);
    }
    Get.lazyPut<AdminHomeController>(
      () => AdminHomeController(),
    );
  }
}
