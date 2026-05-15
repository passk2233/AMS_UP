import 'package:get/get.dart';

import '../bottom_nav_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../approve/controllers/approve_controller.dart';
import '../../announcement/controllers/announcement_controller.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import '../../admin_profile/controllers/admin_profile_controller.dart';
import '../../../../widgets/admin_app_bar/admin_app_bar_bindings.dart';

class AdminShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BottomNavController(), permanent: true);
    Get.put(AdminHomeController());
    Get.put(ApproveController());
    Get.put(AnnouncementController());
    Get.put(EvalutionController());
    Get.put(AdminProfileController());
    AdminAppBarBinding().dependencies();
  }
}
