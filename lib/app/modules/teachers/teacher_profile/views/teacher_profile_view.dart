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
      topBar: const AppTopBar(notiRoute: '/teacher-noti'),
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
            photo: user?.teacher?.photo,
          ),
          const SizedBox(height: 25),
          const AppSectionTitle('ຂໍ້ມູນບັນຊີ'),
          _AccountInfoCard(controller: controller, email: email),
          const SizedBox(height: 20),
          RolesCard(roles: roles, current: 'teacher'),
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

/// "ຂໍ້ມູນບັນຊີ" — username, email, active status.
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

