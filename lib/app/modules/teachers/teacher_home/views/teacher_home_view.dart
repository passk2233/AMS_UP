import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';
import '../../teacher_widgets/home/teacher_home_header.dart';
import '../../teacher_widgets/home/teacher_quick_actions.dart';
import '../../teacher_widgets/home/todays_classes.dart';
import '../controllers/teacher_home_controller.dart';

/// Teacher dashboard — first tab in the teacher shell.
///
/// Renders, top-to-bottom: greeting, profile header, three-stat banner, a
/// row of quick-action shortcuts, and today's class list. All business
/// logic lives in [TeacherHomeController]; this view only composes
/// reactive sub-widgets.
class TeacherHomeView extends GetView<TeacherHomeController> {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<TeacherBottomNavController>();
    return AppPageScaffold(
      withBackground: true,
      body: _TeacherHomeBody(controller: controller, nav: nav),
    );
  }
}

/// Loading / error / content switch for the dashboard body.
class _TeacherHomeBody extends StatelessWidget {
  /// Source of reactive state.
  final TeacherHomeController controller;

  /// Bottom-nav controller used for quick-action navigation.
  final TeacherBottomNavController nav;

  const _TeacherHomeBody({required this.controller, required this.nav});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return AppRefreshableLoader(
          onRefresh: controller.refreshData,
          child: const AppLoading.dashboard(),
        );
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return AppErrorState(
          message: controller.errorMessage.value,
          onRetry: controller.refreshData,
        );
      }
      return _TeacherHomeContent(controller: controller, nav: nav);
    });
  }
}

/// Scrollable success state. Pulls a [TeacherDisplay] adapter off the
/// reactive user once and feeds the rendered sections from it.
class _TeacherHomeContent extends StatelessWidget {
  /// Source of reactive state.
  final TeacherHomeController controller;

  /// Bottom-nav controller used for quick-action navigation.
  final TeacherBottomNavController nav;

  const _TeacherHomeContent({required this.controller, required this.nav});

  @override
  Widget build(BuildContext context) {
    final display = TeacherDisplay(controller.currentUser.value);
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          TeacherGreeting(name: display.name),
          const SizedBox(height: 16),
          AppProfileHeader(
            name: display.name,
            subtitle: display.role,
            caption: display.department,
            photo: display.photo,
          ),
          const SizedBox(height: 16),
          TeacherStatsBanner(controller: controller),
          const SizedBox(height: 16),
          TeacherQuickActionRow(nav: nav),
          const SizedBox(height: AppSpacing.l),
          const Text('ຫ້ອງຮຽນມື້ນີ້', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s),
          ...buildTodaysClasses(controller, nav),
        ],
      ),
    );
  }
}
