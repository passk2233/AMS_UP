import 'package:get/get.dart';

import '../../admin_navigator_bar/bottom_nav_controller.dart';
import '../controllers/home_controller.dart';

/// GetX binding for [AdminHomeView].
///
/// Registers the shared [BottomNavController] (only on first entry, so it
/// survives tab switches) and lazily registers the page's own
/// [AdminHomeController].
class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BottomNavController>()) {
      Get.put(BottomNavController(), permanent: true);
    }
    Get.lazyPut<AdminHomeController>(AdminHomeController.new);
  }
}
