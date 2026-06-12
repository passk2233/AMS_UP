import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../approve/controllers/approve_controller.dart';

/// Row with the search bar and the selection-mode toggle button.
class ApproveSearchHeader extends StatelessWidget {
  /// Source of reactive search + selection state.
  final ApproveController controller;

  const ApproveSearchHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => AppSearchBar(
              hint: 'ຄົ້ນຫາ ຫ້ອງ, ຜູ້ຈອງ, ຈຸດປະສົງ...',
              controller: controller.searchCtrl,
              onChanged: controller.onSearchChanged,
              onClear: controller.clearSearch,
              currentQuery: controller.searchQuery.value,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        _SelectionToggle(controller: controller),
      ],
    );
  }
}

/// 48×48 toggle button that flips [ApproveController.selectionMode].
class _SelectionToggle extends StatelessWidget {
  /// Source of reactive selection state.
  final ApproveController controller;

  const _SelectionToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.selectionMode.value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: controller.toggleSelectionMode,
          child: Container(
            width: AppColors.minTouchTarget,
            height: AppColors.minTouchTarget,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: Icon(
              active ? Icons.close_rounded : Icons.checklist_rounded,
              color: active ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      );
    });
  }
}
