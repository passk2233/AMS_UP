import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../../teacher_evaluation/controllers/teacher_evaluation_controller.dart';
import 'eval_score_colors.dart';

/// Expandable per-subject evaluation card — collapses to a summary row,
/// expands into per-question score bars and (k-anonymous) student comments.
class SubjectEvalCard extends StatelessWidget {
  /// Source subject group.
  final SubjectEvalGroup group;

  const SubjectEvalCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final scoreColor = evalScoreColor(group.averageScore);
    final scoreText = evalScoreTextColor(group.averageScore);

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
                  ...group.questionScores.values.map(
                    (q) => _QuestionScoreBar(score: q),
                  ),
                  // K-anonymity guard: a single verbatim comment next to the
                  // student-group name could identify its author, so the
                  // comments only show once at least 3 students responded.
                  if (group.numRespondents >= 3 &&
                      group.comments.isNotEmpty)
                    _CommentsSection(comments: group.comments)
                  else if (group.comments.isNotEmpty)
                    const _CommentsHiddenNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One question row — text, numeric average, and a heat-colored progress bar.
class _QuestionScoreBar extends StatelessWidget {
  /// Per-question aggregate.
  final QScore score;

  const _QuestionScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final q = score;
    final pct = (q.average / 5.0).clamp(0.0, 1.0);
    final barColor = evalScoreColor(q.average);
    final numColor = evalScoreTextColor(q.average);
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
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anonymous comments (max 5) shown when the k-anonymity floor is met.
class _CommentsSection extends StatelessWidget {
  /// Raw comment strings.
  final List<String> comments;

  const _CommentsSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ...comments.take(5).map(
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
      ],
    );
  }
}

/// Lock note shown instead of comments when fewer than 3 students responded.
class _CommentsHiddenNote extends StatelessWidget {
  const _CommentsHiddenNote();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}
