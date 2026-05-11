import 'package:get/get.dart';

import '../controllers/faculty_feedback_controller.dart';

class FacultyFeedbackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FacultyFeedbackController>(
      () => FacultyFeedbackController(),
    );
  }
}
