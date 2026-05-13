import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'teacher_bottom_nav_controller.dart';

class TeacherBottomNavBar extends StatelessWidget {
  const TeacherBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.isRegistered<TeacherBottomNavController>()
        ? Get.find<TeacherBottomNavController>()
        : Get.put(TeacherBottomNavController(), permanent: true);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Obx(
          () => BottomNavigationBar(
            currentIndex: navCtrl.selectedIndex.value,
            onTap: navCtrl.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month), label: "Schedule"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.book), label: "Booking"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.star), label: "Evaluation"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}
