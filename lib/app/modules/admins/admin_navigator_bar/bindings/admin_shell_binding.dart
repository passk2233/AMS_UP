import 'package:get/get.dart';

import '../../../../widgets/admin_app_bar/admin_app_bar_bindings.dart';
import '../../admin_profile/controllers/admin_profile_controller.dart';
import '../../announcement/controllers/announcement_controller.dart';
import '../../approve/controllers/approve_controller.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../bottom_nav_controller.dart';

/// GetX binding for [AdminShellView].
///
/// Eagerly registers every tab's controller so [IndexedStack]-preserved
/// state is available immediately on first build (without it, the bottom
/// nav's badge wouldn't update until the user visited each tab once).
/// [BottomNavController] is `permanent` so it outlives shell rebuilds.
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
