import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';

/// Pill toggle that swaps between the questions / window / results modes.
class EvalModeToggle extends StatelessWidget {
  /// Source of reactive mode state.
  final EvalutionController controller;

  const EvalModeToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _ToggleButton(
              icon: Icons.quiz_outlined,
              label: 'ຄຳຖາມ',
              selected:
                  controller.pageMode.value == EvalutionPageMode.questions,
              onTap: () =>
                  controller.pageMode.value = EvalutionPageMode.questions,
            ),
            _ToggleButton(
              icon: Icons.event_available_outlined,
              label: 'ໄລຍະເວລາ',
              selected: controller.pageMode.value == EvalutionPageMode.window,
              onTap: () => controller.pageMode.value = EvalutionPageMode.window,
            ),
            _ToggleButton(
              icon: Icons.bar_chart_rounded,
              label: 'ຜົນການປະເມີນ',
              selected: controller.pageMode.value == EvalutionPageMode.results,
              onTap: () =>
                  controller.pageMode.value = EvalutionPageMode.results,
            ),
          ],
        ),
      ),
    );
  }
}

/// One pill inside [EvalModeToggle].
class _ToggleButton extends StatelessWidget {
  /// Glyph rendered next to the label.
  final IconData icon;

  /// Caption.
  final String label;

  /// Whether this pill is the active one.
  final bool selected;

  /// Tap handler.
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.laoBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
