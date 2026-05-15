import 'package:get/get.dart';

import '../teacher_bottom_nav_controller.dart';
import '../../teacher_home/controllers/teacher_home_controller.dart';
import '../../schedules/controllers/schedules_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../teacher_evaluation/controllers/teacher_evaluation_controller.dart';
import '../../teacher_profile/controllers/teacher_profile_controller.dart';

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

