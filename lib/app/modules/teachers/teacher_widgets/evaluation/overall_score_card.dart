import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

import 'eval_score_colors.dart';

/// Headline card showing the teacher's overall average score on a heat-scale
/// colored fill with a white score pill.
class OverallScoreCard extends StatelessWidget {
  /// Overall average score (0..5).
  final double average;

  const OverallScoreCard({super.key, required this.average});

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = evalScoreColor(average);
    final Color onFill = evalOnScoreFill(average);
    final Color pillText = evalScoreTextColor(average);
    String label = 'ດີ';
    IconData emoji = Icons.thumb_up_alt_rounded;

    if (average < 3.0) {
      label = 'ຕ້ອງປັບປຸງ';
      emoji = Icons.trending_down_rounded;
    } else if (average < 4.0) {
      label = 'ປານກາງ';
      emoji = Icons.trending_flat_rounded;
    } else if (average >= 4.5) {
      label = 'ດີເລີດ';
      emoji = Icons.emoji_events_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scoreColor,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ຄະແນນລວມ',
                  style: TextStyle(
                    color: onFill,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(emoji, color: onFill.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: onFill.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: pillText, size: 24),
                const SizedBox(width: 6),
                Text(
                  average.toStringAsFixed(2),
                  style: TextStyle(
                    color: pillText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
