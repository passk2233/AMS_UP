import 'package:get/get.dart';

import '../teacher_home/controllers/teacher_home_controller.dart';
import '../schedules/controllers/schedules_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../teacher_evaluation/controllers/teacher_evaluation_controller.dart';
import '../../profiles/controllers/profiles_controller.dart';

class TeacherBottomNavController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTab(int index) {
    if (index == selectedIndex.value) return;
    selectedIndex.value = index;
    _refreshTab(index);
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        if (Get.isRegistered<TeacherHomeController>()) {
          Get.find<TeacherHomeController>().refreshData();
        }
        break;
      case 1:
        if (Get.isRegistered<SchedulesController>()) {
          Get.find<SchedulesController>().refreshData();
        }
        break;
      case 2:
        if (Get.isRegistered<BookingController>()) {
          Get.find<BookingController>().refreshData();
        }
        break;
      case 3:
        if (Get.isRegistered<TeacherEvaluationController>()) {
          Get.find<TeacherEvaluationController>().refreshData();
        }
        break;
      case 4:
        if (Get.isRegistered<ProfilesController>()) {
          Get.find<ProfilesController>().refreshData();
        }
        break;
    }
  }

  void resetToHome() {
    selectedIndex.value = 0;
    _refreshTab(0);
  }
}
