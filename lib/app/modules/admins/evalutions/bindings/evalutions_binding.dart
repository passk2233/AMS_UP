import 'package:get/get.dart';

import '../controllers/evalutions_controller.dart';

class EvalutionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EvalutionController>(
      () => EvalutionController(),
    );
  }
}
