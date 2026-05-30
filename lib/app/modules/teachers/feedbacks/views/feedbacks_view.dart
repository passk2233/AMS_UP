import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../controllers/feedbacks_controller.dart';

/// Teacher-facing list of comments students left during evaluations.
///
/// Per the CLAUDE.md privacy rule, no student identifier is displayed —
/// each card shows only the subject / group / semester context and the
/// verbatim comment text.
class FeedbacksView extends GetView<FeedbacksController> {
  const FeedbacksView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'ຄຳຄິດເຫັນ',
      trailing: AppIconBubble(
        icon: Icons.notifications_none_rounded,
        onTap: () => Get.toNamed('/teacher-noti'),
      ),
      body: _FeedbacksBody(controller: controller),
    );
  }
}

/// Loading / error / list switch for the feedbacks page body.
class _FeedbacksBody extends StatelessWidget {
  /// Source of reactive state.
  final FeedbacksController controller;

  const _FeedbacksBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return AppRefreshableLoader(
          onRefresh: controller.refreshData,
          child: const AppLoading.feedbacks(),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshData,
        );
      }
      return _FeedbacksList(controller: controller);
    });
  }
}

/// Pull-to-refresh wrapped list of [_FeedbackCard]s, with an empty-state
/// fallback when there are no comments yet.
class _FeedbacksList extends StatelessWidget {
  /// Source of reactive state.
  final FeedbacksController controller;

  const _FeedbacksList({required this.controller});

  @override
  Widget build(BuildContext context) {
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
            for (final item in controller.items)
              _FeedbackCard(item: item),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Single feedback card — subject heading, meta line, anonymous comment.
class _FeedbackCard extends StatelessWidget {
  /// One feedback row from the controller.
  final TeacherFeedbackItem item;

  const _FeedbackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final header = [
      item.subjectName,
      if (item.subjectCode.isNotEmpty) '(${item.subjectCode})',
    ].join(' ');

    final meta = [
      if (item.semesterLabel.isNotEmpty) item.semesterLabel,
      if (item.studentGroupName.isNotEmpty) item.studentGroupName,
    ].join(' • ');

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderLeftColor: AppColors.statsBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          // Question label + text
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.statsBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ຄຳຖາມ ${item.questionId}: ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statsBlue,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.questionText.isNotEmpty
                        ? item.questionText
                        : 'ຄຳຖາມທີ ${item.questionId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Student comment
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded,
                  size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.comment,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
