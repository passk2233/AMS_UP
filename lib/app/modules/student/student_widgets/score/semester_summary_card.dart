import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../../score/controllers/score_controller.dart';

/// Term + cumulative GPA summary card under the score list.
class SemesterSummaryCard extends StatelessWidget {
  /// Source of the selected-semester aggregates.
  final ScoreController controller;

  const SemesterSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SummaryColumn(
                title: 'ລວມເທີມ',
                detail:
                    '${controller.selectedSemesterCredits} ໜ່ວຍກິດ · ${controller.selectedSemesterSubjects} ວິຊາ',
                metricLabel: 'GPA',
                metricValue: controller.selectedSemesterGpa.toStringAsFixed(2),
                color: AppColors.statsBlue,
              ),
            ),
            const VerticalDivider(width: 24),
            Expanded(
              child: _SummaryColumn(
                title: 'ລວມສະສົມ',
                detail: '${controller.selectedCumulativeCredits} ໜ່ວຍກິດ',
                metricLabel: 'CGPA',
                metricValue: controller.selectedCumulativeGpa.toStringAsFixed(
                  2,
                ),
                color: AppColors.borderApproved,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One column inside [SemesterSummaryCard].
class _SummaryColumn extends StatelessWidget {
  final String title;
  final String detail;
  final String metricLabel;
  final String metricValue;
  final Color color;

  const _SummaryColumn({
    required this.title,
    required this.detail,
    required this.metricLabel,
    required this.metricValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$metricLabel ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              metricValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
