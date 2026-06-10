import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../../data/models/user_model.dart';
import '../controllers/admin_profile_controller.dart';

/// Profile tab in the admin shell.
///
/// Shows a gradient avatar hero, three info cards (account / roles /
/// activity), and a destructive sign-out button. All business logic lives
/// in [AdminProfileController]; this view only wires reactive state into
/// dumb sub-widgets.
class AdminProfileView extends GetView<AdminProfileController> {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetImages.dashboardBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const AdminAppBar(),
            Expanded(child: _AdminProfileBody(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Loading / error / content switch for the profile screen.
class _AdminProfileBody extends StatelessWidget {
  /// Source of reactive state.
  final AdminProfileController controller;

  const _AdminProfileBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading.profile();
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.fetchProfile,
        );
      }
      return _AdminProfileContent(controller: controller);
    });
  }
}

/// Scrollable success state with the hero card and three info cards.
class _AdminProfileContent extends StatelessWidget {
  /// Source of reactive state.
  final AdminProfileController controller;

  const _AdminProfileContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      child: Column(
        children: [
          Obx(() => _ProfileHeroCard(user: controller.user.value)),
          const SizedBox(height: AppSpacing.m),
          Obx(() {
            controller.user.value;
            return _AccountInfoCard(controller: controller);
          }),
          const SizedBox(height: AppSpacing.s + 4),
          Obx(() => _RoleListCard(roles: controller.user.value?.roles)),
          const SizedBox(height: AppSpacing.s + 4),
          Obx(() {
            controller.user.value;
            return _ActivityCard(controller: controller);
          }),
          const SizedBox(height: AppSpacing.l),
          Obx(
            () => AppSignOutButton(
              onPressed: controller.logout,
              isLoading: controller.isLoggingOut.value,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indigo gradient hero with avatar initials, username, email, and role
/// pills.
class _ProfileHeroCard extends StatelessWidget {
  /// Source user — `null` falls back to placeholders.
  final UserModel? user;

  const _ProfileHeroCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user?.username ?? '?');
    final roles = user?.roles ?? const <String>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _AvatarCircle(initials: initials),
          const SizedBox(height: AppSpacing.s + 4),
          Text(
            user?.username ?? '-',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '-',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            _RolePillRow(roles: roles),
          ],
        ],
      ),
    );
  }

  /// Up to 2 uppercase letters extracted from the user's name.
  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// 80×80 white-bordered circle showing the user's initials.
class _AvatarCircle extends StatelessWidget {
  /// 1–2 character initial string.
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of translucent role pills shown in the hero card.
class _RolePillRow extends StatelessWidget {
  /// Role names — each rendered as one pill.
  final List<String> roles;

  const _RolePillRow({required this.roles});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final r in roles)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppColors.chipRadius),
            ),
            child: Text(
              r,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// White rounded card with an indigo icon-headed title and a child slot.
class _SectionCard extends StatelessWidget {
  /// Leading icon next to the title.
  final IconData icon;

  /// Card title.
  final String title;

  /// Body content (typically a list of [_InfoRow]s).
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.laoBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// One label-value row inside a [_SectionCard].
class _InfoRow extends StatelessWidget {
  /// Leading glyph.
  final IconData icon;

  /// Left-side caption.
  final String label;

  /// Right-side value text.
  final String value;

  /// Optional override for the value color (status indicators).
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin divider used between [_InfoRow]s inside a [_SectionCard].
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.shade100);
  }
}

/// "ຂໍ້ມູນບັນຊີ" — user ID, username, email, and active status.
class _AccountInfoCard extends StatelessWidget {
  /// Source of reactive user data and derived getters.
  final AdminProfileController controller;

  const _AccountInfoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final u = controller.user.value;
    return _SectionCard(
      icon: Icons.person_rounded,
      title: 'ຂໍ້ມູນບັນຊີ',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_rounded,
            label: 'ລະຫັດຜູ້ໃຊ້',
            value: '${u?.id ?? '-'}',
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.account_circle_rounded,
            label: 'ຊື່ຜູ້ໃຊ້',
            value: u?.username ?? '-',
          ),
          const _RowDivider(),
          _InfoRow(
            icon: Icons.email_rounded,
            label: 'ອີເມລ',
            value: u?.email ?? '-',
          ),
          const _RowDivider(),
          _InfoRow(
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

/// "ສິດທິ & ບົດບາດ" — one tinted tile per role, or an empty-state caption
/// when the user has no roles.
class _RoleListCard extends StatelessWidget {
  /// Role names from the user model (may be `null` or empty).
  final List<String>? roles;

  const _RoleListCard({required this.roles});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
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

/// "ກິດຈະກຳ" — created-at + updated-at info rows.
class _ActivityCard extends StatelessWidget {
  /// Source of reactive user data and derived getters.
  final AdminProfileController controller;

  const _ActivityCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final u = controller.user.value;
    final updated = u?.updatedAt;
    return _SectionCard(
      icon: Icons.access_time_rounded,
      title: 'ກິດຈະກຳ',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'ສ້າງບັນຊີ',
            value: controller.memberSince,
          ),
          const _RowDivider(),
          _InfoRow(
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
