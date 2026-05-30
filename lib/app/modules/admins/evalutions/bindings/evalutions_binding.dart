import 'package:get/get.dart';

import '../controllers/evalutions_controller.dart';

/// GetX binding for [EvalutionView] — lazily registers [EvalutionController].
class EvalutionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EvalutionController>(EvalutionController.new);
  }
}
