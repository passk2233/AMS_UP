import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/data_exporter.dart';
import '../../Booking_student/controllers/booking_student_controller.dart';

/// One student booking row card with status pill and a discoverable cancel
/// action.
class StudentBookingCard extends StatelessWidget {
  /// Booking to render.
  final RoomBookingModel booking;

  /// Source of past-check + cancel callbacks.
  final BookingStudentController controller;

  const StudentBookingCard({
    super.key,
    required this.booking,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final room = b.room?.roomCode ?? 'ຫ້ອງ ${b.roomId}';
    final date =
        '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}';
    final status = b.status;
    final s = status.toLowerCase();
    final past = controller.isBookingPast(b);
    final style = BookingStatusStyle.of(status);
    final canCancel = (s == 'pending' || s == 'approved') && !past;
    final dayBadge = BookingDayBadge.forDate(b.bookingDate);
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: past ? 0.65 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      '$room • ${b.startTime} - ${b.endTime}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dayBadge != null) ...[
                    const SizedBox(width: 6),
                    dayBadge,
                  ],
                ],
              ),
              subtitle: Text(
                [
                  'ວັນທີ $date',
                  if (b.purpose != null && b.purpose!.isNotEmpty)
                    'ເປົ້າໝາຍ: ${b.purpose}',
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  style.labelLao,
                  style: TextStyle(
                    color: style.onColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Discoverable cancel action. Replaces the old 12px tap-link so the
            // destructive control meets the 48dp touch target (CLAUDE.md §7.1).
            // Only shown for cancellable (pending/approved, not past) bookings.
            if (canCancel)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m, 0, AppSpacing.s, AppSpacing.s),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => controller.cancelBooking(b),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('ຍົກເລີກການຈອງ'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        backgroundColor:
                            AppColors.danger.withValues(alpha: 0.08),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m, vertical: AppSpacing.s),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppColors.buttonRadius),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
