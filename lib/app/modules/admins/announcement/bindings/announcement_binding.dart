import 'package:get/get.dart';

import '../controllers/announcement_controller.dart';

/// GetX binding for [AnnouncementView] — lazily registers
/// [AnnouncementController] on first navigation.
class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnnouncementController>(AnnouncementController.new);
  }
}
