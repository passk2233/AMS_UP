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
    if (s >= 9.0) return AppColors.success;
    if (s >= 7.0) return AppColors.info; // was off-palette #3B82F6
    if (s >= 5.0) return AppColors.warning; // was raw #F59E0B
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
    if (s >= 9.0) return 'ດີຫຼາຍ';
    if (s >= 7.0) return 'ດີ';
    if (s >= 5.0) return 'ປານກາງ';
    return 'ຕ້ອງປັບປຸງ';
  }

  /// Long verdict for an average score, used on the printable report.
  /// Mirrors the webapp's `score_verdict()` (same 9/7/5 bands).
  static String verdictFor(double s) {
    if (s >= 9.0) return 'ການສອນມີຄຸນນະພາບດີຫຼາຍ';
    if (s >= 7.0) return 'ການສອນມີຄຸນນະພາບດີ';
    if (s >= 5.0) return 'ການສອນມີຄຸນນະພາບພໍໃຊ້';
    return 'ການສອນຍັງບໍ່ມີຄຸນນະພາບພຽງພໍ ຕ້ອງໄດ້ປັບປຸງເພີ່ມ';
  }

  /// Scoring legend rows printed under the report. Mirrors `score_legend()`.
  static const List<String> legend = [
    'ຄະແນນ 9 ຫາ 10 ໝາຍເຖິງ ການສອນມີຄຸນນະພາບດີຫຼາຍ',
    'ຄະແນນ 7 ຫາ 8 ໝາຍເຖິງ ການສອນມີຄຸນນະພາບດີ',
    'ຄະແນນ 5 ຫາ 6 ໝາຍເຖິງ ການສອນມີຄຸນນະພາບພໍໃຊ້',
    'ຄະແນນ 0 ຫາ 4 ໝາຍເຖິງ ການສອນຍັງບໍ່ມີຄຸນນະພາບພຽງພໍ ຕ້ອງໄດ້ປັບປຸງເພີ່ມ',
  ];
}

/// 5-star row shared by the list and detail pages. [score] is on the 0..10
/// scale; the 5 stars represent score/2.
class EvalStarRow extends StatelessWidget {
  /// Average score (0..10).
  final double score;

  const EvalStarRow({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final stars = score / 2; // 0..10 → 0..5 stars
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          if (i < stars.floor())
            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning)
          else if (i < stars)
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

/// "ປະເມີນແລ້ວ ▬▬▬ R/E" completion meter shown on the teacher list and the
/// subject cards — the mobile equivalent of the webapp admin's evaluated /
/// expected count + progress bar. [expected] is the group roster size; when it
/// is unknown (0) the bar stays empty and the count reads "R/-".
class EvalCompletionMeter extends StatelessWidget {
  /// Students who submitted.
  final int respondents;

  /// Roster size (the denominator). 0 when unknown.
  final int expected;

  const EvalCompletionMeter({
    super.key,
    required this.respondents,
    required this.expected,
  });

  @override
  Widget build(BuildContext context) {
    final pct = expected > 0 ? (respondents / expected).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        const Icon(
          Icons.groups_outlined,
          size: 13,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        const Text(
          'ປະເມີນແລ້ວ',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          expected > 0 ? '$respondents/$expected' : '$respondents/-',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
