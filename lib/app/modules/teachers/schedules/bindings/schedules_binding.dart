import 'package:get/get.dart';

import '../controllers/schedules_controller.dart';

/// GetX binding for [SchedulesView] — lazily registers
/// [SchedulesController] on first navigation.
class SchedulesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SchedulesController>(SchedulesController.new);
  }
}
