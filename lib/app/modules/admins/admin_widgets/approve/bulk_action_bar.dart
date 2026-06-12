import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../approve/controllers/approve_controller.dart';

/// Sticky bottom toolbar that appears in selection mode. Renders the
/// selection count, a select-all / clear-selection toggle, and the bulk
/// reject + approve buttons.
class BulkActionBar extends StatelessWidget {
  /// Source of reactive selection state.
  final ApproveController controller;

  const BulkActionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.selectionMode.value) return const SizedBox.shrink();
      final count = controller.selectedBookingIds.length;
      return Material(
        elevation: 12,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(child: _SelectionSummary(controller: controller)),
                OutlinedButton.icon(
                  onPressed: count == 0 ? null : controller.bulkRejectSelected,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('ປະຕິເສດ', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rejectRed,
                    side: const BorderSide(color: AppColors.rejectRed),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: count == 0 ? null : controller.bulkApproveSelected,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('ອະນຸມັດ', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.borderApproved,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Left half of the bulk action bar — selection count and a select-all /
/// clear-selection toggle.
class _SelectionSummary extends StatelessWidget {
  /// Source of reactive selection state.
  final ApproveController controller;

  const _SelectionSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final count = controller.selectedBookingIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ເລືອກ $count ລາຍການ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: count == 0
              ? controller.selectAllVisiblePending
              : controller.clearSelection,
          child: Text(
            count == 0 ? 'ເລືອກທັງໝົດທີ່ລໍຖ້າ' : 'ລ້າງການເລືອກ',
            style: const TextStyle(
              // On-fill teal (4.70:1); bright primary is 2.43:1 as text.
              fontSize: 12,
              color: AppColors.primaryFill,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
