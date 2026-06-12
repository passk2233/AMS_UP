import 'package:flutter/material.dart';

import '../modules/data/models/user_model.dart';
import 'app_avatar.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Gradient profile + stats banner rendered on the admin dashboard.
///
/// The card is purely presentational — derive name/role/department from the
/// supplied [UserModel] and three integer counters. Tap targets and gradients
/// follow brand tokens from [AppColors].
class ProfileCard extends StatelessWidget {
  /// Logged-in user; `null` falls back to neutral placeholders.
  final UserModel? user;

  /// Count of bookings still awaiting approval (top-left stat).
  final int pendingCount;

  /// Count of bookings approved this period (top-middle stat).
  final int approvedCount;

  /// % of rooms currently in use (top-right stat).
  final int roomInUsePercent;

  const ProfileCard({
    super.key,
    required this.user,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.roomInUsePercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final display = _ProfileDisplay(user);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s + 4,
        AppSpacing.m,
        0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // White text/icons sit on this banner, so both stops must clear AA.
          // The bright primary (#40b4cd) is only 2.43:1 under white; the
          // darker on-fill teal (4.70:1) into Info Blue (6.2:1) stays legible
          // across the whole sweep and mirrors the admin app bar. See DESIGN.md.
          colors: [AppColors.primaryFill, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryFill.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            _ProfileIdentity(display: display),
            const SizedBox(height: AppSpacing.m),
            _ProfileStatsRow(
              pendingCount: pendingCount,
              approvedCount: approvedCount,
              roomInUsePercent: roomInUsePercent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Adapter that turns a [UserModel] into the strings the card needs.
class _ProfileDisplay {
  final UserModel? user;

  const _ProfileDisplay(this.user);

  /// Preferred display name (teacher → student → username → fallback).
  String get name {
    if (user == null) return 'ຜູ້ດູເເລລະບົບ';
    final teacher = user!.teacher;
    if (teacher != null) {
      return '${teacher.nameLao} ${teacher.surnameLao}'.trim();
    }
    final student = user!.student;
    if (student != null) {
      return '${student.nameLao} ${student.surnameLao ?? ''}'.trim();
    }
    return user!.username;
  }

  /// First entry in the user's `roles` list, or the admin fallback.
  String get role {
    final roles = user?.roles;
    if (roles != null && roles.isNotEmpty) return roles.first;
    return 'ຜູ້ດູເເລລະບົບ';
  }

  /// Department name from `user.teacher.department`, or the IT department
  /// fallback used by the design.
  String get department {
    final dept = user?.teacher?.department;
    if (dept != null) return dept.deptNameLao;
    return 'ພາກວິຊາວິສະວະກຳຄອມພິວເຕີ ແລະ ເຕັກໂນໂລຊີຂໍ້ມູນຂ່າວສານ';
  }

  /// Stored profile photo (teacher → student). Null/broken paths fall back to
  /// the bundled placeholder inside [AppAvatar].
  String? get photo => user?.teacher?.photo ?? user?.student?.photo;
}

/// Avatar + name + role + department block (top of the card).
class _ProfileIdentity extends StatelessWidget {
  /// Pre-built display adapter.
  final _ProfileDisplay display;

  const _ProfileIdentity({required this.display});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileAvatar(photo: display.photo),
        const SizedBox(width: AppSpacing.s + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                display.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _SubLine(text: display.role),
              const SizedBox(height: 2),
              _SubLine(text: display.department),
            ],
          ),
        ),
      ],
    );
  }
}

/// Circular photo avatar rendered on the gradient surface, ringed in white.
class _ProfileAvatar extends StatelessWidget {
  /// Stored photo path/URL; null/broken shows the bundled placeholder.
  final String? photo;

  const _ProfileAvatar({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      // 44 = 48 − 2px ring on each side, so the photo sits flush inside it.
      child: AppAvatar(
        photo: photo,
        radius: 22,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

/// One-line muted-white caption used for role / department.
class _SubLine extends StatelessWidget {
  /// Caption text.
  final String text;

  const _SubLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.85),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Three side-by-side counters that sit under the identity row.
class _ProfileStatsRow extends StatelessWidget {
  /// Count of pending bookings.
  final int pendingCount;

  /// Count of approved bookings.
  final int approvedCount;

  /// Room usage percentage.
  final int roomInUsePercent;

  const _ProfileStatsRow({
    required this.pendingCount,
    required this.approvedCount,
    required this.roomInUsePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileStatTile(
          icon: Icons.pending_actions,
          label: 'ລໍຖ້າການຢືນຢັນ',
          value: '$pendingCount',
          color: AppColors.borderPending,
        ),
        const SizedBox(width: AppSpacing.s),
        _ProfileStatTile(
          icon: Icons.check_circle_outline,
          label: 'ລາຍການອະນຸມັດ',
          value: '$approvedCount',
          color: AppColors.borderApproved,
        ),
        const SizedBox(width: AppSpacing.s),
        _ProfileStatTile(
          icon: Icons.meeting_room_outlined,
          label: 'ການນຳໃຊ້ຫ້ອງ',
          value: '$roomInUsePercent%',
          color: AppColors.laoBlue,
        ),
      ],
    );
  }
}

/// One translucent stat tile inside [_ProfileStatsRow].
class _ProfileStatTile extends StatelessWidget {
  /// Glyph rendered at the top of the tile.
  final IconData icon;

  /// Lower caption.
  final String label;

  /// Large value displayed under the icon.
  final String value;

  /// Tint applied to the icon.
  final Color color;

  const _ProfileStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          // Dark wash (not white) so the white value + label keep contrast on
          // the gradient; a translucent-white tile lightens it and fails AA.
          color: Colors.black.withValues(alpha: 0.18),
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
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
