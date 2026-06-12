import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_scoring.dart';
import 'eval_subject_card.dart';

/// Detail page that drills into one teacher's per-subject results.
class EvalTeacherDetailPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const EvalTeacherDetailPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.selectedTeacherSummary.value;
      if (summary == null) return const SizedBox.shrink();
      final teacher = summary.teacher;
      return Column(
        children: [
          _DetailTopBar(
            teacherName: '${teacher.nameLao} ${teacher.surnameLao}',
            onBack: controller.closeTeacherDetail,
          ),
          _TeacherSummaryCard(summary: summary),
          const SizedBox(height: 12),
          _SubjectsHeader(controller: controller),
          const SizedBox(height: 8),
          Expanded(child: _SubjectList(controller: controller)),
        ],
      );
    });
  }
}

/// Back + title row at the top of [EvalTeacherDetailPage].
class _DetailTopBar extends StatelessWidget {
  /// Title text (teacher full name).
  final String teacherName;

  /// Back button tap handler.
  final VoidCallback onBack;

  const _DetailTopBar({required this.teacherName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              teacherName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// White card under the top bar showing the teacher's headline score, dept,
/// star rating, and the total evaluation count.
class _TeacherSummaryCard extends StatelessWidget {
  /// Source summary.
  final TeacherEvalSummary summary;

  const _TeacherSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final teacher = summary.teacher;
    final avg = summary.averageScore;
    final color = EvalScoring.colorFor(avg);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.department?.deptNameLao ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teacher.teacherCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    EvalStarRow(score: avg),
                    const SizedBox(width: 8),
                    EvalRatingTag(
                      label: EvalScoring.labelFor(avg),
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${summary.totalResponses}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'ການປະເມີນ',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "ວິຊາທີ່ສອນ (N)" heading above the subjects list.
class _SubjectsHeader extends StatelessWidget {
  /// Source of the reactive subjects count.
  final EvalutionController controller;

  const _SubjectsHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Obx(
          () => Text(
            'ວິຊາທີ່ສອນ (${controller.selectedTeacherSubjects.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical list of [EvalSubjectCard]s.
class _SubjectList extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _SubjectList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjects = controller.selectedTeacherSubjects;
      if (subjects.isEmpty) {
        return const AppEmptyState(
          icon: Icons.school_outlined,
          title: 'ບໍ່ມີຂໍ້ມູນວິຊາ',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: subjects.length,
        itemBuilder: (_, i) => EvalSubjectCard(subject: subjects[i]),
      );
    });
  }
}
