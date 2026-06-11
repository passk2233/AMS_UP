import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import 'profile_section_card.dart';

/// "ສິດທິ & ບົດບາດ" — one tinted tile per role, or an empty-state caption
/// when the user has no roles.
class RoleListCard extends StatelessWidget {
  /// Role names from the user model (may be `null` or empty).
  final List<String>? roles;

  const RoleListCard({super.key, required this.roles});

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.admin_panel_settings_rounded,
      title: 'ສິດທິ & ບົດບາດ',
      child: (roles == null || roles!.isEmpty)
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ບໍ່ມີບົດບາດ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            )
          : Column(
              children: [
                for (final role in roles!)
                  _RoleTile(role: role, info: _RoleInfo.fromName(role)),
              ],
            ),
    );
  }
}

/// One role tile with a color-coded icon and human-readable subtitle.
class _RoleTile extends StatelessWidget {
  /// Raw role name from the API.
  final String role;

  /// Pre-resolved color / icon / description.
  final _RoleInfo info;

  const _RoleTile({required this.role, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: info.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(info.icon, color: info.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: info.color,
                  ),
                ),
                Text(
                  info.desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: info.color, size: 18),
        ],
      ),
    );
  }
}

/// Visual style + description for a single role.
class _RoleInfo {
  /// Glyph rendered next to the role name.
  final IconData icon;

  /// Tint applied to the tile background, border, and name text.
  final Color color;

  /// Lao subtitle describing the role's scope.
  final String desc;

  const _RoleInfo(this.icon, this.color, this.desc);

  /// Build the style for a given role name. Falls back to a neutral
  /// "general role" style for unknown roles.
  factory _RoleInfo.fromName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const _RoleInfo(
          Icons.shield_rounded,
          AppColors.laoBlue,
          'ສິດເຂົ້າເຖິງລະບົບທັງໝົດ',
        );
      case 'teacher':
        return const _RoleInfo(
          Icons.school_rounded,
          AppColors.borderApproved,
          'ຄຸ້ມຄອງການສອນ & ການປະເມີນ',
        );
      case 'student':
        return const _RoleInfo(
          Icons.menu_book_rounded,
          AppColors.borderPending,
          'ເຂົ້າເຖິງຂໍ້ມູນການຮຽນ',
        );
      default:
        return const _RoleInfo(
          Icons.person_rounded,
          AppColors.textSecondary,
          'ບົດບາດທົ່ວໄປ',
        );
    }
  }
}
