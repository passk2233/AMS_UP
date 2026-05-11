import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/student_home_controller.dart';

class HomeStudentView extends GetView<HomeStudentController> {
  const HomeStudentView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => controller.currentPage),
      bottomNavigationBar: controller.buildBottomNavigation(),
    );
  }
}
