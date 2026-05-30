import 'package:flutter/material.dart';
import 'package:frontend/app/routes/app_pages.dart';
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
          return AppRefreshableLoader(
            onRefresh: controller.fetchDashboard,
            child: const AppLoading.dashboard(),
          );
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
              const SizedBox(height: AppSpacing.l + 2),
              Obx(() {
                if (!controller.isEvaluationWindowOpen.value) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.l + 2),
                  child: AppPrimaryButton(
                    label: 'ປະເມີນອາຈານ',
                    icon: Icons.rate_review_rounded,
                    // Refresh the gate after returning so the button hides
                    // if admin closed the window while we were away.
                    onPressed: () async {
                      await Get.toNamed(Routes.FACULTY_FEEDBACK);
                      await controller.refreshEvaluationWindow();
                    },
                  ),
                );
              }),
              const Text("ຫ້ອງຮຽນມື້ນີ້", style: AppTypography.heading),
              const SizedBox(height: AppSpacing.s + 6),
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

