import 'package:flutter/material.dart';
import 'package:frontend/app/modules/student/student_noti/views/booking_detail.dart';
import 'package:frontend/app/modules/student/student_noti/views/grade_noti.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/admin_noti_controller.dart';

class AdminNotiView extends GetView<AdminNotiController> {
  const AdminNotiView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdminNotiController>()) {
      Get.put(AdminNotiController());
    }

    return GetBuilder<AdminNotiController>(
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
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
                      itemBuilder: (context, index) {
                        final item = list[index];

                        if (item['type'] == 'Urgent') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ແຈ້ງເຕືອນດ່ວນ",
                                  style: TextStyle(
                                    color: AppColors.rejectRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildUrgentCard(
                                  item['title']!,
                                  item['sub']!,
                                  item['status']!,
                                  item['time']!,
                                  onTap: () =>
                                      Get.to(() => const GradeNotiView()),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildRecentCard(
                          icon: item['category'] == 'Academic'
                              ? Icons.stars_outlined
                              : Icons.assignment_turned_in_outlined,
                          iconColor: item['category'] == 'Academic'
                              ? AppColors.statsBlue
                              : AppColors.borderApproved,
                          title: item['title']!,
                          desc: item['desc']!,
                          time: item['time']!,
                          onTap: () {
                            if (item['title'] == "Grade Released") {
                              Get.to(() => const GradeNotiView());
                            } else if (item['title'] == "Booking Confirmed") {
                              Get.to(() => const BookingDetailView());
                            }
                          },
                        );
                      },
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

  Widget _buildUrgentCard(
    String title,
    String sub,
    String status,
    String time, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.rejectRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
            border:
                Border.all(color: AppColors.rejectRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rejectRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.rejectRed),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                              color: AppColors.rejectRed, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.rejectRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
    VoidCallback? onTap,
  }) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
