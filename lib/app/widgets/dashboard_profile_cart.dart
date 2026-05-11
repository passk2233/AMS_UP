import 'package:flutter/material.dart';

import '../modules/data/models/user_model.dart';
import 'app_colors.dart';

/// A premium profile card showing the current admin user info and
/// dashboard stats (pending, approved, room usage %).
class ProfileCard extends StatelessWidget {
  final UserModel? user;
  final int pendingCount;
  final int approvedCount;
  final int roomInUsePercent;

  const ProfileCard({
    super.key,
    required this.user,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.roomInUsePercent = 0,
  });

  /// Derive display name from the user model
  String get _displayName {
    if (user == null) return 'ຜູ້ດູເເລລະບົບ';

    // Prefer teacher name if available
    if (user!.teacher != null) {
      final t = user!.teacher!;
      return '${t.nameLao} ${t.surnameLao}'.trim();
    }

    // Fall back to student name
    if (user!.student != null) {
      final s = user!.student!;
      return '${s.nameLao} ${s.surnameLao ?? ''}'.trim();
    }

    return user!.username;
  }

  /// Derive role label
  String get _roleLabel {
    if (user?.roles != null && user!.roles!.isNotEmpty) {
      return user!.roles!.first;
    }
    return 'ຜູ້ດູເເລລະບົບ';
  }

  /// Derive department from teacher's department
  String get _departmentLabel {
    if (user?.teacher?.department != null) {
      return user!.teacher!.department!.deptNameLao;
    }
    return 'ພາກວິຊາວິສະວະກຳຄອມພິວເຕີ ແລະ ເຕັກໂນໂລຊີຂໍ້ມູນຂ່າວສານ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserInfo(),
            const SizedBox(height: 16),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: Center(
            child: Text(
              _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'A',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name + role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _roleLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _departmentLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.pending_actions,
          label: 'ລໍຖ້າການຢືນຢັນ',
          value: '$pendingCount',
          color: AppColors.borderPending,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          icon: Icons.check_circle_outline,
          label: 'ລາຍການອະນຸມັດ',
          value: '$approvedCount',
          color: AppColors.borderApproved,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          icon: Icons.meeting_room_outlined,
          label: 'ການນຳໃຊ້ຫ້ອງ',
          value: '$roomInUsePercent%',
          color: AppColors.laoBlue,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
