import 'package:flutter/material.dart';

import '../modules/data/models/room_booking_model.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'booking_status.dart';

/// Card that summarizes one [RoomBookingModel] and exposes approve / reject
/// actions when the booking is pending.
///
/// The card is intentionally dumb — it takes a pre-loaded booking plus two
/// callbacks. Filtering, persistence, and FCM are the caller's job. All
/// display-side derivations (formatting names, dates, time ranges) live in
/// the private [_BookingDisplay] adapter so the build method stays flat.
class BookingCard extends StatelessWidget {
  /// The booking to render.
  final RoomBookingModel booking;

  /// Invoked when the user taps "Approve" (only shown while pending).
  final VoidCallback onApprove;

  /// Invoked when the user taps "Reject" (only shown while pending).
  final VoidCallback onReject;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final display = _BookingDisplay(booking);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s + 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.s + 4),
        border: Border(left: BorderSide(color: display.borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s + 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookingHeader(display: display),
            const SizedBox(height: 6),
            if (booking.purpose != null && booking.purpose!.isNotEmpty) ...[
              Text(
                booking.purpose!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
            ],
            _BookingUserRow(display: display),
            const SizedBox(height: 6),
            _BookingMetaRow(display: display),
            const SizedBox(height: AppSpacing.s + 4),
            _BookingActions(
              display: display,
              onApprove: onApprove,
              onReject: onReject,
            ),
          ],
        ),
      ),
    );
  }
}

/// Adapter that turns a [RoomBookingModel] into the display primitives the
/// card's child widgets need. Keeps every formatting decision in one place.
class _BookingDisplay {
  final RoomBookingModel booking;

  const _BookingDisplay(this.booking);

  bool get isPending => booking.status.toLowerCase() == 'pending';
  bool get isApproved => booking.status.toLowerCase() == 'approved';
  bool get isRejected => booking.status.toLowerCase() == 'rejected';

  Color get borderColor => BookingStatusStyle.of(booking.status).color;

  /// Whether the booker is a student — used to switch the role pill color.
  bool get isStudent => booking.user?.stdId != null;

  /// Room code if the relation is populated, otherwise `Room <id>`.
  String get roomName => booking.room?.roomCode ?? 'Room ${booking.roomId}';

  /// Formatted `HH:mm - HH:mm` time range. Empty when both ends are missing.
  String get timeDisplay {
    if (booking.startTime.isEmpty && booking.endTime.isEmpty) return '';
    return '${booking.startTime} - ${booking.endTime}';
  }

  /// Lao-localized weekday + month + day, e.g. "ວັນຈັນ, ມັງກອນ 5".
  String get dateDisplay {
    final d = booking.bookingDate;
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  }

  /// Preferred display name: teacher → student → username fallback.
  String get displayName {
    final user = booking.user;
    if (user == null) return 'Unknown User';

    final teacher = user.teacher;
    if (teacher != null) {
      return '${teacher.nameLao} ${teacher.surnameLao}'.trim();
    }
    final student = user.student;
    if (student != null) {
      return '${student.nameLao} ${student.surnameLao ?? ''}'.trim();
    }
    return user.username;
  }

  static const _weekdays = <String>[
    'ວັນຈັນ', 'ວັນອັງຄານ', 'ວັນພຸດ', 'ວັນພະຫັດ',
    'ວັນສຸກ', 'ວັນເສົາ', 'ວັນອາທິດ',
  ];

  static const _months = <String>[
    'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ',
    'ພຶດສະພາ', 'ມິຖຸນາ', 'ກໍລະກົດ', 'ສິງຫາ',
    'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ',
  ];
}

/// Header row: status circle + room title (left), time range (right).
class _BookingHeader extends StatelessWidget {
  /// Pre-built display adapter.
  final _BookingDisplay display;

  const _BookingHeader({required this.display});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookingStatusIcon(display: display),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            display.roomName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.laoBlue,
            ),
          ),
        ),
        if (display.timeDisplay.isNotEmpty)
          Text(display.timeDisplay, style: AppTypography.caption),
      ],
    );
  }
}

/// Small circular badge that reflects the booking's status: filled blue
/// check when approved, gray X when rejected, empty when pending.
class _BookingStatusIcon extends StatelessWidget {
  /// Pre-built display adapter.
  final _BookingDisplay display;

  const _BookingStatusIcon({required this.display});

  @override
  Widget build(BuildContext context) {
    final approved = display.isApproved;
    final rejected = display.isRejected;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Approved is emerald everywhere — the status color, matching the card
        // border and the resolved pill. (Was Info Blue, which collided.)
        color: approved ? AppColors.success : Colors.transparent,
        border: Border.all(
          color: approved ? AppColors.success : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: approved
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : rejected
              ? Icon(Icons.close, color: Colors.grey.shade400, size: 14)
              : null,
    );
  }
}

/// Booker name + role pill (Student / Teacher).
class _BookingUserRow extends StatelessWidget {
  /// Pre-built display adapter.
  final _BookingDisplay display;

  const _BookingUserRow({required this.display});

  @override
  Widget build(BuildContext context) {
    final isStudent = display.isStudent;
    return Row(
      children: [
        Flexible(
          child: Text(
            display.displayName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.laoBlue,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        _RolePill(isStudent: isStudent),
      ],
    );
  }
}

/// Small role chip rendered next to the booker's name.
class _RolePill extends StatelessWidget {
  /// `true` when the booker is a student, `false` for a teacher.
  final bool isStudent;

  const _RolePill({required this.isStudent});

  @override
  Widget build(BuildContext context) {
    // On-palette tints: Info Blue for students, on-fill teal for teachers.
    // (Was raw blue/orange Material shades, off the palette entirely.)
    final color = isStudent ? AppColors.info : AppColors.primaryFill;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isStudent ? 'ນັກສຶກສາ' : 'ອາຈານ',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Date + room meta row rendered below the user row.
class _BookingMetaRow extends StatelessWidget {
  /// Pre-built display adapter.
  final _BookingDisplay display;

  const _BookingMetaRow({required this.display});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 13,
      color: AppColors.textSecondary,
    );
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(display.dateDisplay, style: labelStyle),
        const Spacer(),
        const Icon(Icons.location_on_outlined,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(display.roomName, style: labelStyle),
      ],
    );
  }
}

/// Pending → approve/reject buttons row.  Resolved → status pill.
class _BookingActions extends StatelessWidget {
  /// Pre-built display adapter.
  final _BookingDisplay display;

  /// Approve callback (only invoked when [display.isPending]).
  final VoidCallback onApprove;

  /// Reject callback (only invoked when [display.isPending]).
  final VoidCallback onReject;

  const _BookingActions({
    required this.display,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (!display.isPending) return _ResolvedPill(display: display);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('ປະຕິເສດ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rejectRed,
              side: const BorderSide(color: AppColors.rejectRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.s),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('ອະນຸມັດ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryFill,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.s),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only status pill rendered in place of the action buttons when the
/// booking has already been approved or rejected.
class _ResolvedPill extends StatelessWidget {
  /// Pre-built display adapter.
  final _BookingDisplay display;

  const _ResolvedPill({required this.display});

  @override
  Widget build(BuildContext context) {
    // Same color + Lao label source as the card border and the booking lists.
    final style = BookingStatusStyle.of(display.booking.status);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: style.color,
          borderRadius: BorderRadius.circular(AppColors.chipRadius),
        ),
        child: Text(
          style.labelLao,
          style: TextStyle(
            color: style.onColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
