import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_storage.dart';
import '../services/role_routing.dart';
import 'app_colors.dart';
import 'app_dialogs.dart';
import 'app_shell.dart';

/// In-app role switcher shown on each role's profile screen.
///
/// A user may hold several roles (e.g. teacher + student). Each role has its
/// own home shell; this card lets them jump to another role's shell without
/// logging out. Renders nothing when there is no *other* role to switch to,
/// so it is safe to drop unconditionally into every profile view.
class RoleSwitcherCard extends StatelessWidget {
  /// All role names from the user model (may be empty).
  final List<String> roles;

  /// The role whose shell is currently showing ('admin' / 'teacher' /
  /// 'student') — excluded from the switch targets.
  final String current;

  const RoleSwitcherCard({
    super.key,
    required this.roles,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final targets = RoleRouting.known(roles)
        .where((r) => r != RoleRouting.canon(current))
        .toList();
    if (targets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Owns its own top gap so single-role profiles (card hidden) keep the
        // surrounding spacing unchanged.
        const SizedBox(height: 20),
        const AppSectionTitle('ສະຫຼັບບົດບາດ'),
        AppSurfaceCard(
          child: Column(
            children: [
              for (final role in targets)
                _SwitchTile(role: role, ui: _RoleUi.of(role)),
            ],
          ),
        ),
      ],
    );
  }
}

/// One "switch to X" row. Tapping persists the new active role and replaces
/// the whole navigation stack with that role's home — structurally the same
/// move as a logout-then-land, so GetX disposes the old shell's controllers.
class _SwitchTile extends StatelessWidget {
  final String role;
  final _RoleUi ui;

  const _SwitchTile({required this.role, required this.ui});

  Future<void> _switch() async {
    final route = RoleRouting.routeFor(role);
    if (route == null) return;
    final confirmed = await AppDialogs.showConfirmation(
      title: 'ສະຫຼັບບົດບາດ',
      message: 'ຕ້ອງການສະຫຼັບໄປໜ້າ "${ui.label}" ບໍ?',
      confirmText: 'ສະຫຼັບ',
      cancelText: 'ຍົກເລີກ',
    );
    if (confirmed != true) return;
    await AuthStorage.writeActiveRole(role);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: _switch,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ui.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(ui.icon, color: ui.color, size: 20),
      ),
      title: Text(
        ui.label,
        style: TextStyle(color: ui.color, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        ui.desc,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.swap_horiz_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

/// Icon + color + Lao label for a switch target. Mirrors the role styling
/// used by the read-only role cards elsewhere in the profile screens.
class _RoleUi {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  const _RoleUi(this.icon, this.color, this.label, this.desc);

  factory _RoleUi.of(String role) {
    switch (role) {
      case 'admin':
        return const _RoleUi(
          Icons.shield_rounded,
          AppColors.info,
          'ຜູ້ດູແລລະບົບ',
          'ເຂົ້າສູ່ໜ້າຜູ້ດູແລ',
        );
      case 'teacher':
        return const _RoleUi(
          Icons.school_rounded,
          AppColors.borderApproved,
          'ອາຈານ',
          'ເຂົ້າສູ່ໜ້າອາຈານ',
        );
      case 'student':
        return const _RoleUi(
          Icons.menu_book_rounded,
          AppColors.borderPending,
          'ນັກສຶກສາ',
          'ເຂົ້າສູ່ໜ້ານັກສຶກສາ',
        );
      default:
        return const _RoleUi(
          Icons.person_rounded,
          Colors.grey,
          'ບົດບາດ',
          '',
        );
    }
  }
}
