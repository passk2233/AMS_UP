import 'package:get/get.dart';

import '../controllers/approve_controller.dart';

/// GetX binding for [ApproveView] — lazily registers [ApproveController].
class ApproveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApproveController>(ApproveController.new);
  }
}
