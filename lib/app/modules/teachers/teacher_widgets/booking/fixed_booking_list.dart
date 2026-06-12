import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../booking/controllers/fixed_booking.dart';

/// Header row above the fixed (schedule-derived) bookings section.
class FixedSectionHeader extends StatelessWidget {
  /// Source of the counters.
  final BookingController controller;

  const FixedSectionHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'ການຈອງປະຈຳ (ຈາກຕາຕະລາງຮຽນ)',
            style: AppTypography.subheading,
          ),
        ),
        if (c.countFixedCancelled > 0)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.rejectRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ຍົກເລີກ ${c.countFixedCancelled}',
                style: const TextStyle(
                  color: AppColors.rejectRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Text('${c.countFixedUpcoming} ຄາບ', style: AppTypography.caption),
      ],
    );
  }
}

/// Renders [list] grouped under date headers so a week's classes scan top to
/// bottom without the eye having to re-derive the date for each card.
List<Widget> buildFixedBookingList(
  BuildContext context,
  BookingController controller,
  List<FixedBooking> list,
) {
  final widgets = <Widget>[];
  String? currentDateKey;
  for (final fb in list) {
    final key =
        '${fb.date.year}-${fb.date.month.toString().padLeft(2, '0')}-${fb.date.day.toString().padLeft(2, '0')}';
    if (key != currentDateKey) {
      widgets.add(FixedDateHeader(date: fb.date));
      currentDateKey = key;
    }
    widgets.add(FixedBookingCard(booking: fb, controller: controller));
  }
  return widgets;
}

/// Date header row ("ວັນຈັນ 1/1/2026" + today/tomorrow hint) above a group of
/// fixed-booking cards.
class FixedDateHeader extends StatelessWidget {
  /// Date this header introduces.
  final DateTime date;

  const FixedDateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final d = date;
    final weekday = _weekdayLao(d.weekday);
    final dateStr = '${d.day}/${d.month}/${d.year}';
    final today = dateOnly(DateTime.now());
    final target = dateOnly(d);
    String? hint;
    if (sameDate(target, today)) {
      hint = 'ມື້ນີ້';
    } else if (sameDate(target, today.add(const Duration(days: 1)))) {
      hint = 'ມື້ອື່ນ';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$weekday $dateStr',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.3,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hint,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _weekdayLao(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'ວັນຈັນ';
      case DateTime.tuesday:
        return 'ວັນອັງຄານ';
      case DateTime.wednesday:
        return 'ວັນພຸດ';
      case DateTime.thursday:
        return 'ວັນພະຫັດ';
      case DateTime.friday:
        return 'ວັນສຸກ';
      case DateTime.saturday:
        return 'ວັນເສົາ';
      case DateTime.sunday:
        return 'ວັນອາທິດ';
      default:
        return '';
    }
  }
}

/// One fixed (schedule-derived) class slot card with cancel / restore actions.
class FixedBookingCard extends StatelessWidget {
  /// Slot to render.
  final FixedBooking booking;

  /// Source of cancel / restore callbacks.
  final BookingController controller;

  const FixedBookingCard({
    super.key,
    required this.booking,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final fb = booking;
    final room = fb.plan.room?.roomCode ?? 'ຫ້ອງ ${fb.roomId}';
    final subject =
        fb.plan.subject?.nameLao ?? fb.plan.subject?.nameEng ?? 'ວິຊາ';
    final group = fb.plan.studentGroup?.stdGroupName ?? '-';
    final color = fb.cancelled ? Colors.grey : AppColors.bookingBlue;
    final past = isPastSlot(fb.date, fb.startTime);
    final canRestore = fb.cancelled && !past;

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: past ? 0.7 : 1.0,
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              fb.cancelled ? Icons.event_busy : Icons.event_repeat,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            '$subject • $room',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: fb.cancelled
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              'ກຸ່ມ $group • ${fb.startTime}-${fb.endTime}',
              if (fb.cancelled && (fb.cancelReason ?? '').isNotEmpty)
                'ເຫດຜົນ: ${fb.cancelReason}',
            ].join('\n'),
          ),
          isThreeLine: fb.cancelled && (fb.cancelReason ?? '').isNotEmpty,
          trailing: fb.cancelled
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rejectRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ຍົກເລີກ',
                        style: TextStyle(
                          color: AppColors.rejectRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (canRestore) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => controller.restoreFixedBooking(fb),
                        child: const Text(
                          'ກູ້ຄືນ',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : past
              ? Text(
                  'ສຳເລັດ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : TextButton.icon(
                  onPressed: () =>
                      promptFixedCancelReason(context, controller, fb),
                  icon: const Icon(
                    Icons.cancel,
                    color: AppColors.rejectRed,
                    size: 18,
                  ),
                  label: const Text(
                    'ຍົກເລີກ',
                    style: TextStyle(color: AppColors.rejectRed, fontSize: 12),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Asks for an optional cancel reason, then cancels [fb] via [controller].
Future<void> promptFixedCancelReason(
  BuildContext context,
  BookingController controller,
  FixedBooking fb,
) async {
  final reasonCtrl = TextEditingController();
  final dateStr = '${fb.date.day}/${fb.date.month}/${fb.date.year}';
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('ຍົກເລີກການຮຽນ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ວັນທີ $dateStr ${fb.startTime}-${fb.endTime}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'ເຫດຜົນ (ບໍ່ບັງຄັບ)',
              hintText: 'ເຊັ່ນ: ອາຈານປ່ວຍ',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ນັກສຶກສາໃນກຸ່ມຈະຮັບການແຈ້ງເຕືອນ (ມີເຫດຜົນຖ້າລະບຸ)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('ກັບຄືນ'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('ຍົກເລີກການຮຽນ'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await controller.cancelFixedBooking(fb, reason: reasonCtrl.text);
}
