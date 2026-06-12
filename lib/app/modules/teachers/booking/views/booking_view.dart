import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../teacher_widgets/booking/booking_card.dart';
import '../../teacher_widgets/booking/booking_filter_chips.dart';
import '../../teacher_widgets/booking/booking_stats_row.dart';
import '../../teacher_widgets/booking/create_booking_sheet.dart';
import '../../teacher_widgets/booking/fixed_booking_list.dart';
import '../../teacher_widgets/booking/fixed_diagnostic_banner.dart';
import '../controllers/booking_controller.dart';

class BookingView extends GetView<BookingController> {
  const BookingView({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ຈອງຫ້ອງ'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Get.toNamed('/teacher-noti'),
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'ການແຈ້ງເຕືອນ',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => showCreateBookingSheet(context, controller),
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

              final fixedList = controller.filteredFixedBookings;
              final filtered = controller.filteredMyBookings;
              final hasAnyFixed = controller.fixedBookings.isNotEmpty;
              final isTeacher = controller.currentUser.value?.teacherId != null;

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    BookingStatsRow(controller: controller),
                    const SizedBox(height: AppSpacing.m),
                    if (hasAnyFixed) ...[
                      FixedSectionHeader(controller: controller),
                      const SizedBox(height: AppSpacing.s),
                      FixedBookingFilterChips(controller: controller),
                      const SizedBox(height: AppSpacing.s + 2),
                      if (fixedList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AppEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'ບໍ່ມີຄາບໃນຕົວກອງນີ້',
                            subtitle: 'ລອງເລືອກຕົວກອງອື່ນ',
                          ),
                        )
                      else
                        ...buildFixedBookingList(context, controller, fixedList),
                      const SizedBox(height: AppSpacing.l),
                    ] else if (isTeacher) ...[
                      FixedDiagnosticBanner(controller: controller),
                      const SizedBox(height: AppSpacing.l),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ປະຫວັດການຈອງຂອງຂ້ອຍ',
                            style: AppTypography.subheading,
                          ),
                        ),
                        Text(
                          '${filtered.length} ລາຍການ',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BookingFilterChips(controller: controller),
                    const SizedBox(height: 10),
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
                              ? () => showCreateBookingSheet(context, controller)
                              : () => controller.bookingFilter.value = 'all',
                        ),
                      )
                    else
                      ...filtered.map(
                        (b) => TeacherBookingCard(booking: b, controller: controller),
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
