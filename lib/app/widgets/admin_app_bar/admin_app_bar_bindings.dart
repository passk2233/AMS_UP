import 'package:get/get.dart';
import 'package:frontend/app/widgets/admin_app_bar/admin_app_bar_controllers.dart';

class AdminAppBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AdminAppBarControllers>(AdminAppBarControllers());
  }
}