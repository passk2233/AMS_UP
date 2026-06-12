import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../../score/controllers/score_controller.dart';

/// Horizontal scrolling chips — one per semester, newest first.
class SemesterChips extends StatelessWidget {
  /// Source of semester data + selection state.
  final ScoreController controller;

  const SemesterChips({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final groups = controller.semestersNewestFirst;
    if (groups.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: groups.map((s) {
          final selected = controller.selectedSemesterId.value == s.semasterId;
          final label = controller.chipLabelFor(s);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: () => controller.changeSemester(s.semasterId),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected
                    ? AppColors.statsBlue
                    : AppColors.cardBg,
                side: BorderSide(
                  color: selected ? AppColors.statsBlue : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.chipRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: const Size(0, AppColors.minTouchTarget),
                // Flat — the system bans Material elevation tiers. The selected
                // chip already reads via its filled background + bold label.
                elevation: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.line1,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (label.line2.isNotEmpty)
                    Text(
                      label.line2,
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
