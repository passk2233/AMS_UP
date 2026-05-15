import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../controllers/feedbacks_controller.dart';

class FeedbacksView extends GetView<FeedbacksController> {
  const FeedbacksView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeedbacksController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      title: 'ຄຳຄິດເຫັນ',
      trailing: AppIconBubble(
        icon: Icons.refresh_rounded,
        onTap: controller.refreshData,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.feedbacks();
        }
        final err = controller.errorMessage.value;
        if (err.isNotEmpty) {
          return AppErrorState(
            message: err,
            onRetry: controller.refreshData,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (controller.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: AppEmptyState(
                    icon: Icons.feedback_outlined,
                    title: 'ຍັງບໍ່ມີຄຳຄິດເຫັນ',
                  ),
                )
              else
                ...controller.items.map((it) {
                  final header = [
                    it.subjectName,
                    if (it.subjectCode.isNotEmpty) '(${it.subjectCode})',
                  ].join(' ');
                  final meta = [
                    if (it.semesterLabel.isNotEmpty) it.semesterLabel,
                    if (it.studentGroupName.isNotEmpty) it.studentGroupName,
                  ].join(' • ');
                  return AppSurfaceCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    borderLeftColor: AppColors.statsBlue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          header,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.statsBlue,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          it.comment,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 20),
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
