import 'package:flutter/material.dart';
import 'package:frontend/app/modules/student/student_home/views/home_page.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/student/Booking_student/views/booking_student_view.dart';
import 'package:frontend/app/modules/student/profile_student/views/profile_student_view.dart';
import 'package:frontend/app/modules/student/schedule_student/views/schedule_student_view.dart';
import 'package:frontend/app/modules/student/score/views/score_view.dart';

class HomeStudentController extends GetxController {
  final selectedIndex = 0.obs;

  final List<String> appBarTitles = [
    "ໜ້າຫຼັກ",
    "ຕາຕະລາງ",
    "ຈອງຫ້ອງ",
    "ຄະແນນ",
    "ໂປຣໄຟລ໌",
  ];

  // ໜ້າທັງໝົດທີ່ຈະສະແດງໃນ IndexedStack
  final List<Widget> pages = [
    const HomePage(), // ໜ້າແບນເນີ ແລະ ເມນູ
    const ScheduleStudentView(),
    const BookingStudentView(),
    const ScoreView(),
    const ProfileStudentView(),
  ];

  String get currentTitle => appBarTitles[selectedIndex.value];
  Widget get currentPage => pages[selectedIndex.value];

  void changePage(int index) {
    selectedIndex.value = index;
  }

  void onLogout() {
    debugPrint("Logout clicked");
    // Get.offAllNamed('/login');
  }
}
