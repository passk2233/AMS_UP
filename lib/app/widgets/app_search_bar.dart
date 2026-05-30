import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Standardized in-page search bar (used by admin approve, evaluation
/// results, and announcement history). Matches the surface card style of
/// [AppSurfaceCard] so it sits naturally between filter chips and lists.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String currentQuery;

  const AppSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.currentQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppColors.minTouchTarget),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.buttonRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodySmall,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodySmallMuted.copyWith(
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: currentQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'ລ້າງການຄົ້ນຫາ',
                  icon: Icon(Icons.close,
                      size: 18, color: Colors.grey.shade500),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
