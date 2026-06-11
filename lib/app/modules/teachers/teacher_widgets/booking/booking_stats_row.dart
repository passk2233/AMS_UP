import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../booking/controllers/booking_controller.dart';

/// Four stat tiles (upcoming / pending / approved / past) at the top of the
/// booking page.
class BookingStatsRow extends StatelessWidget {
  /// Source of the counters.
  final BookingController controller;

  const BookingStatsRow({super.key, required this.controller});

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

/// One colored stat tile inside [BookingStatsRow].
class _StatTile extends StatelessWidget {
  /// Caption under the number.
  final String label;

  /// Counter value.
  final int value;

  /// Tint applied to border, icon and number.
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
              style: TextStyle(
                color: color,
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
