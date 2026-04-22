import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/teacher_home_controller.dart';

class TeacherHomeView extends GetView<TeacherHomeController> {
  const TeacherHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeacherHomeView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'TeacherHomeView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
