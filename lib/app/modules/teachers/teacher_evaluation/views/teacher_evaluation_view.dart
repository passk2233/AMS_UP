import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../controllers/teacher_evaluation_controller.dart';

/// Heat-scale color for an evaluation score — fill / tint / icon use only.
Color _scoreColor(double score) {
  if (score >= 4.5) return AppColors.success; // emerald — strong
  if (score >= 3.5) return AppColors.warning; // amber — medium
  if (score >= 2.5) return AppColors.info; // blue — fair
  return AppColors.danger; // red — weak
}

/// AA-safe foreground for a score used as TEXT or an icon on a WHITE surface.
/// Amber (#f59e0b) is ~2:1 on white and must never be a text color, so the
/// amber band falls back to ink; the tinted bubble / bar still carries the hue.
Color _scoreTextColor(double score) {
  final c = _scoreColor(score);
  return c == AppColors.warning ? AppColors.textPrimary : c;
}

/// AA-safe foreground for text / icons placed on a SOLID score-color fill.
/// White on amber is 2.15:1 and fails; ink clears AA there (7.94:1).
Color _onScoreFill(double score) {
  return _scoreColor(score) == AppColors.warning
      ? AppColors.textPrimary
      : Colors.white;
}

class TeacherEvaluationView extends GetView<TeacherEvaluationController> {
  const TeacherEvaluationView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherEvaluationController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
            title: 'ການປະເມີນ',
            trailing: const NotiBellButton(route: '/teacher-noti'),
            body: Obx(() {
              if (controller.isLoading.value) {
                return AppRefreshableLoader(
                  onRefresh: controller.refreshData,
                  child: const AppLoading.evaluation(),
                );
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
                    parent: BouncingScrollPhysics(),
                  ),
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
                    if (controller.semesterTrendDelta != null) ...[
                      const SizedBox(height: 12),
                      _SemesterTrendCard(
                        current: controller.currentSemesterAverage ?? 0,
                        previous: controller.previousSemesterAverage ?? 0,
                        delta: controller.semesterTrendDelta!,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.l),
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                        bottom: AppSpacing.s + 4,
                      ),
                      child: Text(
                        'ການປະເມີນແຕ່ລະວິຊາ',
                        style: AppTypography.heading,
                      ),
                    ),
                    ...controller.subjectGroups.map(
                      (g) => _SubjectEvalCard(group: g),
                    ),
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
    final Color scoreColor = _scoreColor(average);
    final Color onFill = _onScoreFill(average);
    final Color pillText = _scoreTextColor(average);
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
                Text(
                  'ຄະແນນລວມ',
                  style: TextStyle(
                    color: onFill,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(emoji, color: onFill.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: onFill.withValues(alpha: 0.7),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                Icon(Icons.star_rounded, color: pillText, size: 24),
                const SizedBox(width: 6),
                Text(
                  average.toStringAsFixed(2),
                  style: TextStyle(
                    color: pillText,
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

class _SemesterTrendCard extends StatelessWidget {
  final double current;
  final double previous;
  final double delta;
  const _SemesterTrendCard({
    required this.current,
    required this.previous,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final improved = delta > 0.05;
    final declined = delta < -0.05;
    final color = improved
        ? AppColors.borderApproved
        : declined
        ? AppColors.rejectRed
        : AppColors.textSecondary;
    final icon = improved
        ? Icons.trending_up_rounded
        : declined
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;
    final label = improved
        ? 'ດີຂຶ້ນ'
        : declined
        ? 'ຫຼຸດລົງ'
        : 'ບໍ່ປ່ຽນ';
    final sign = delta > 0 ? '+' : '';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ທຽບກັບພາກຮຽນກ່ອນ — $label',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ກ່ອນ ${previous.toStringAsFixed(2)} → ປັດຈຸບັນ ${current.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${delta.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
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

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(group.averageScore);
    final scoreText = _scoreTextColor(group.averageScore);

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.semesterLabel,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (group.semesterLabel.isNotEmpty &&
                          group.studentGroupName.isNotEmpty)
                        const SizedBox(width: 10),
                      if (group.studentGroupName.isNotEmpty) ...[
                        Icon(
                          Icons.group_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.studentGroupName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: scoreText),
                          const SizedBox(width: 4),
                          Text(
                            group.averageScore.toStringAsFixed(2),
                            style: TextStyle(
                              color: scoreText,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.numRespondents} ຄົນ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
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
                    final numColor = _scoreTextColor(q.average);
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
                                  color: numColor,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                barColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // K-anonymity guard: a single verbatim comment next to the
                  // student-group name could identify its author, so the
                  // comments only show once at least 3 students responded.
                  if (group.numRespondents >= 3 &&
                      group.comments.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
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
                    ...group.comments
                        .take(5)
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                                Expanded(
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ] else if (group.comments.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ເຊື່ອງຄຳເຫັນເພື່ອປົກປ້ອງຄວາມເປັນສ່ວນຕົວ '
                            '(ມີຜູ້ປະເມີນໜ້ອຍກວ່າ 3 ຄົນ)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
