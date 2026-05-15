import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../controllers/teacher_evaluation_controller.dart';

class TeacherEvaluationView extends GetView<TeacherEvaluationController> {
  const TeacherEvaluationView({super.key});

  Color _getScoreColor(double score) {
    if (score >= 4.5) return AppColors.borderApproved;
    if (score >= 3.5) return AppColors.borderPending;
    if (score >= 2.5) return AppColors.statsBlue;
    return AppColors.rejectRed;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherEvaluationController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      title: 'ການປະເມີນ',
      trailing: AppIconBubble(
        icon: Icons.refresh_rounded,
        onTap: controller.refreshData,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.evaluation();
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
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _buildOverallScoreCard(controller.overallAverage),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppStatCard(
                      label: 'ການປະເມີນ',
                      value: '${controller.totalEvaluations}',
                      icon: Icons.people_alt_outlined,
                      color: AppColors.statsBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppStatCard(
                      label: 'ວິຊາ',
                      value: '${controller.totalSubjects}',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.borderPending,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'ການປະເມີນແຕ່ລະວິຊາ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              ...controller.subjectGroups.map((g) => _SubjectEvalCard(group: g)),
              if (controller.subjectGroups.isEmpty)
                const AppEmptyState(
                  icon: Icons.insert_chart_outlined,
                  title: 'ຍັງບໍ່ມີຂໍ້ມູນການປະເມີນ',
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

  Widget _buildOverallScoreCard(double average) {
    Color scoreColor = _getScoreColor(average);
    String label = 'ດີ';
    IconData emoji = Icons.thumb_up_alt_rounded;

    if (average < 3.0) {
      label = 'ຕ້ອງປັບປຸງ';
      emoji = Icons.trending_down_rounded;
    } else if (average < 4.0) {
      label = 'ປານກາງ';
      emoji = Icons.trending_flat_rounded;
    } else if (average >= 4.5) {
      label = 'ດີເລີດ';
      emoji = Icons.emoji_events_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ຄະແນນລວມ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(emoji, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: scoreColor, size: 24),
                const SizedBox(width: 6),
                Text(
                  average.toStringAsFixed(2),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
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

class _SubjectEvalCard extends StatelessWidget {
  final SubjectEvalGroup group;
  const _SubjectEvalCard({required this.group});

  Color _scoreColor(double score) {
    if (score >= 4.5) return AppColors.borderApproved;
    if (score >= 3.5) return AppColors.borderPending;
    if (score >= 2.5) return AppColors.statsBlue;
    return AppColors.rejectRed;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(group.averageScore);

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderLeftColor: scoreColor,
      borderLeftWidth: 5,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            '${group.subjectName} ${group.subjectCode.isNotEmpty ? '(${group.subjectCode})' : ''}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group.semesterLabel.isNotEmpty ||
                    group.studentGroupName.isNotEmpty)
                  Row(
                    children: [
                      if (group.semesterLabel.isNotEmpty) ...[
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(group.semesterLabel,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                      if (group.semesterLabel.isNotEmpty &&
                          group.studentGroupName.isNotEmpty)
                        const SizedBox(width: 10),
                      if (group.studentGroupName.isNotEmpty) ...[
                        Icon(Icons.group_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(group.studentGroupName,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 14, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            group.averageScore.toStringAsFixed(2),
                            style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${group.totalResponses} ຄຳຕອບ',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'ລາຍລະອຽດຄະແນນ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...group.questionScores.values.map((q) {
                    final pct = (q.average / 5.0).clamp(0.0, 1.0);
                    final barColor = _scoreColor(q.average);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  q.questionText,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                q.average.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: barColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (group.comments.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      children: [
                        Icon(Icons.format_quote_rounded,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          'ຄຳເຫັນຈາກນັກສຶກສາ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...group.comments.take(5).map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      color: Colors.grey.shade500)),
                              Expanded(
                                child: Text(
                                  c,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
