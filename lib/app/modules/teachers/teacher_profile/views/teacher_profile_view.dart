import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../../profiles/controllers/profiles_controller.dart';

class TeacherProfileView extends GetView<ProfilesController> {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // If controller is not registered, put it
    if (!Get.isRegistered<ProfilesController>()) {
      Get.put(ProfilesController());
    }
    
    return GetBuilder<ProfilesController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AssetImages.dashboardBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Teacher custom top bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'ໂປຣໄຟລ໌',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: controller.refreshData,
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              tooltip: 'Refresh',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          );
                        }
                        if (controller.errorMessage.value.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off_rounded,
                                    size: 56, color: Colors.white.withOpacity(0.8)),
                                const SizedBox(height: 12),
                                Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: controller.fetchProfile,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 18),
                                  label: const Text('ລອງໃໝ່'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                          child: Column(
                            children: [
                              _buildAvatarHeader(),
                              const SizedBox(height: 16),
                              _buildAccountInfoCard(),
                              const SizedBox(height: 12),
                              _buildRolesCard(),
                              const SizedBox(height: 12),
                              _buildActivityCard(),
                              const SizedBox(height: 24),
                              _buildLogoutButton(),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVATAR HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvatarHeader() {
    return Obx(() {
      final user = controller.user.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
              ),
              child: Center(
                child: Text(
                  _avatarInitials(user?.username ?? '?'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              user?.username ?? '-',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Email
            Text(
              user?.email ?? '-',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            // Role badges
            if (user?.roles != null && user!.roles!.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: user.roles!
                    .map((r) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            r,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      );
    });
  }

  String _avatarInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCOUNT INFO CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAccountInfoCard() {
    return _card(
      icon: Icons.person_rounded,
      title: 'ຂໍ້ມູນບັນຊີ',
      child: Obx(() {
        final u = controller.user.value;
        return Column(
          children: [
            _infoRow(Icons.badge_rounded, 'User ID', '${u?.id ?? '-'}'),
            _divider(),
            _infoRow(Icons.account_circle_rounded, 'Username',
                u?.username ?? '-'),
            _divider(),
            _infoRow(Icons.email_rounded, 'Email', u?.email ?? '-'),
            _divider(),
            _infoRow(
              Icons.verified_user_rounded,
              'ສະຖານະ',
              controller.accountStatus,
              valueColor: u?.active == 1
                  ? AppColors.borderApproved
                  : AppColors.rejectRed,
            ),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLES CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRolesCard() {
    return _card(
      icon: Icons.admin_panel_settings_rounded,
      title: 'ສິດທິ & ບົດບາດ',
      child: Obx(() {
        final roles = controller.user.value?.roles;
        if (roles == null || roles.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('ບໍ່ມີບົດບາດ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          );
        }
        return Column(
          children: roles.map((r) {
            final roleInfo = _getRoleInfo(r);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: roleInfo.color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: roleInfo.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: roleInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(roleInfo.icon, color: roleInfo.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: roleInfo.color,
                          ),
                        ),
                        Text(
                          roleInfo.desc,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded,
                      color: roleInfo.color, size: 18),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  _RoleInfo _getRoleInfo(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _RoleInfo(Icons.shield_rounded, AppColors.laoBlue,
            'ສິດເຂົ້າເຖິງລະບົບທັງໝົດ');
      case 'teacher':
        return _RoleInfo(Icons.school_rounded, AppColors.borderApproved,
            'ຄຸ້ມຄອງການສອນ & ການປະເມີນ');
      case 'student':
        return _RoleInfo(Icons.menu_book_rounded, AppColors.borderPending,
            'ເຂົ້າເຖິງຂໍ້ມູນການຮຽນ');
      default:
        return _RoleInfo(Icons.person_rounded, AppColors.textSecondary,
            'ບົດບາດທົ່ວໄປ');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVITY CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActivityCard() {
    return _card(
      icon: Icons.access_time_rounded,
      title: 'ກິດຈະກຳ',
      child: Obx(() {
        final u = controller.user.value;
        return Column(
          children: [
            _infoRow(Icons.calendar_today_rounded, 'ສ້າງບັນຊີ',
                controller.memberSince),
            _divider(),
            _infoRow(
              Icons.update_rounded,
              'ອັບເດດລ່າສຸດ',
              u?.updatedAt != null
                  ? '${u!.updatedAt!.day}/${u.updatedAt!.month}/${u.updatedAt!.year}'
                  : '-',
            ),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGOUT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLogoutButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed:
              controller.isLoggingOut.value ? null : controller.logout,
          icon: controller.isLoggingOut.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.logout_rounded, size: 20),
          label: Text(
            controller.isLoggingOut.value ? 'ກຳລັງອອກ...' : 'ອອກຈາກລະບົບ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rejectRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.rejectRed.withOpacity(0.6),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
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

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }
}

class _RoleInfo {
  final IconData icon;
  final Color color;
  final String desc;
  const _RoleInfo(this.icon, this.color, this.desc);
}
