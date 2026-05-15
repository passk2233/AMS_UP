import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Outlined red sign-out / destructive action button.
class AppSignOutButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final String loadingLabel;

  const AppSignOutButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'ອອກຈາກລະບົບ',
    this.loadingLabel = 'ກຳລັງອອກ...',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppColors.minTouchTarget,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.rejectRed,
                ),
              )
            : const Icon(Icons.logout, color: AppColors.rejectRed),
        label: Text(
          isLoading ? loadingLabel : label,
          style: const TextStyle(
            color: AppColors.rejectRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.rejectRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable row of filter chips with a selection state.
class AppFilterChip {
  final String label;
  final Object? value;
  const AppFilterChip({required this.label, this.value});
}

class AppFilterChipRow extends StatelessWidget {
  final List<AppFilterChip> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color activeColor;
  final EdgeInsetsGeometry padding;

  const AppFilterChipRow({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.activeColor = AppColors.statsBlue,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppColors.minTouchTarget + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              constraints:
                  const BoxConstraints(minHeight: AppColors.minTouchTarget),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppColors.chipRadius),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  items[index].label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
