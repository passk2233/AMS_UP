import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

/// Registers the [SplashController] for the boot-gate route.
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
