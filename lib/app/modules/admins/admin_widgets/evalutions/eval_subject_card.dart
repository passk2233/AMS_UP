import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_scoring.dart';

/// Expandable card for one subject — collapses to a summary row, expands
/// into per-question breakdown + anonymous comments.
class EvalSubjectCard extends StatelessWidget {
  /// Source summary.
  final SubjectEvalSummary subject;

  const EvalSubjectCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final avg = subject.averageScore;
    final color = EvalScoring.colorFor(avg);
    return Container(
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
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: _SubjectScoreBadge(score: avg, color: color),
          title: Text(
            subject.subjectName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: _SubjectSubtitle(subject: subject),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            _QuestionBreakdown(scores: subject.questionScores),
            if (subject.evaluationDetails.any(
              (d) => d.comment != null && d.comment!.isNotEmpty,
            )) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _CommentsSection(
                comments: subject.evaluationDetails
                    .where((d) => d.comment != null && d.comment!.isNotEmpty)
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 40×40 square showing the subject's average score in [EvalSubjectCard].
class _SubjectScoreBadge extends StatelessWidget {
  /// Average score (0..5).
  final double score;

  /// Tint applied to text and tinted background.
  final Color color;

  const _SubjectScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Subtitle below the subject name — code, semester / group chips, response
/// count.
class _SubjectSubtitle extends StatelessWidget {
  /// Source summary.
  final SubjectEvalSummary subject;

  const _SubjectSubtitle({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subject.subjectCode.isNotEmpty)
          Text(
            subject.subjectCode,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            _MetaChip(
              icon: Icons.calendar_today_outlined,
              text: subject.semesterLabel,
              color: AppColors.info,
            ),
            const SizedBox(width: 6),
            if (subject.studentGroupName.isNotEmpty)
              _MetaChip(
                icon: Icons.group_outlined,
                text: subject.studentGroupName,
                color: AppColors.borderApproved,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${subject.totalResponses} ການປະເມີນ',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Small color-tinted meta chip used in [_SubjectSubtitle].
class _MetaChip extends StatelessWidget {
  /// Glyph.
  final IconData icon;

  /// Caption.
  final String text;

  /// Tint applied to background + glyph + text.
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-question breakdown rendered inside the expanded [EvalSubjectCard].
class _QuestionBreakdown extends StatelessWidget {
  /// Per-question score aggregates.
  final Map<int, QuestionScore> scores;

  const _QuestionBreakdown({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in scores.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.value.questionText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.value.average.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: EvalScoring.textColorFor(entry.value.average),
                  ),
                ),
                const Text(
                  '/5',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Anonymous comments section rendered inside the expanded [EvalSubjectCard].
class _CommentsSection extends StatelessWidget {
  /// Comments to render (already filtered to non-empty entries).
  final List<AnonymousEvalDetail> comments;

  const _CommentsSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 4),
            Text(
              'ຄຳເຫັນ (ບໍ່ລະບຸຕົວຕົນ)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final d in comments) _CommentTile(text: d.comment!),
      ],
    );
  }
}

/// One italic comment tile inside [_CommentsSection].
class _CommentTile extends StatelessWidget {
  /// Comment body.
  final String text;

  const _CommentTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
