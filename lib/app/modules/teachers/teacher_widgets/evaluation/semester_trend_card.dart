import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

/// "Compared with last semester" trend card — direction icon, before → after
/// scores, and the signed delta.
class SemesterTrendCard extends StatelessWidget {
  /// Current semester average.
  final double current;

  /// Previous semester average.
  final double previous;

  /// current − previous.
  final double delta;

  const SemesterTrendCard({
    super.key,
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
