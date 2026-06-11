import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../admin_widgets/profile/profile_hero_card.dart';
import '../../admin_widgets/profile/profile_info_cards.dart';
import '../../admin_widgets/profile/role_list_card.dart';
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
          Obx(() => ProfileHeroCard(user: controller.user.value)),
          const SizedBox(height: AppSpacing.m),
          Obx(() {
            controller.user.value;
            return AccountInfoCard(controller: controller);
          }),
          const SizedBox(height: AppSpacing.s + 4),
          Obx(() => RoleListCard(roles: controller.user.value?.roles)),
          const SizedBox(height: AppSpacing.s + 4),
          Obx(() {
            controller.user.value;
            return ActivityCard(controller: controller);
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
