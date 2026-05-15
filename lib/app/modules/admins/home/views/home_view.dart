import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../../../widgets/widget.dart';

class AdminHomeView extends GetView<AdminHomeController> {
  const AdminHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminHomeController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AssetImages.dashboardBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  AdminAppBar(),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const AppLoading.adminHome();
                      }

                      // Show error state
                      if (controller.errorMessage.isNotEmpty &&
                          controller.bookings.isEmpty) {
                        return AppErrorState(
                          message: controller.errorMessage.value,
                          onRetry: controller.refreshData,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: controller.refreshData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile + Stats card
                              Obx(
                                () => ProfileCard(
                                  user: controller.currentUser.value,
                                  pendingCount: controller.pendingCount.value,
                                  approvedCount: controller.approvedCount.value,
                                  roomInUsePercent:
                                      controller.roomInUsePercent.value,
                                ),
                              ),
                              // Booking approvals section
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                child: _buildSectionHeader(),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Obx(() {
                                  final pendingBookings = controller.bookings
                                      .where((b) =>
                                          b.status.toLowerCase() == 'pending')
                                      .toList();

                                  if (pendingBookings.isEmpty) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 40),
                                      child: AppEmptyState(
                                        icon: Icons.inbox_outlined,
                                        title: 'ບໍ່ພົບການຈອງທີ່ລໍຖ້າ',
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: pendingBookings
                                        .map(
                                          (booking) => BookingCard(
                                            booking: booking,
                                            onApprove: () => controller
                                                .approveBooking(
                                                    booking.bookingId),
                                            onReject: () => controller
                                                .rejectBooking(
                                                    booking.bookingId),
                                          ),
                                        )
                                        .toList(),
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ລາຍການອະນຸມັດການໃຊ້ຫ້ອງ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Obx(
          () => Text(
            controller.todayDate.value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}
