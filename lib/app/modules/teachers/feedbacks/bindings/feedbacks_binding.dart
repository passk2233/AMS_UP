import 'package:get/get.dart';

import '../controllers/feedbacks_controller.dart';

/// GetX binding for [FeedbacksView] — lazily registers
/// [FeedbacksController] on first navigation.
class FeedbacksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedbacksController>(FeedbacksController.new);
  }
}
