import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/score_controller.dart';

class ScoreView extends GetView<ScoreController> {
  const ScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ScoreController>()) {
      Get.put(ScoreController());
    }

    return GetBuilder<ScoreController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      withBackground: true,
      title: 'ຄະແນນ',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.score();
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.fetchData,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppProfileHeader(
                name: controller.displayName,
                subtitle: controller.studentCode,
                caption: controller
                        .currentUser.value?.student?.curriculum?.curriNameEng ??
                    controller
                        .currentUser.value?.student?.curriculum?.curriNameLao ??
                    '-',
                avatarImage: const AssetImage(AssetImages.profile2),
              ),
              const SizedBox(height: 20),
              AppStatsBanner(
                items: [
                  AppStatItem(
                    label: "GPA",
                    value: controller.gpa.toStringAsFixed(2),
                    suffix: "/4.00",
                    icon: Icons.bar_chart_rounded,
                  ),
                  AppStatItem(
                    label: "ໜ່ວຍກິດ",
                    value: controller.earnedCredits.toString(),
                    icon: Icons.credit_card_rounded,
                  ),
                  AppStatItem(
                    label: "ວິຊາ",
                    value: controller.enrollments.length.toString(),
                    icon: Icons.grid_view_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "ຄະແນນແຕ່ລະພາກຮຽນ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Obx(() => Row(
                      children: List.generate(8, (index) {
                        final selected =
                            controller.selectedTermIndex.value == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: OutlinedButton(
                            onPressed: () => controller.changeTerm(index),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: selected
                                  ? AppColors.statsBlue
                                  : AppColors.cardBg,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.statsBlue
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppColors.chipRadius),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              elevation: selected ? 4 : 0,
                            ),
                            child: Text(
                              "ພາກ ${index + 1}",
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    )),
              ),
              const Divider(),
              const SizedBox(height: 12),
              _buildScoreList(),
            ],
          ),
        );
      }),
    );
        },
      ),
    );
  }

  Widget _buildScoreList() {
    final items = controller.enrollments;
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'ບໍ່ພົບຄະແນນ',
        subtitle: 'ຄະແນນຈະສະແດງຢູ່ບ່ອນນີ້',
      );
    }

    return Column(
      children: items.map((e) {
        final sub = e.studyPlan?.subject;
        final teacher = e.studyPlan?.teacher;
        final code = sub?.subjectCode ?? '-';
        final credit = sub?.credit ?? 0;
        final title = sub?.nameLao ?? sub?.nameEng ?? '-';
        final teacherName = teacher?.nameLao ?? teacher?.nameEng ?? '-';
        final grade = e.grade ?? '-';
        final color = grade == 'A'
            ? AppColors.statsBlue
            : (grade == 'B+' || grade == 'B')
                ? AppColors.borderApproved
                : AppColors.borderPending;

        return AppSurfaceCard(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          borderLeftColor: color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$code  ~ $credit ໜ່ວຍກິດ",
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      teacherName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      grade,
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _gradeLabel(grade),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _gradeLabel(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 'ດີເລີດ';
      case 'B+':
      case 'B':
        return 'ດີ';
      case 'C+':
      case 'C':
        return 'ປານກາງ';
      case 'D+':
      case 'D':
        return 'ພໍຜ່ານ';
      case 'F':
        return 'ຕົກ';
      default:
        return '-';
    }
  }
}
