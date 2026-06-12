import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';

/// Heat-scale color for an evaluation score — fill / tint / icon use only.
Color evalScoreColor(double score) {
  if (score >= 4.5) return AppColors.success; // emerald — strong
  if (score >= 3.5) return AppColors.warning; // amber — medium
  if (score >= 2.5) return AppColors.info; // blue — fair
  return AppColors.danger; // red — weak
}

/// AA-safe foreground for a score used as TEXT or an icon on a WHITE surface.
/// Amber (#f59e0b) is ~2:1 on white and must never be a text color, so the
/// amber band falls back to ink; the tinted bubble / bar still carries the hue.
Color evalScoreTextColor(double score) {
  final c = evalScoreColor(score);
  return c == AppColors.warning ? AppColors.textPrimary : c;
}

/// AA-safe foreground for text / icons placed on a SOLID score-color fill.
/// White on amber is 2.15:1 and fails; ink clears AA there (7.94:1).
Color evalOnScoreFill(double score) {
  return evalScoreColor(score) == AppColors.warning
      ? AppColors.textPrimary
      : Colors.white;
}
