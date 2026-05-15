import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/home_page_controller.dart';

class HomePage extends GetView<HomePageController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomePageController>()) {
      Get.put(HomePageController());
    }

    return GetBuilder<HomePageController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      withBackground: true,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.dashboard();
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.fetchDashboard,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppGreetingHeader(
                greeting: "ສະບາຍດີ, ${controller.displayName} 👋",
                subtitle: controller.currentDate,
                trailing: AppIconBubble(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Get.toNamed('/student-noti'),
                ),
              ),
              const SizedBox(height: 25),
              AppStatsBanner(
                items: const [
                  AppStatItem(
                    label: "ພາກຮຽນ",
                    value: "2026",
                    icon: Icons.calendar_today_rounded,
                  ),
                  AppStatItem(
                    label: "ຍິນດີຕ້ອນຮັບ",
                    value: "👋",
                    icon: Icons.celebration_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: AppStatCard(
                      label: "ຫ້ອງຮຽນ",
                      value: "${controller.totalClasses}",
                      icon: Icons.school_rounded,
                      color: AppColors.statsBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppStatCard(
                      label: "ວິຊາ",
                      value: "${controller.totalSubjects}",
                      icon: Icons.book_rounded,
                      color: AppColors.borderApproved,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppStatCard(
                      label: "GPA",
                      value: controller.gpa.toStringAsFixed(2),
                      icon: Icons.bar_chart_rounded,
                      color: AppColors.borderPending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                "ຫ້ອງຮຽນມື້ນີ້",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              if (controller.todayClasses.isEmpty)
                const AppEmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'ບໍ່ມີຫ້ອງຮຽນມື້ນີ້',
                )
              else
                ...controller.todayClasses.map(
                  (cls) => AppClassCard(
                    title: cls['subject'] ?? '',
                    time: cls['time'],
                    location: cls['room'],
                    color: AppColors.statsBlue,
                  ),
                ),
            ],
          ),
        );
      }),
    );
        },
      ),
    );
  }
}
