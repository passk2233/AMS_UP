import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Solid, high-contrast primary action button.
///
/// One primary should typically appear per screen. Renders a spinner inline
/// when [isLoading] is true; the press handler is disabled while loading to
/// prevent accidental double-submits. Honors the 48dp minimum touch target.
class AppPrimaryButton extends StatelessWidget {
  /// Button caption.
  final String label;

  /// Tap handler — pass `null` to disable.
  final VoidCallback? onPressed;

  /// Optional leading icon rendered to the left of [label].
  final IconData? icon;

  /// When true, replaces the icon with a spinner and disables [onPressed].
  final bool isLoading;

  /// When true (default), the button stretches to fill its parent's width.
  final bool fullWidth;

  /// Override the default on-fill teal background.
  final Color? backgroundColor;

  /// Color applied to the label and icon (default white).
  final Color foregroundColor;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primaryFill;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppColors.minTouchTarget,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.85),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          color: foregroundColor,
        ),
      ),
    );
  }
}

/// Outlined / subtle secondary action button.
///
/// Use alongside [AppPrimaryButton] for "Cancel", "Back", or alternative
/// actions. Shares loading and sizing rules with the primary variant.
class AppSecondaryButton extends StatelessWidget {
  /// Button caption.
  final String label;

  /// Tap handler — pass `null` to disable.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// When true, replaces the icon with a spinner and disables [onPressed].
  final bool isLoading;

  /// When true (default), the button stretches to fill its parent's width.
  final bool fullWidth;

  /// Border + foreground color (default brand).
  final Color color;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: AppColors.minTouchTarget,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          color: color,
        ),
      ),
    );
  }
}

/// Text-only tertiary action.
///
/// Used for inline "more" / "skip" affordances. Has no loading state.
class AppTertiaryButton extends StatelessWidget {
  /// Button caption.
  final String label;

  /// Tap handler — pass `null` to disable.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Foreground tint (default brand).
  final Color color;

  const AppTertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppColors.minTouchTarget,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          ),
          textStyle: AppTypography.button.copyWith(fontSize: 14),
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: false,
          color: color,
        ),
      ),
    );
  }
}

/// Internal helper that picks between three children for a button label:
/// loading spinner + text, icon + text, or text-only.
class _ButtonContent extends StatelessWidget {
  /// Caption text.
  final String label;

  /// Optional leading icon. Ignored while [isLoading].
  final IconData? icon;

  /// Whether to render the spinner instead of an icon.
  final bool isLoading;

  /// Tint applied to the spinner and the (default) icon.
  final Color color;

  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: AppSpacing.s),
          Text(label),
        ],
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.s),
        Text(label),
      ],
    );
  }
}

/// Outlined red sign-out / destructive action button.
///
/// Localized to Lao by default ([label] / [loadingLabel]). The icon is swapped
/// for a spinner while [isLoading].
class AppSignOutButton extends StatelessWidget {
  /// Tap handler — pass `null` to disable.
  final VoidCallback? onPressed;

  /// Whether to show the spinner state.
  final bool isLoading;

  /// Caption shown when idle.
  final String label;

  /// Caption shown while [isLoading].
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

/// One entry inside an [AppFilterChipRow].
///
/// - [label]: caption displayed inside the chip.
/// - [value]: optional payload returned to the parent on selection.
class AppFilterChip {
  /// Caption rendered inside the chip.
  final String label;

  /// Optional payload — the chip row reports back the index, not the value;
  /// callers may look this up themselves.
  final Object? value;

  const AppFilterChip({required this.label, this.value});
}

/// Horizontal, scrollable row of filter chips with single-selection.
///
/// Parent owns the [selectedIndex] and is notified via [onSelected]. The
/// row reserves enough vertical space to honor the 48dp touch target.
class AppFilterChipRow extends StatelessWidget {
  /// Chip definitions, rendered left-to-right.
  final List<AppFilterChip> items;

  /// Index in [items] that should appear selected.
  final int selectedIndex;

  /// Invoked with the tapped index.
  final ValueChanged<int> onSelected;

  /// Tint applied to the selected chip.
  final Color activeColor;

  /// Outer padding around the scrolling row.
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
        itemBuilder: (context, index) => _AppFilterChipTile(
          label: items[index].label,
          isSelected: index == selectedIndex,
          activeColor: activeColor,
          onTap: () => onSelected(index),
        ),
      ),
    );
  }
}

/// Internal pill button rendered by [AppFilterChipRow]. Kept private so the
/// row remains the single API surface — consumers do not instantiate tiles.
class _AppFilterChipTile extends StatelessWidget {
  /// Caption rendered inside the pill.
  final String label;

  /// Whether the chip is the selected one.
  final bool isSelected;

  /// Tint applied when [isSelected] is true.
  final Color activeColor;

  /// Tap handler.
  final VoidCallback onTap;

  const _AppFilterChipTile({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          constraints: const BoxConstraints(
            minHeight: AppColors.minTouchTarget,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppColors.chipRadius),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
