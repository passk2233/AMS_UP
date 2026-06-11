import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';

/// White rounded card with an indigo icon-headed title row above the [child].
class AnnSectionCard extends StatelessWidget {
  /// Leading icon next to the title.
  final IconData icon;

  /// Card heading.
  final String title;

  /// Body slot.
  final Widget child;

  const AnnSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.m + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.laoBlue, size: 22),
              const SizedBox(width: AppSpacing.s),
              Text(title, style: AppTypography.subheading),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

/// Small all-caps caption used as a label above a field or dropdown.
class AnnFieldLabel extends StatelessWidget {
  /// Caption text.
  final String text;

  const AnnFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.captionStrong);
  }
}

/// Filled, rounded text field shared by the title / message / search inputs.
class AnnFilledTextField extends StatelessWidget {
  /// Backing controller.
  final TextEditingController controller;

  /// Placeholder text.
  final String hint;

  /// Vertical line count.
  final int maxLines;

  /// Optional keyboard hint (numeric for ID lookup, etc.).
  final TextInputType? keyboardType;

  const AnnFilledTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        // Slate (4.5:1), not grey.shade400 (~1.8:1) — placeholders are held to
        // the same contrast floor as body text. See DESIGN.md.
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.laoBlue, width: 1.5),
        ),
      ),
    );
  }
}

/// Label + boxed dropdown column, used by every selector on this page.
class AnnLabeledDropdown<T> extends StatelessWidget {
  /// Caption rendered above the dropdown.
  final String label;

  /// Current value.
  final T value;

  /// Available options.
  final List<DropdownMenuItem<T>> items;

  /// Invoked when the user picks a different option.
  final ValueChanged<T?> onChanged;

  const AnnLabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnnFieldLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
