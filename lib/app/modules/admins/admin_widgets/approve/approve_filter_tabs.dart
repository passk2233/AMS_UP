import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../approve/controllers/approve_controller.dart';

/// Horizontal scrolling row of four filter pills, each with a live count.
class ApproveFilterTabsRow extends StatelessWidget {
  /// Source of reactive tab selection + counters.
  final ApproveController controller;

  const ApproveFilterTabsRow({super.key, required this.controller});

  /// Static tab definitions — order matches [ApproveTab] integers.
  static const List<_TabInfo> _tabs = [
    _TabInfo('ທັງໝົດ', null),
    _TabInfo('ລໍຖ້າ', AppColors.borderPending),
    _TabInfo('ອະນຸມັດ', AppColors.borderApproved),
    _TabInfo('ປະຕິເສດ', AppColors.rejectRed),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                child: _FilterTab(
                  info: _tabs[i],
                  count: _countForTab(i),
                  isSelected: controller.selectedTab.value == i,
                  onTap: () => controller.setTab(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _countForTab(int tabIndex) {
    switch (tabIndex) {
      case ApproveTab.pending:
        return controller.pendingCount.value;
      case ApproveTab.approved:
        return controller.approvedCount.value;
      case ApproveTab.rejected:
        return controller.rejectedCount.value;
      default:
        return controller.totalCount.value;
    }
  }
}

/// One pill in [ApproveFilterTabsRow]. Tints to its color (or brand) when
/// selected and shows a count badge on the right.
class _FilterTab extends StatelessWidget {
  /// Label + accent.
  final _TabInfo info;

  /// Live booking count for this tab.
  final int count;

  /// Whether the user is currently filtering by this tab.
  final bool isSelected;

  /// Tap handler.
  final VoidCallback onTap;

  const _FilterTab({
    required this.info,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = info.color ?? AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.chipRadius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.white,
            borderRadius: BorderRadius.circular(AppColors.chipRadius),
            border: Border.all(
              color: isSelected ? accent : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              _CountBadge(count: count, onAccent: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small numeric pill rendered inside a [_FilterTab].
class _CountBadge extends StatelessWidget {
  /// Numeric label.
  final int count;

  /// When true, switches to the inverted (on-color) style used by the
  /// selected tab.
  final bool onAccent;

  const _CountBadge({required this.count, required this.onAccent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: onAccent
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: onAccent ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Tab metadata: label and optional accent.
class _TabInfo {
  /// Caption rendered inside the pill.
  final String label;

  /// Tint applied when the tab is selected. `null` falls back to the brand.
  final Color? color;

  const _TabInfo(this.label, this.color);
}
