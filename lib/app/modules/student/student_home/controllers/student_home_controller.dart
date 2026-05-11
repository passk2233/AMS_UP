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
    "Home",
    "Schedule",
    "Booking",
    "Score",
    "Profile",
  ];

  // แก้ไขตรงนี้: เปลี่ยนจาก HomeStudentView เป็น StudentHomeView
  final List<Widget> pages = [
    const HomePage(), // หน้าที่โชว์แบนเนอร์ หรือเมนูต่างๆ
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
    print("Logout clicked");
    // Get.offAllNamed('/login');
  }

  // ฟังก์ชันสร้าง BottomBar ที่คุณต้องการ
  Widget buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Obx(
          () => BottomNavigationBar(
            currentIndex: selectedIndex.value,
            onTap: changePage,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: "Schedule",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: "Booking"),
              BottomNavigationBarItem(icon: Icon(Icons.star), label: "Score"),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
