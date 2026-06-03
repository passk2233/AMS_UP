import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/user_model.dart';
import '../controllers/teacher_profile_controller.dart';

/// Profile tab in the teacher shell.
///
/// Shows the avatar header, three info cards (account / roles / activity),
/// and a destructive sign-out button. All business logic lives in
/// [TeacherProfileController]; this view is composition only.
class TeacherProfileView extends GetView<TeacherProfileController> {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TeacherProfileController>()) {
      Get.put(TeacherProfileController());
    }
    return AppPageScaffold(
      title: 'ໂປຣໄຟລ໌',
      trailing: const NotiBellButton(route: '/teacher-noti'),
      body: _TeacherProfileBody(controller: controller),
    );
  }
}

/// Loading / error / content switch for the profile screen.
class _TeacherProfileBody extends StatelessWidget {
  /// Source of reactive state.
  final TeacherProfileController controller;

  const _TeacherProfileBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return AppRefreshableLoader(
          onRefresh: controller.fetchProfile,
          child: const AppLoading.profile(),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.fetchProfile,
        );
      }
      return _TeacherProfileContent(controller: controller);
    });
  }
}

/// Scrollable success state with the hero card and three info cards.
class _TeacherProfileContent extends StatelessWidget {
  /// Source of reactive state.
  final TeacherProfileController controller;

  const _TeacherProfileContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value;
    final displayName = _resolveName(user);
    final email = user?.email ?? '-';
    final roles = user?.roles ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: Column(
        children: [
          AppProfileHeader(
            name: displayName,
            subtitle: email,
            caption: roles.join(', '),
            avatarFallback: displayName.isNotEmpty ? displayName : '?',
          ),
          const SizedBox(height: 25),
          const AppSectionTitle('ຂໍ້ມູນບັນຊີ'),
          _AccountInfoCard(controller: controller, email: email),
          const SizedBox(height: 20),
          const AppSectionTitle('ບົດບາດ & ສິດ'),
          _RolesCard(roles: roles),
          const SizedBox(height: 20),
          const AppSectionTitle('ກິດຈະກຳ'),
          _ActivityCard(controller: controller),
          const SizedBox(height: 20),
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

  /// Prefer the teacher name from the relation, otherwise fall back to the
  /// username.
  String _resolveName(UserModel? user) {
    if (user == null) return '-';
    final t = user.teacher;
    if (t != null) {
      final full = '${t.nameLao} ${t.surnameLao}'.trim();
      if (full.isNotEmpty) return full;
    }
    return user.username;
  }
}

/// "ຂໍ້ມູນບັນຊີ" — id, username, email, active status.
class _AccountInfoCard extends StatelessWidget {
  /// Source of reactive state.
  final TeacherProfileController controller;

  /// Pre-resolved email string.
  final String email;

  const _AccountInfoCard({required this.controller, required this.email});

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value;
    return AppSurfaceCard(
      child: Column(
        children: [
          AppInfoTile(
            icon: Icons.badge_outlined,
            label: 'ລະຫັດ',
            value: '${user?.id ?? '-'}',
          ),
          AppInfoTile(
            icon: Icons.account_circle_outlined,
            label: 'ຊື່ຜູ້ໃຊ້',
            value: user?.username ?? '-',
          ),
          AppInfoTile(
            icon: Icons.email_outlined,
            label: 'ອີເມວ',
            value: email,
          ),
          AppInfoTile(
            icon: Icons.verified_user_outlined,
            label: 'ສະຖານະ',
            value: controller.accountStatus,
            valueColor: user?.active == 1
                ? AppColors.borderApproved
                : AppColors.rejectRed,
          ),
        ],
      ),
    );
  }
}

/// "ບົດບາດ & ສິດ" — one tile per role with a color-coded icon and subtitle,
/// or a single empty-state tile when the user has no roles.
class _RolesCard extends StatelessWidget {
  /// User's role list.
  final List<String> roles;

  const _RolesCard({required this.roles});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return const AppSurfaceCard(
        child: Column(
          children: [
            AppInfoTile(
              icon: Icons.person_outline,
              label: 'ບົດບາດ',
              value: 'ບໍ່ມີບົດບາດ',
            ),
          ],
        ),
      );
    }

    return AppSurfaceCard(
      child: Column(
        children: [
          for (final r in roles) _RoleTile(role: r, info: _RoleInfo.fromName(r)),
        ],
      ),
    );
  }
}

/// One role row inside [_RolesCard].
class _RoleTile extends StatelessWidget {
  /// Raw role name.
  final String role;

  /// Pre-resolved style (icon + color + description).
  final _RoleInfo info;

  const _RoleTile({required this.role, required this.info});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(info.icon, color: info.color, size: 20),
      ),
      title: Text(
        role,
        style: TextStyle(color: info.color, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        info.desc,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.check_circle_rounded, color: info.color, size: 18),
    );
  }
}

/// "ກິດຈະກຳ" — created-at + updated-at info rows.
class _ActivityCard extends StatelessWidget {
  /// Source of reactive state.
  final TeacherProfileController controller;

  const _ActivityCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = controller.user.value;
    final updated = user?.updatedAt;
    return AppSurfaceCard(
      child: Column(
        children: [
          AppInfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'ສະມາຊິກຕັ້ງແຕ່',
            value: controller.memberSince,
          ),
          AppInfoTile(
            icon: Icons.update_outlined,
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

/// Visual style + description for a role.
class _RoleInfo {
  /// Glyph rendered next to the role name.
  final IconData icon;

  /// Tint applied to the row.
  final Color color;

  /// Lao subtitle describing the role's scope.
  final String desc;

  const _RoleInfo(this.icon, this.color, this.desc);

  /// Style for a given role name, with a neutral fallback for unknown roles.
  factory _RoleInfo.fromName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const _RoleInfo(
          Icons.shield_rounded,
          Colors.indigo,
          'ເຂົ້າເຖິງລະບົບທັງໝົດ',
        );
      case 'teacher':
        return const _RoleInfo(
          Icons.school_rounded,
          AppColors.borderApproved,
          'ສອນ & ຈັດການການປະເມີນ',
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
          Colors.grey,
          'ບົດບາດທົ່ວໄປ',
        );
    }
  }
}
