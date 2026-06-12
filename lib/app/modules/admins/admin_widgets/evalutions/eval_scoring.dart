import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';

/// Tiny utility for the (score → color, score → label) mapping used in
/// multiple places.
abstract class EvalScoring {
  /// Color for a 0..5 score:
  /// - 4.0+ → green
  /// - 3.0+ → blue
  /// - 2.0+ → amber
  /// - else → red
  static Color colorFor(double s) {
    if (s >= 4.0) return AppColors.success;
    if (s >= 3.0) return AppColors.info; // was off-palette #3B82F6
    if (s >= 2.0) return AppColors.warning; // was raw #F59E0B
    return AppColors.danger;
  }

  /// AA-safe foreground for a score used as TEXT on a white / tinted surface.
  /// Amber (#f59e0b) is ~2:1 on white and fails; the amber band falls back to
  /// ink. Use this anywhere [colorFor] would be a text color, not a fill/tint.
  static Color textColorFor(double s) {
    final c = colorFor(s);
    return c == AppColors.warning ? AppColors.textPrimary : c;
  }

  /// Lao rating label matching [colorFor].
  static String labelFor(double s) {
    if (s >= 4.0) return 'ດີຫຼາຍ';
    if (s >= 3.0) return 'ດີ';
    if (s >= 2.0) return 'ປານກາງ';
    return 'ຕ້ອງປັບປຸງ';
  }
}

/// 0..5 star row shared by the list and detail pages.
class EvalStarRow extends StatelessWidget {
  /// Average score (0..5).
  final double score;

  const EvalStarRow({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          if (i < score.floor())
            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning)
          else if (i < score)
            const Icon(
              Icons.star_half_rounded,
              size: 16,
              color: AppColors.warning,
            )
          else
            Icon(
              Icons.star_outline_rounded,
              size: 16,
              color: Colors.grey.shade300,
            ),
      ],
    );
  }
}

/// Small colored tag carrying the human rating label (e.g. "ດີຫຼາຍ").
class EvalRatingTag extends StatelessWidget {
  /// Rating label.
  final String label;

  /// Tint applied to background + foreground.
  final Color color;

  const EvalRatingTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          // Amber text on its own 10% tint fails AA; ink for that band.
          color: color == AppColors.warning ? AppColors.textPrimary : color,
        ),
      ),
    );
  }
}
