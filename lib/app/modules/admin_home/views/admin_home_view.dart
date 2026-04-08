import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/admin_home_controller.dart';

class AdminHomeView extends GetView<AdminHomeController> {
  const AdminHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdminHomeView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'AdminHomeView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
