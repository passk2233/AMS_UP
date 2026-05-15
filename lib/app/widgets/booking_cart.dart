import 'package:flutter/material.dart';

import '../modules/data/models/room_booking_model.dart';
import 'app_colors.dart';

class BookingCard extends StatelessWidget {
  final RoomBookingModel booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  // ── Status helpers ──────────────────────────────────────────────────────
  bool get _isPending => booking.status.toLowerCase() == 'pending';
  bool get _isApproved => booking.status.toLowerCase() == 'approved';
  bool get _isRejected => booking.status.toLowerCase() == 'rejected';

  Color get _borderColor => _isApproved
      ? AppColors.borderApproved
      : _isPending
          ? AppColors.borderPending
          : AppColors.rejectRed;

  /// Derive a display name from the nested User (teacher or student name).
  String get _displayName {
    final user = booking.user;
    if (user == null) return 'Unknown User';

    // Prefer teacher name
    if (user.teacher != null) {
      final t = user.teacher!;
      return '${t.nameLao} ${t.surnameLao}'.trim();
    }

    // Fall back to student name
    if (user.student != null) {
      final s = user.student!;
      return '${s.nameLao} ${s.surnameLao ?? ''}'.trim();
    }

    return user.username;
  }

  /// Whether the booker is a student
  bool get _isStudent => booking.user?.stdId != null;

  /// Room display name
  String get _roomName => booking.room?.roomCode ?? 'Room ${booking.roomId}';

  /// Format time display (start_time – end_time)
  String get _timeDisplay {
    if (booking.startTime.isEmpty && booking.endTime.isEmpty) {
      return '';
    }
    return '${booking.startTime} - ${booking.endTime}';
  }

  /// Format booking date
  String get _dateDisplay {
    final d = booking.bookingDate;
    const weekdays = [
      'ວັນຈັນ', 'ວັນອັງຄານ', 'ວັນພຸດ', 'ວັນພະຫັດ',
      'ວັນສຸກ', 'ວັນເສົາ', 'ວັນອາທິດ'
    ];
    const months = [
      'ມັງກອນ', 'ກຸມພາ', 'ມີນາ', 'ເມສາ',
      'ພຶດສະພາ', 'ມິຖຸນາ', 'ກໍລະກົດ', 'ສິງຫາ',
      'ກັນຍາ', 'ຕຸລາ', 'ພະຈິກ', 'ທັນວາ'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 6),
            if (booking.purpose != null && booking.purpose!.isNotEmpty) ...[
              Text(
                booking.purpose!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
            ],
            _buildUserRow(),
            const SizedBox(height: 6),
            _buildRoomDateRow(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _roomName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.laoBlue,
            ),
          ),
        ),
        if (_timeDisplay.isNotEmpty)
          Text(
            _timeDisplay,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isApproved ? AppColors.laoBlue : Colors.transparent,
        border: Border.all(
          color: _isApproved ? AppColors.laoBlue : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: _isApproved
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : _isRejected
              ? Icon(Icons.close, color: Colors.grey.shade400, size: 14)
              : null,
    );
  }

  Widget _buildUserRow() {
    return Row(
      children: [
        Flexible(
          child: Text(
            _displayName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.laoBlue,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _isStudent ? Colors.blue.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _isStudent ? '(Student)' : '(Teacher)',
            style: TextStyle(
              fontSize: 11,
              color:
                  _isStudent ? Colors.blue.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomDateRow() {
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          _dateDisplay,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        const Icon(Icons.location_on_outlined,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          _roomName,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (!_isPending) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _isApproved
                ? AppColors.borderApproved.withValues(alpha: 0.1)
                : AppColors.rejectRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isApproved ? 'Approved' : 'Rejected',
            style: TextStyle(
              color:
                  _isApproved ? AppColors.borderApproved : AppColors.rejectRed,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rejectRed,
              side: const BorderSide(color: AppColors.rejectRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
