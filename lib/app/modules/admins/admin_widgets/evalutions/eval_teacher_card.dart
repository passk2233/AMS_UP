import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_scoring.dart';

/// One teacher row card on the results list. Tapping opens the detail page.
class EvalTeacherCard extends StatelessWidget {
  /// Source summary.
  final TeacherEvalSummary summary;

  /// 1-based rank in the sorted list.
  final int rank;

  /// Tap handler.
  final VoidCallback onTap;

  const EvalTeacherCard({
    super.key,
    required this.summary,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = summary.teacher;
    final avg = summary.averageScore;
    final color = EvalScoring.colorFor(avg);
    final label = EvalScoring.labelFor(avg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RankBubble(rank: rank, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${teacher.nameLao} ${teacher.surnameLao}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher.department?.deptNameLao ?? teacher.teacherCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.subjectNames.length} ວິຊາ • ${summary.totalResponses} ການປະເມີນ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        EvalStarRow(score: avg),
                        const SizedBox(width: 6),
                        Text(
                          avg.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        EvalRatingTag(label: label, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient rank bubble shown on the left of [EvalTeacherCard].
class _RankBubble extends StatelessWidget {
  /// Rank number rendered inside.
  final int rank;

  /// Tint matching the teacher's average score.
  final Color color;

  const _RankBubble({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
