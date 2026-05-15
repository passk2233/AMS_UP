import 'package:frontend/app/modules/admins/approve/controllers/approve_controller.dart';
import 'package:frontend/app/modules/admins/home/controllers/home_controller.dart';
import 'package:frontend/app/modules/admins/announcement/controllers/announcement_controller.dart';
import 'package:frontend/app/modules/admins/admin_profile/controllers/admin_profile_controller.dart';
import 'package:frontend/app/widgets/admin_app_bar/admin_app_bar_controllers.dart';
import 'package:get/get.dart';


/// Global bottom navigation controller, shared across all admin pages.
/// Register once with `Get.put(BottomNavController())` and use
/// `Get.find<BottomNavController>()` from any page.
class BottomNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) {
    if (index == selectedIndex.value) return; // skip if already on the tab
    selectedIndex.value = index;
    _refreshTab(index);
  }

  void _refreshTab(int index) {
    // Always refresh the app bar pending count
    if (Get.isRegistered<AdminAppBarControllers>()) {
      Get.find<AdminAppBarControllers>().refreshData();
    }

    if (index == 0) {
      if (Get.isRegistered<AdminHomeController>()) {
        Get.find<AdminHomeController>().refreshData();
      }
    } else if (index == 1) {
      if (Get.isRegistered<ApproveController>()) {
        Get.find<ApproveController>().refreshData();
      }
    } else if (index == 2) {
      if (Get.isRegistered<AnnouncementController>()) {
        Get.find<AnnouncementController>().refreshData();
      }
    } else if (index == 4) {
      if (Get.isRegistered<AdminProfileController>()) {
        Get.find<AdminProfileController>().refreshData();
      }
    }
  }

  void resetToHome() {
    selectedIndex.value = 0;
    _refreshTab(0);
  }

  void gotoApprovePage(){
    selectedIndex.value = 1;
    _refreshTab(1);
  }

  void gotoNotificationPage(){
    selectedIndex.value = 2;
    _refreshTab(2);
  }

  void gotoEvalutionPage(){
    selectedIndex.value = 3;
    _refreshTab(3);
  }

  void gotoProfilesPage(){
    selectedIndex.value = 4;
    _refreshTab(4);
  }
}
