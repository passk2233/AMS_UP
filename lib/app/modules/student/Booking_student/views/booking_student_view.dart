import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../student_widgets/booking/create_student_booking_sheet.dart';
import '../../student_widgets/booking/student_booking_card.dart';
import '../../student_widgets/booking/student_booking_filter_chips.dart';
import '../../student_widgets/booking/student_booking_stats_row.dart';
import '../controllers/booking_student_controller.dart';

class BookingStudentView extends GetView<BookingStudentController> {
  const BookingStudentView({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BookingStudentController>()) {
      Get.put(BookingStudentController());
    }
    return GetBuilder<BookingStudentController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ຈອງຫ້ອງ'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Get.toNamed('/student-noti'),
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'ການແຈ້ງເຕືອນ',
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => showCreateStudentBookingSheet(
                context,
                controller,
              ),
              backgroundColor: AppColors.primaryFill,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('ຈອງໃໝ່'),
            ),
            body: Obx(() {
              if (controller.isLoading.value) {
                return AppRefreshableLoader(
                  onRefresh: controller.refreshData,
                  child: const AppLoading.booking(),
                );
              }
              final err = controller.errorMessage.value;
              if (err.isNotEmpty) {
                return AppErrorState(
                  message: err,
                  onRetry: controller.refreshData,
                );
              }

              final filtered = controller.filteredMyBookings;

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    StudentBookingStatsRow(controller: controller),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('ປະຫວັດການຈອງຂອງຂ້ອຍ',
                              style: AppTypography.subheading),
                        ),
                        Text('${filtered.length} ລາຍການ',
                            style: AppTypography.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    StudentBookingFilterChips(controller: controller),
                    const SizedBox(height: AppSpacing.s + 2),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: AppEmptyState(
                          icon: Icons.inbox_outlined,
                          title: controller.myBookings.isEmpty
                              ? 'ຍັງບໍ່ມີການຈອງ'
                              : 'ບໍ່ມີຂໍ້ມູນທີ່ກົງກັບຕົວກອງ',
                          subtitle: controller.myBookings.isEmpty
                              ? 'ກົດປຸ່ມ "ຈອງໃໝ່" ເພື່ອເລີ່ມຕົ້ນ'
                              : 'ລອງເລືອກຕົວກອງອື່ນ',
                          actionLabel: controller.myBookings.isEmpty
                              ? 'ຈອງໃໝ່'
                              : 'ລ້າງຕົວກອງ',
                          actionIcon: controller.myBookings.isEmpty
                              ? Icons.add_rounded
                              : Icons.filter_alt_off_rounded,
                          onAction: controller.myBookings.isEmpty
                              ? () => showCreateStudentBookingSheet(
                                    context,
                                    controller,
                                  )
                              : () => controller.bookingFilter.value = 'all',
                        ),
                      )
                    else
                      ...filtered.map(
                        (b) => StudentBookingCard(
                          booking: b,
                          controller: controller,
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
