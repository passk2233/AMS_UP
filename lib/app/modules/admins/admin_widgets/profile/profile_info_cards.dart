import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../admin_profile/controllers/admin_profile_controller.dart';
import 'profile_section_card.dart';

/// "ຂໍ້ມູນບັນຊີ" — user ID, username, email, and active status.
class AccountInfoCard extends StatelessWidget {
  /// Source of reactive user data and derived getters.
  final AdminProfileController controller;

  const AccountInfoCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final u = controller.user.value;
    return ProfileSectionCard(
      icon: Icons.person_rounded,
      title: 'ຂໍ້ມູນບັນຊີ',
      child: Column(
        children: [
          ProfileInfoRow(
            icon: Icons.badge_rounded,
            label: 'ລະຫັດຜູ້ໃຊ້',
            value: '${u?.id ?? '-'}',
          ),
          const ProfileRowDivider(),
          ProfileInfoRow(
            icon: Icons.account_circle_rounded,
            label: 'ຊື່ຜູ້ໃຊ້',
            value: u?.username ?? '-',
          ),
          const ProfileRowDivider(),
          ProfileInfoRow(
            icon: Icons.email_rounded,
            label: 'ອີເມລ',
            value: u?.email ?? '-',
          ),
          const ProfileRowDivider(),
          ProfileInfoRow(
            icon: Icons.verified_user_rounded,
            label: 'ສະຖານະ',
            value: controller.accountStatus,
            valueColor: u?.active == 1
                ? AppColors.borderApproved
                : AppColors.rejectRed,
          ),
        ],
      ),
    );
  }
}

/// "ກິດຈະກຳ" — created-at + updated-at info rows.
class ActivityCard extends StatelessWidget {
  /// Source of reactive user data and derived getters.
  final AdminProfileController controller;

  const ActivityCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final u = controller.user.value;
    final updated = u?.updatedAt;
    return ProfileSectionCard(
      icon: Icons.access_time_rounded,
      title: 'ກິດຈະກຳ',
      child: Column(
        children: [
          ProfileInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'ສ້າງບັນຊີ',
            value: controller.memberSince,
          ),
          const ProfileRowDivider(),
          ProfileInfoRow(
            icon: Icons.update_rounded,
            label: 'ອັບເດດລ່າສຸດ',
            value: updated == null
                ? '-'
                : '${updated.day}/${updated.month}/${updated.year}',
          ),
        ],
      ),
    );
  }
}
