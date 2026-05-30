import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../../data/models/room_booking_model.dart';
import '../controllers/approve_controller.dart';

/// Admin booking approval queue.
///
/// Renders, top-to-bottom:
/// - The shared [AdminAppBar].
/// - A three-chip stats row (pending / approved / rejected).
/// - A search bar + a selection-mode toggle.
/// - Filter tabs (All / Pending / Approved / Rejected).
/// - The filtered, sorted list of [BookingCard]s.
/// - A floating bulk-action toolbar that appears in selection mode.
class ApproveView extends GetView<ApproveController> {
  const ApproveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _BulkActionBar(controller: controller),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetImages.dashboardBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const AdminAppBar(),
            Expanded(child: _ApproveBody(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Loading / error / content switch for the approve page body.
class _ApproveBody extends StatelessWidget {
  /// Source of reactive state.
  final ApproveController controller;

  const _ApproveBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading.adminApprove();
      if (controller.errorMessage.isNotEmpty && controller.bookings.isEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshData,
        );
      }
      return _ApproveScrollContent(controller: controller);
    });
  }
}

/// Pull-to-refresh + scrollable content for the success state.
class _ApproveScrollContent extends StatelessWidget {
  /// Source of reactive state.
  final ApproveController controller;

  const _ApproveScrollContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                0,
              ),
              child: _StatsRow(controller: controller),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s + 4,
                AppSpacing.m,
                0,
              ),
              child: _SearchHeader(controller: controller),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s + 4,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: _FilterTabsRow(controller: controller),
            ),
          ),
          _BookingListSliver(controller: controller),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── stats row ──

/// Horizontal row with three [_StatChip]s (pending / approved / rejected).
class _StatsRow extends StatelessWidget {
  /// Source of reactive stat counters.
  final ApproveController controller;

  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          _StatChip(
            icon: Icons.hourglass_top_rounded,
            label: 'ລໍຖ້າ',
            count: controller.pendingCount.value,
            color: AppColors.borderPending,
          ),
          const SizedBox(width: AppSpacing.s),
          _StatChip(
            icon: Icons.check_circle_outline_rounded,
            label: 'ອະນຸມັດ',
            count: controller.approvedCount.value,
            color: AppColors.borderApproved,
          ),
          const SizedBox(width: AppSpacing.s),
          _StatChip(
            icon: Icons.cancel_outlined,
            label: 'ປະຕິເສດ',
            count: controller.rejectedCount.value,
            color: AppColors.rejectRed,
          ),
        ],
      ),
    );
  }
}

/// One stat tile inside [_StatsRow] — leading icon bubble + count + label.
class _StatChip extends StatelessWidget {
  /// Glyph rendered inside the colored bubble.
  final IconData icon;

  /// Lower caption.
  final String label;

  /// Large value shown above the label.
  final int count;

  /// Accent applied to the icon bubble, the count text, and the shadow.
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: AppColors.minTouchTarget),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s + 4,
          horizontal: AppSpacing.s + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppColors.buttonRadius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: AppTypography.heading.copyWith(color: color),
                  ),
                  Text(
                    label,
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── search header ──

/// Row with the search bar and the selection-mode toggle button.
class _SearchHeader extends StatelessWidget {
  /// Source of reactive search + selection state.
  final ApproveController controller;

  const _SearchHeader({required this.controller});

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

// ──────────────────────────────────────────────────── filter tabs ──

/// Horizontal scrolling row of four filter pills, each with a live count.
class _FilterTabsRow extends StatelessWidget {
  /// Source of reactive tab selection + counters.
  final ApproveController controller;

  const _FilterTabsRow({required this.controller});

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
                padding:
                    EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
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

/// One pill in [_FilterTabsRow]. Tints to its color (or brand) when selected
/// and shows a count badge on the right.
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          fontSize: 11,
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

// ────────────────────────────────────────────────── booking list ──

/// Sliver wrapper around the filtered booking list. Falls back to an
/// empty-state when the filter returns nothing.
class _BookingListSliver extends StatelessWidget {
  /// Source of reactive booking + selection state.
  final ApproveController controller;

  const _BookingListSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.filteredBookings;
      if (list.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: controller.searchQuery.value.isNotEmpty
                ? 'ບໍ່ພົບຜົນການຄົ້ນຫາ'
                : 'ບໍ່ມີລາຍການຈອງ',
            subtitle: controller.searchQuery.value.isNotEmpty
                ? 'ລອງຄົ້ນຫາດ້ວຍຄຳອື່ນ'
                : 'ລາຍການຈອງຈະສະແດງຢູ່ບ່ອນນີ້',
          ),
        );
      }

      final inSelection = controller.selectionMode.value;
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        sliver: SliverList.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final booking = list[index];
            if (!inSelection) {
              return BookingCard(
                booking: booking,
                onApprove: () => controller.approveBooking(booking.bookingId),
                onReject: () => controller.rejectBooking(booking.bookingId),
              );
            }
            final selected =
                controller.selectedBookingIds.contains(booking.bookingId);
            return _SelectableBookingCard(
              booking: booking,
              selected: selected,
              onTap: () => controller.toggleSelected(booking.bookingId),
            );
          },
        ),
      );
    });
  }
}

/// A booking card overlaid with a selection check mark and a tap target
/// that toggles inclusion in the bulk selection.
///
/// Non-pending rows render at 0.55 opacity and are non-interactive — bulk
/// mutations can only act on pending bookings.
class _SelectableBookingCard extends StatelessWidget {
  /// The booking to render.
  final RoomBookingModel booking;

  /// Whether the user has included this booking in the selection.
  final bool selected;

  /// Tap handler — only called for pending rows.
  final VoidCallback onTap;

  const _SelectableBookingCard({
    required this.booking,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status.toLowerCase() == 'pending';
    return Opacity(
      opacity: isPending ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: isPending ? onTap : null,
        child: Stack(
          children: [
            IgnorePointer(
              child: BookingCard(
                booking: booking,
                onApprove: () {},
                onReject: () {},
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _SelectionCheck(selected: selected),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular check-mark overlaid on the top-right of a selectable booking.
class _SelectionCheck extends StatelessWidget {
  /// Whether the booking is currently in the selection.
  final bool selected;

  const _SelectionCheck({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}

// ───────────────────────────────────────────────── bulk action bar ──

/// Sticky bottom toolbar that appears in selection mode. Renders the
/// selection count, a select-all / clear-selection toggle, and the bulk
/// reject + approve buttons.
class _BulkActionBar extends StatelessWidget {
  /// Source of reactive selection state.
  final ApproveController controller;

  const _BulkActionBar({required this.controller});

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
                  onPressed: count == 0
                      ? null
                      : controller.bulkRejectSelected,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('ປະຕິເສດ',
                      style: TextStyle(fontSize: 12)),
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
                  onPressed: count == 0
                      ? null
                      : controller.bulkApproveSelected,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('ອະນຸມັດ',
                      style: TextStyle(fontSize: 12)),
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
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
