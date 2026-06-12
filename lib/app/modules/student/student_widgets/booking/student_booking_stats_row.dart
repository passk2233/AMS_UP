import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../Booking_student/controllers/booking_student_controller.dart';

/// Four stat tiles (upcoming / pending / approved / past) at the top of the
/// student booking page.
class StudentBookingStatsRow extends StatelessWidget {
  /// Source of the counters.
  final BookingStudentController controller;

  const StudentBookingStatsRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'ກຳລັງມາ',
          value: controller.countUpcoming,
          color: AppColors.primary,
          icon: Icons.event_available,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: 'ລໍຖ້າ',
          value: controller.countPending,
          color: AppColors.borderPending,
          icon: Icons.hourglass_top,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: 'ອະນຸມັດ',
          value: controller.countApproved,
          color: AppColors.borderApproved,
          icon: Icons.check_circle,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: 'ຜ່ານໄປແລ້ວ',
          value: controller.countPast,
          color: Colors.grey,
          icon: Icons.history,
        ),
      ],
    );
  }
}

/// One colored stat tile inside [StudentBookingStatsRow].
class _StatTile extends StatelessWidget {
  /// Caption under the number.
  final String label;

  /// Counter value.
  final int value;

  /// Tint applied to border and icon.
  final Color color;

  /// Glyph above the number.
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(
                // High-contrast ink number; the tile's color lives in the
                // icon + tint, not the figure (amber/teal text fails AA).
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
