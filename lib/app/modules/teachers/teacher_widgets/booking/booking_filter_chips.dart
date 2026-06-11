import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../booking/controllers/booking_controller.dart';

/// Filter chip row for the teacher's own ad-hoc bookings.
class BookingFilterChips extends StatelessWidget {
  /// Source of the reactive filter value.
  final BookingController controller;

  const BookingFilterChips({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const filters = <(String, String)>[
      ('all', 'ທັງໝົດ'),
      ('upcoming', 'ກຳລັງມາ'),
      ('pending', 'ລໍຖ້າ'),
      ('approved', 'ອະນຸມັດ'),
      ('cancelled', 'ຍົກເລີກ'),
      ('past', 'ຜ່ານໄປແລ້ວ'),
    ];
    final selectedIndex = filters.indexWhere(
      (f) => f.$1 == controller.bookingFilter.value,
    );
    return AppFilterChipRow(
      items: [for (final f in filters) AppFilterChip(label: f.$2)],
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onSelected: (i) => controller.bookingFilter.value = filters[i].$1,
      activeColor: AppColors.info,
      padding: EdgeInsets.zero,
    );
  }
}

/// Filter chip row for the fixed (schedule-derived) bookings section.
class FixedBookingFilterChips extends StatelessWidget {
  /// Source of the reactive filter value + counters.
  final BookingController controller;

  const FixedBookingFilterChips({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    const filters = <(String, String)>[
      ('upcoming', 'ກຳລັງມາ'),
      ('today', 'ມື້ນີ້'),
      ('week', '7 ວັນ'),
      ('cancelled', 'ຍົກເລີກ'),
      ('all', 'ທັງໝົດ'),
    ];
    final selectedIndex = filters.indexWhere(
      (f) => f.$1 == controller.fixedFilter.value,
    );
    return AppFilterChipRow(
      items: [
        for (final f in filters)
          AppFilterChip(
            label: (f.$1 == 'today' && controller.countFixedToday > 0)
                ? '${f.$2} (${controller.countFixedToday})'
                : (f.$1 == 'cancelled' && controller.countFixedCancelled > 0)
                ? '${f.$2} (${controller.countFixedCancelled})'
                : f.$2,
          ),
      ],
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onSelected: (i) => controller.fixedFilter.value = filters[i].$1,
      activeColor: AppColors.info,
      padding: EdgeInsets.zero,
    );
  }
}
