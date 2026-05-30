import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Mobile-first form field per design.txt §3.1.
///
/// - Label is rendered **above** the field (saves horizontal space, easier
///   to scan on small screens).
/// - Min touch height is [AppColors.minTouchTarget].
/// - [keyboardType] / [textInputAction] / [inputFormatters] surface the
///   right keyboard for each input — numeric, email, phone.
/// - Inline `errorText` is rendered directly under the field.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool required;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.autofocus = false,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label sits above the field
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.s),
          child: RichText(
            text: TextSpan(
              text: label,
              style: AppTypography.label,
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.rejectRed),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          // Flutter asserts: TextInputAction.newline on a multiline field
          // requires TextInputType.multiline, not TextInputType.text.
          keyboardType: (!obscureText && (maxLines == null || (maxLines ?? 1) > 1) &&
                  identical(keyboardType, TextInputType.text))
              ? TextInputType.multiline
              : keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          autofocus: autofocus,
          validator: validator,
          inputFormatters: inputFormatters,
          style: AppTypography.body,
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMuted.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon,
                    size: 20, color: AppColors.textSecondary),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.inputFill,
            isDense: false,
            // Min touch height ≥ 48dp.
            constraints: BoxConstraints(
              minHeight: AppColors.minTouchTarget,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: 14,
            ),
            counterText: '',
            border: _border(),
            enabledBorder: _border(color: Colors.grey.shade200),
            focusedBorder: _border(color: AppColors.primary, width: 1.5),
            errorBorder: _border(color: AppColors.rejectRed),
            focusedErrorBorder: _border(color: AppColors.rejectRed, width: 1.5),
            disabledBorder: _border(color: Colors.grey.shade100),
            errorText: hasError ? errorText : null,
            helperText: !hasError ? helperText : null,
            helperStyle: AppTypography.caption,
            errorStyle: AppTypography.caption.copyWith(
              color: AppColors.rejectRed,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.buttonRadius),
      borderSide: color == null
          ? BorderSide.none
          : BorderSide(color: color, width: width),
    );
  }
}
