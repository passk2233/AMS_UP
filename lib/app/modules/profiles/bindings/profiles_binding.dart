import 'package:get/get.dart';

import '../controllers/profiles_controller.dart';

class ProfilesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfilesController>(
      () => ProfilesController(),
    );
  }
}
