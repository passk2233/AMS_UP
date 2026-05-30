import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// GetX binding for [AuthView] — lazily registers [AuthController] on first
/// navigation. Always re-registered (not `permanent`) so signing out
/// disposes the previous form state.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(AuthController.new);
  }
}
