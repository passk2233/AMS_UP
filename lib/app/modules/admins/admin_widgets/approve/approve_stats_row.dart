import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../approve/controllers/approve_controller.dart';

/// Horizontal row with three [_StatChip]s (pending / approved / rejected).
class ApproveStatsRow extends StatelessWidget {
  /// Source of reactive stat counters.
  final ApproveController controller;

  const ApproveStatsRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          _StatChip(
            icon: Icons.hourglass_top_rounded,
            label: 'ລໍຖ້າ',
            count: controller.pendingCount.value,
            color: AppColors.borderPending,
          ),
          const SizedBox(width: AppSpacing.s),
          _StatChip(
            icon: Icons.check_circle_outline_rounded,
            label: 'ອະນຸມັດ',
            count: controller.approvedCount.value,
            color: AppColors.borderApproved,
          ),
          const SizedBox(width: AppSpacing.s),
          _StatChip(
            icon: Icons.cancel_outlined,
            label: 'ປະຕິເສດ',
            count: controller.rejectedCount.value,
            color: AppColors.rejectRed,
          ),
        ],
      ),
    );
  }
}

/// One stat tile inside [ApproveStatsRow] — leading icon bubble + count +
/// label.
class _StatChip extends StatelessWidget {
  /// Glyph rendered inside the colored bubble.
  final IconData icon;

  /// Lower caption.
  final String label;

  /// Large value shown above the label.
  final int count;

  /// Accent applied to the icon bubble, the count text, and the shadow.
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: AppColors.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s + 4,
          horizontal: AppSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    // Numbers stay high-contrast ink; the hue lives in the icon
                    // bubble. Amber (#f59e0b) as text is ~2:1 and fails AA — the
                    // pending count is the admin's most-read number, so it must
                    // not be the lowest-contrast thing on screen.
                    style: AppTypography.heading,
                  ),
                  Text(
                    label,
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
