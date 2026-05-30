import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../controllers/home_controller.dart';

/// Admin dashboard — first tab in the admin shell.
///
/// Renders, in order:
/// 1. The shared [AdminAppBar] (semester chip + notifications bell).
/// 2. A [ProfileCard] gradient banner with name + 3 stats.
/// 3. A list of `pending` [BookingCard]s the admin can approve / reject.
///
/// All business logic lives in [AdminHomeController]; this view only owns
/// composition and reactive rebuild boundaries.
class AdminHomeView extends GetView<AdminHomeController> {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Expanded(child: _AdminHomeBody(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Loading / error / data switch for the dashboard body.
class _AdminHomeBody extends StatelessWidget {
  /// Source of reactive state.
  final AdminHomeController controller;

  const _AdminHomeBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const AppLoading.adminHome();
      }
      if (controller.errorMessage.isNotEmpty && controller.bookings.isEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshData,
        );
      }
      return _AdminHomeContent(controller: controller);
    });
  }
}

/// Scrollable success state — profile card + pending booking list.
class _AdminHomeContent extends StatelessWidget {
  /// Source of reactive state.
  final AdminHomeController controller;

  const _AdminHomeContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => ProfileCard(
                user: controller.currentUser.value,
                pendingCount: controller.pendingCount.value,
                approvedCount: controller.approvedCount.value,
                roomInUsePercent: controller.roomInUsePercent.value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: _PendingSectionHeader(controller: controller),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: _PendingBookingsList(controller: controller),
            ),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }
}

/// "Pending approvals" section heading with today's date on the right.
class _PendingSectionHeader extends StatelessWidget {
  /// Source of the reactive today-date string.
  final AdminHomeController controller;

  const _PendingSectionHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'ລາຍການອະນຸມັດການໃຊ້ຫ້ອງ',
            style: AppTypography.subheading,
          ),
        ),
        Obx(
          () => Text(controller.todayDate.value, style: AppTypography.caption),
        ),
      ],
    );
  }
}

/// Vertical list of pending [BookingCard]s, with an empty-state fallback
/// when nothing is awaiting approval.
class _PendingBookingsList extends StatelessWidget {
  /// Source of the reactive bookings list.
  final AdminHomeController controller;

  const _PendingBookingsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pending = controller.bookings
          .where((b) => b.status.toLowerCase() == 'pending')
          .toList();

      if (pending.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'ບໍ່ພົບການຈອງທີ່ລໍຖ້າ',
            subtitle: 'ລາຍການຈອງໃໝ່ຈະປະກົດຢູ່ບ່ອນນີ້',
          ),
        );
      }

      return Column(
        children: [
          for (final booking in pending)
            BookingCard(
              booking: booking,
              onApprove: () => controller.approveBooking(booking.bookingId),
              onReject: () => controller.rejectBooking(booking.bookingId),
            ),
        ],
      );
    });
  }
}
