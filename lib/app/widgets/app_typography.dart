import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale per design.txt §4.2.
///
/// Title 24/Bold · Heading 18/Semibold · Body 16/Regular · Caption 12/Regular.
/// Minimum legible body size is 16 px.
class AppTypography {
  AppTypography._();

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmallMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle captionStrong = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  /// Returns a Material 3 [TextTheme] derived from the scale above so that
  /// raw Material widgets (Text, AppBar title, ListTile.title …) inherit
  /// the same scale without each screen passing styles explicitly.
  static TextTheme toMaterialTextTheme() {
    return const TextTheme(
      // Display – not used in mobile-first scale, alias to title.
      displayLarge: title,
      displayMedium: title,
      displaySmall: title,
      headlineLarge: title,
      headlineMedium: heading,
      headlineSmall: heading,
      titleLarge: heading,
      titleMedium: subheading,
      titleSmall: subheading,
      bodyLarge: body,
      bodyMedium: bodySmall,
      bodySmall: caption,
      labelLarge: button,
      labelMedium: label,
      labelSmall: caption,
    );
  }
}
