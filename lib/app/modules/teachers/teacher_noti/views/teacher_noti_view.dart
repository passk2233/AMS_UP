import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../controllers/teacher_noti_controller.dart';

/// Teacher notification center.
///
/// Displays the user's notifications filtered by category (all / academic /
/// room booking) and renders an urgent-styled card for `Urgent` entries.
/// Tapping any item optimistically marks it read and routes to the relevant
/// detail screen.
class TeacherNotiView extends GetView<TeacherNotiController> {
  const TeacherNotiView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TeacherNotiController>()) {
      Get.put(TeacherNotiController());
    }
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: Get.back,
        ),
        title: const Text(
          'ສູນແຈ້ງເຕືອນ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bulk badge-clear — visible only while something is unread.
          Obx(
            () => controller.unreadCount == 0
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'ໝາຍວ່າອ່ານທັງໝົດ',
                    icon: const Icon(
                      Icons.done_all,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: controller.markAllAsRead,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          _NotiFilterRow(controller: controller),
          Expanded(child: _NotiBody(controller: controller)),
        ],
      ),
    );
  }
}

/// Category filter chips (all / academic / booking) bound to
/// [TeacherNotiController.selectedFilterIndex].
class _NotiFilterRow extends StatelessWidget {
  /// Source of reactive selection state.
  final TeacherNotiController controller;

  const _NotiFilterRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppFilterChipRow(
        items: const [
          AppFilterChip(label: 'ທັງໝົດ'),
          AppFilterChip(label: 'ການສຶກສາ'),
          AppFilterChip(label: 'ຈອງຫ້ອງ'),
        ],
        selectedIndex: controller.selectedFilterIndex.value,
        onSelected: (i) => controller.selectedFilterIndex.value = i,
      ),
    );
  }
}

/// Loading / error / empty / list switch for the notification body.
class _NotiBody extends StatelessWidget {
  /// Source of reactive state.
  final TeacherNotiController controller;

  const _NotiBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading.notifications();
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.fetchNotifications,
        );
      }
      final list = controller.filteredNotifications;
      if (list.isEmpty) {
        return const AppEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'ບໍ່ມີການແຈ້ງເຕືອນ',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: list.length,
        itemBuilder: (context, index) => NotificationListItem(
          item: list[index],
          onMarkRead: controller.markAsRead,
        ),
      );
    });
  }
}
