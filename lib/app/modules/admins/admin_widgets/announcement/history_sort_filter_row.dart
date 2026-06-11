import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../announcement/controllers/announcement_controller.dart';

/// Scrolling row of sort chips followed by a vertical divider and type
/// filter chips.
class HistorySortFilterRow extends StatelessWidget {
  /// Source of reactive sort / filter state.
  final AnnouncementController controller;

  const HistorySortFilterRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(
          () => Row(
            children: [
              _SortChip(
                label: 'ໃໝ່ສຸດ',
                mode: AnnouncementSortMode.newest,
                controller: controller,
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'ເກົ່າສຸດ',
                mode: AnnouncementSortMode.oldest,
                controller: controller,
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'ຫົວຂໍ້ ກ-ຮ',
                mode: AnnouncementSortMode.titleAZ,
                controller: controller,
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 24, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              _TypeFilterChip(
                label: 'ທັງໝົດ',
                typeValue: '',
                controller: controller,
              ),
              const SizedBox(width: 6),
              for (final t in controller.uniqueTypes.take(4))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TypeFilterChip(
                    label: t.length > 15 ? '${t.substring(0, 15)}…' : t,
                    typeValue: t,
                    controller: controller,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sort chip with a leading icon. Tints indigo when its [mode] is active.
class _SortChip extends StatelessWidget {
  /// Caption.
  final String label;

  /// Sort mode this chip selects.
  final int mode;

  /// Source of reactive sort state.
  final AnnouncementController controller;

  const _SortChip({
    required this.label,
    required this.mode,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.historySortMode.value == mode;
      return GestureDetector(
        onTap: () => controller.setHistorySortMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.laoBlue : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.laoBlue : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: 14,
                color: selected ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Type filter chip. Tints green when its [typeValue] is active.
class _TypeFilterChip extends StatelessWidget {
  /// Caption.
  final String label;

  /// Type value this chip selects; empty string means "all".
  final String typeValue;

  /// Source of reactive filter state.
  final AnnouncementController controller;

  const _TypeFilterChip({
    required this.label,
    required this.typeValue,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.historyFilterType.value == typeValue;
      return GestureDetector(
        onTap: () => controller.setHistoryFilterType(typeValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.borderApproved.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.borderApproved : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? AppColors.borderApproved
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
    });
  }
}
