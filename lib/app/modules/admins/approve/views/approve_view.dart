import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../admin_widgets/approve/approve_booking_list.dart';
import '../../admin_widgets/approve/approve_filter_tabs.dart';
import '../../admin_widgets/approve/approve_search_header.dart';
import '../../admin_widgets/approve/approve_stats_row.dart';
import '../../admin_widgets/approve/bulk_action_bar.dart';
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
      bottomNavigationBar: BulkActionBar(controller: controller),
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
              child: ApproveStatsRow(controller: controller),
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
              child: ApproveSearchHeader(controller: controller),
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
              child: ApproveFilterTabsRow(controller: controller),
            ),
          ),
          ApproveBookingListSliver(controller: controller),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),
        ],
      ),
    );
  }
}
