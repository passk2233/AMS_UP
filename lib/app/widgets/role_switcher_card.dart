import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_storage.dart';
import '../services/role_routing.dart';
import 'app_colors.dart';
import 'app_dialogs.dart';

/// "ສິດທິ & ບົດບາດ" card — shows every role the user holds and, when they hold
/// more than one, lets them tap another role to switch into its shell.
///
/// The tile for the role they're currently using shows a check; the others
/// become tappable "switch" buttons. Used verbatim by all three profile
/// screens so the roles/permissions card looks and behaves the same for admin,
/// teacher, and student.
class RolesCard extends StatelessWidget {
  /// All role names from the user model (may be empty).
  final List<String> roles;

  /// The role whose shell is currently showing ('admin' / 'teacher' /
  /// 'student') — shown with a check instead of a switch affordance.
  final String current;

  const RolesCard({super.key, required this.roles, required this.current});

  @override
  Widget build(BuildContext context) {
    final known = RoleRouting.known(roles);
    final canSwitch = known.length > 1;
    final currentCanon = RoleRouting.canon(current);

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
              const Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.laoBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ສິດທິ & ບົດບາດ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (canSwitch) ...[
                const Spacer(),
                Text(
                  'ແຕະເພື່ອສະຫຼັບ',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (known.isEmpty)
            Text(
              'ບໍ່ມີບົດບາດ',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            )
          else
            for (final role in known)
              _RoleTile(
                ui: _RoleUi.of(role),
                isCurrent: role == currentCanon,
                onSwitch: role == currentCanon ? null : () => confirmSwitchRole(role),
              ),
        ],
      ),
    );
  }
}

/// Confirm, persist the chosen active role, and replace the whole navigation
/// stack with that role's home — structurally the same move as a logout-then-
/// land, so GetX disposes the previous shell's controllers. No-op if the role
/// has no home shell or the user cancels the dialog.
Future<void> confirmSwitchRole(String role) async {
  final route = RoleRouting.routeFor(role);
  if (route == null) return;
  final confirmed = await AppDialogs.showConfirmation(
    title: 'ສະຫຼັບບົດບາດ',
    message: 'ຕ້ອງການສະຫຼັບໄປໜ້າ "${_RoleUi.of(role).label}" ບໍ?',
    confirmText: 'ສະຫຼັບ',
    cancelText: 'ຍົກເລີກ',
  );
  if (confirmed != true) return;
  await AuthStorage.writeActiveRole(role);
  Get.offAllNamed(route);
}

/// One role row. Renders a check when it's the active role, or a tappable
/// swap affordance otherwise.
class _RoleTile extends StatelessWidget {
  final _RoleUi ui;
  final bool isCurrent;

  /// Tap handler — `null` for the current role (not switchable to itself).
  final VoidCallback? onSwitch;

  const _RoleTile({
    required this.ui,
    required this.isCurrent,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onSwitch,
      contentPadding: EdgeInsets.zero,
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
        isCurrent ? 'ກຳລັງໃຊ້ຢູ່' : ui.desc,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Icon(
        isCurrent ? Icons.check_circle_rounded : Icons.swap_horiz_rounded,
        color: isCurrent ? ui.color : AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

/// Icon + color + Lao label/description for a role.
class _RoleUi {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  const _RoleUi(this.icon, this.color, this.label, this.desc);

  factory _RoleUi.of(String role) {
    switch (RoleRouting.canon(role)) {
      case 'admin':
        return const _RoleUi(
          Icons.shield_rounded,
          AppColors.info,
          'ຜູ້ດູແລລະບົບ',
          'ເຂົ້າເຖິງລະບົບທັງໝົດ',
        );
      case 'teacher':
        return const _RoleUi(
          Icons.school_rounded,
          AppColors.borderApproved,
          'ອາຈານ',
          'ສອນ & ຈັດການການປະເມີນ',
        );
      case 'student':
        return const _RoleUi(
          Icons.menu_book_rounded,
          AppColors.borderPending,
          'ນັກສຶກສາ',
          'ເຂົ້າເຖິງຂໍ້ມູນການຮຽນ',
        );
      default:
        return const _RoleUi(
          Icons.person_rounded,
          Colors.grey,
          'ບົດບາດ',
          'ບົດບາດທົ່ວໄປ',
        );
    }
  }
}
