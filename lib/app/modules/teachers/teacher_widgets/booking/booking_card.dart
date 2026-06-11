import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/data_exporter.dart';
import '../../booking/controllers/booking_controller.dart';

/// One ad-hoc booking row card with status pill and optional cancel action.
class TeacherBookingCard extends StatelessWidget {
  /// Booking to render.
  final RoomBookingModel booking;

  /// Source of past-check + cancel callbacks.
  final BookingController controller;

  const TeacherBookingCard({
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
        child: ListTile(
          title: Row(
            children: [
              Flexible(
                child: Text(
                  '$room • ${b.startTime} - ${b.endTime}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dayBadge != null) ...[const SizedBox(width: 6), dayBadge],
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
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
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
              if (canCancel) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => controller.cancelAdHocBooking(b),
                  child: const Text(
                    'ຍົກເລີກ',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
