import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/student_noti_controller.dart';

/// Student notification center.
///
/// Displays the user's notifications filtered by category (all / academic /
/// room booking) and renders an urgent-styled card for `Urgent` entries.
/// Tapping any item optimistically marks it read and routes to the relevant
/// detail screen.
class StudentNotiView extends GetView<StudentNotiController> {
  const StudentNotiView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StudentNotiController>()) {
      Get.put(StudentNotiController());
    }

    return GetBuilder<StudentNotiController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBg,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Get.back(),
              ),
              title: const Text(
                'ສູນແຈ້ງເຕືອນ',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
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
                Obx(() => AppFilterChipRow(
                      items: const [
                        AppFilterChip(label: 'ທັງໝົດ'),
                        AppFilterChip(label: 'ການສຶກສາ'),
                        AppFilterChip(label: 'ຈອງຫ້ອງ'),
                      ],
                      selectedIndex: controller.selectedFilterIndex.value,
                      onSelected: (i) =>
                          controller.selectedFilterIndex.value = i,
                    )),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const AppLoading.notifications();
                    }
                    if (controller.errorMessage.value.isNotEmpty) {
                      return AppErrorState(
                        message: controller.errorMessage.value,
                        onRetry: () => controller.onInit(),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: list.length,
                      itemBuilder: (context, index) => NotificationListItem(
                        item: list[index],
                        onMarkRead: controller.markAsRead,
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
