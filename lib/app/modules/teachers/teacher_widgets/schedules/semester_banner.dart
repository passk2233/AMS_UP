import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';

import '../../schedules/controllers/schedules_controller.dart';

/// Blue-tinted banner showing the active semester label + date range.
class SemesterBanner extends StatelessWidget {
  /// Source of the semester label.
  final SchedulesController controller;

  const SemesterBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final label = controller.semesterLabel;
      final range = controller.semesterDateRange;
      if (label.isEmpty && range.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.statsBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
          ),
          child: Row(
            children: [
              Icon(Icons.event_note_rounded,
                  size: 18, color: AppColors.statsBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label.isNotEmpty)
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (range.isNotEmpty)
                      Text(
                        range,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
