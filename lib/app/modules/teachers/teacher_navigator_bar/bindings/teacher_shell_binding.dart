import 'package:get/get.dart';

import '../../booking/controllers/booking_controller.dart';
import '../../schedules/controllers/schedules_controller.dart';
import '../../teacher_evaluation/controllers/teacher_evaluation_controller.dart';
import '../../teacher_home/controllers/teacher_home_controller.dart';
import '../../teacher_profile/controllers/teacher_profile_controller.dart';
import '../teacher_bottom_nav_controller.dart';

/// GetX binding for [TeacherShellView].
///
/// Eagerly registers every tab's controller so [IndexedStack]-preserved
/// state is available immediately on first build.
/// [TeacherBottomNavController] is `permanent` so it outlives shell
/// rebuilds.
class TeacherShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TeacherBottomNavController(), permanent: true);
    Get.put(TeacherHomeController());
    Get.put(SchedulesController());
    Get.put(BookingController());
    Get.put(TeacherEvaluationController());
    Get.put(TeacherProfileController());
  }
}

