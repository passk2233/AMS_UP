import 'package:get/get.dart';

import '../controllers/feedbacks_controller.dart';

class FeedbacksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeedbacksController>(
      () => FeedbacksController(),
    );
  }
}
