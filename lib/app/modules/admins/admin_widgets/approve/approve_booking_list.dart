import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/room_booking_model.dart';
import '../../approve/controllers/approve_controller.dart';

/// Sliver wrapper around the filtered booking list. Falls back to an
/// empty-state when the filter returns nothing.
class ApproveBookingListSliver extends StatelessWidget {
  /// Source of reactive booking + selection state.
  final ApproveController controller;

  const ApproveBookingListSliver({super.key, required this.controller});

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
            final selected = controller.selectedBookingIds.contains(
              booking.bookingId,
            );
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
