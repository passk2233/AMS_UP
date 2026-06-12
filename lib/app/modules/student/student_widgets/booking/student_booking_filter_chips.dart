import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../Booking_student/controllers/booking_student_controller.dart';

/// Filter chip row for the student's own bookings.
class StudentBookingFilterChips extends StatelessWidget {
  /// Source of the reactive filter value.
  final BookingStudentController controller;

  const StudentBookingFilterChips({super.key, required this.controller});

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
    final selectedIndex =
        filters.indexWhere((f) => f.$1 == controller.bookingFilter.value);
    return AppFilterChipRow(
      items: [for (final f in filters) AppFilterChip(label: f.$2)],
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onSelected: (i) => controller.bookingFilter.value = filters[i].$1,
      activeColor: AppColors.info,
      padding: EdgeInsets.zero,
    );
  }
}
