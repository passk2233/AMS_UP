import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../controllers/teacher_profile_controller.dart';

class TeacherProfileView extends GetView<TeacherProfileController> {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TeacherProfileController>()) {
      Get.put(TeacherProfileController());
    }

    return GetBuilder<TeacherProfileController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      title: 'ໂປຣໄຟລ໌',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.profile();
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: () => controller.onInit(),
          );
        }

        final user = controller.user.value;
        String displayName = user?.username ?? '-';
        final email = user?.email ?? '-';
        final roles = user?.roles ?? [];
        if (user?.teacher != null) {
          final t = user!.teacher!;
          final name = '${t.nameLao} ${t.surnameLao}'.trim();
          if (name.isNotEmpty) displayName = name;
        }

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

              const AppSectionTitle("ຂໍ້ມູນບັນຊີ"),
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.badge_outlined,
                      label: "ລະຫັດ",
                      value: '${user?.id ?? '-'}',
                    ),
                    AppInfoTile(
                      icon: Icons.account_circle_outlined,
                      label: "ຊື່ຜູ້ໃຊ້",
                      value: user?.username ?? '-',
                    ),
                    AppInfoTile(
                      icon: Icons.email_outlined,
                      label: "ອີເມວ",
                      value: email,
                    ),
                    AppInfoTile(
                      icon: Icons.verified_user_outlined,
                      label: "ສະຖານະ",
                      value: controller.accountStatus,
                      valueColor: user?.active == 1
                          ? AppColors.borderApproved
                          : AppColors.rejectRed,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const AppSectionTitle("ບົດບາດ & ສິດ"),
              _buildRolesSection(),

              const SizedBox(height: 20),

              const AppSectionTitle("ກິດຈະກຳ"),
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: "ສະມາຊິກຕັ້ງແຕ່",
                      value: controller.memberSince,
                    ),
                    AppInfoTile(
                      icon: Icons.update_outlined,
                      label: "ອັບເດດລ່າສຸດ",
                      value: user?.updatedAt != null
                          ? '${user!.updatedAt!.day}/${user.updatedAt!.month}/${user.updatedAt!.year}'
                          : '-',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Obx(() => AppSignOutButton(
                    onPressed: controller.logout,
                    isLoading: controller.isLoggingOut.value,
                  )),

            
            ],
          ),
        );
      }),
    );
        },
      ),
    );
  }

  Widget _buildRolesSection() {
    final roles = controller.user.value?.roles;
    if (roles == null || roles.isEmpty) {
      return AppSurfaceCard(
        child: Column(
          children: const [
            AppInfoTile(
              icon: Icons.person_outline,
              label: "ບົດບາດ",
              value: "ບໍ່ມີບົດບາດ",
            ),
          ],
        ),
      );
    }
    return AppSurfaceCard(
      child: Column(
        children: roles.map((r) {
          final info = _getRoleInfo(r);
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
              r,
              style: TextStyle(
                color: info.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              info.desc,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: Icon(Icons.check_circle_rounded,
                color: info.color, size: 18),
          );
        }).toList(),
      ),
    );
  }

  _RoleInfo _getRoleInfo(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _RoleInfo(
            Icons.shield_rounded, Colors.indigo, 'ເຂົ້າເຖິງລະບົບທັງໝົດ');
      case 'teacher':
        return _RoleInfo(Icons.school_rounded, AppColors.borderApproved,
            'ສອນ & ຈັດການການປະເມີນ');
      case 'student':
        return _RoleInfo(Icons.menu_book_rounded, AppColors.borderPending,
            'ເຂົ້າເຖິງຂໍ້ມູນການຮຽນ');
      default:
        return _RoleInfo(Icons.person_rounded, Colors.grey, 'ບົດບາດທົ່ວໄປ');
    }
  }
}

class _RoleInfo {
  final IconData icon;
  final Color color;
  final String desc;
  const _RoleInfo(this.icon, this.color, this.desc);
}
