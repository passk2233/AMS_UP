import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/study_plan_model.dart';
import '../../../data/models/user_model.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';
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

/// Scrollable success state. Pulls a [_TeacherDisplay] adapter off the
/// reactive user once and feeds the rendered sections from it.
class _TeacherHomeContent extends StatelessWidget {
  /// Source of reactive state.
  final TeacherHomeController controller;

  /// Bottom-nav controller used for quick-action navigation.
  final TeacherBottomNavController nav;

  const _TeacherHomeContent({required this.controller, required this.nav});

  @override
  Widget build(BuildContext context) {
    final display = _TeacherDisplay(controller.currentUser.value);
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          _Greeting(name: display.name),
          const SizedBox(height: 16),
          AppProfileHeader(
            name: display.name,
            subtitle: display.role,
            caption: display.department,
            photo: display.photo,
          ),
          const SizedBox(height: 16),
          _StatsBanner(controller: controller),
          const SizedBox(height: 16),
          _QuickActionRow(nav: nav),
          const SizedBox(height: AppSpacing.l),
          const Text('ຫ້ອງຮຽນມື້ນີ້', style: AppTypography.heading),
          const SizedBox(height: AppSpacing.s),
          ..._TodaysClasses(controller: controller, nav: nav).build(),
        ],
      ),
    );
  }
}

/// Adapter that turns a [UserModel] into the display strings the dashboard
/// needs. Keeps the formatting decisions out of the widgets.
class _TeacherDisplay {
  final UserModel? user;

  const _TeacherDisplay(this.user);

  /// Preferred display name (teacher record → username fallback).
  String get name {
    if (user == null) return 'ອາຈານ';
    final t = user!.teacher;
    if (t != null) return '${t.nameLao} ${t.surnameLao}'.trim();
    return user!.username;
  }

  /// First role from the user's `roles` list, or empty.
  String get role {
    final roles = user?.roles;
    return (roles == null || roles.isEmpty) ? '' : roles.first;
  }

  /// Department name from the teacher relation, or empty.
  String get department => user?.teacher?.department?.deptNameLao ?? '';

  /// Stored profile photo path/URL; null when unset (header shows placeholder).
  String? get photo => user?.teacher?.photo;
}

/// Greeting line with a trailing notifications bubble.
class _Greeting extends StatelessWidget {
  /// Display name (already resolved).
  final String name;

  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    return AppGreetingHeader(
      greeting: 'ສະບາຍດີ, $name 👋',
      subtitle: 'ພາກຮຽນ 2026',
      trailing: const NotiBellButton(route: '/teacher-noti'),
    );
  }
}

/// Three-stat banner — subjects / bookings / pending.
class _StatsBanner extends StatelessWidget {
  /// Source of the reactive counters.
  final TeacherHomeController controller;

  const _StatsBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppStatsBanner(
      items: [
        AppStatItem(
          label: 'ວິຊາ',
          value: controller.mySubjectsCount.value.toString(),
          icon: Icons.grid_view_rounded,
        ),
        AppStatItem(
          label: 'ຈອງຫ້ອງ',
          value: controller.myBookingsCount.value.toString(),
          icon: Icons.meeting_room_rounded,
        ),
        AppStatItem(
          label: 'ລໍຖ້າ',
          value: controller.myPendingBookingsCount.value.toString(),
          icon: Icons.pending_actions_rounded,
        ),
      ],
    );
  }
}

/// Four-card quick-action row that jumps to the correct tab.
class _QuickActionRow extends StatelessWidget {
  /// Bottom-nav controller (tap targets call [TeacherBottomNavController.changeTab]).
  final TeacherBottomNavController nav;

  const _QuickActionRow({required this.nav});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_month_rounded,
            label: 'ຕາຕະລາງ',
            color: AppColors.statsBlue,
            onTap: () => nav.changeTab(TeacherTab.schedule),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.meeting_room_rounded,
            label: 'ຈອງຫ້ອງ',
            color: AppColors.borderApproved,
            onTap: () => nav.changeTab(TeacherTab.booking),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.bar_chart_rounded,
            label: 'ປະເມີນ',
            color: AppColors.borderPending,
            onTap: () => nav.changeTab(TeacherTab.evaluation),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_rounded,
            label: 'ໂປຣໄຟລ໌',
            color: AppColors.primary,
            onTap: () => nav.changeTab(TeacherTab.profile),
          ),
        ),
      ],
    );
  }
}

/// One tile in the quick-action row.
class _QuickAction extends StatelessWidget {
  /// Glyph rendered inside the colored bubble.
  final IconData icon;

  /// Caption.
  final String label;

  /// Tint applied to the icon bubble.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds the "today's classes" section — either an empty state or a list
/// of [AppClassCard]s tinted by an index-based palette.
class _TodaysClasses {
  /// Source of the reactive class list.
  final TeacherHomeController controller;

  /// Bottom-nav controller used so taps deep-link into the schedule tab.
  final TeacherBottomNavController nav;

  const _TodaysClasses({required this.controller, required this.nav});

  // Single brand accent — matches the student dashboard and avoids tinting
  // class cards in the reserved status colors. See the status rule in DESIGN.md.
  static const List<Color> _palette = <Color>[AppColors.info];

  List<Widget> build() {
    final classes = controller.todaySchedules;
    if (classes.isEmpty) {
      return const [
        AppEmptyState(
          icon: Icons.event_available_rounded,
          title: 'ບໍ່ມີຫ້ອງຮຽນມື້ນີ້',
          subtitle: 'ມື້ພັກຜ່ອນ!',
        ),
      ];
    }
    return [
      for (var i = 0; i < classes.length; i++)
        _ClassCard(
          plan: classes[i],
          color: _palette[i % _palette.length],
          onTap: () => nav.changeTab(TeacherTab.schedule),
        ),
    ];
  }
}

/// Single class card — adapter around [AppClassCard] that derives the
/// title / subtitle / time / room from a [StudyPlanModel].
class _ClassCard extends StatelessWidget {
  /// Study plan rendered by this card.
  final StudyPlanModel plan;

  /// Tint for the left border + icon bubble.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const _ClassCard({
    required this.plan,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subject = plan.subject?.nameLao ?? plan.subject?.nameEng ?? 'ວິຊາ';
    final code = plan.subject?.subjectCode ?? '';
    final room = plan.room?.roomCode ??
        (plan.roomId != null ? 'ຫ້ອງ ${plan.roomId}' : '-');
    final time = '${plan.startTime ?? '-'} - ${plan.endTime ?? '-'}';
    final group = plan.studentGroup?.stdGroupName ?? '';

    return AppClassCard(
      title: '$subject${code.isNotEmpty ? ' ($code)' : ''}',
      subtitle: group.isNotEmpty ? group : null,
      time: time,
      location: room,
      color: color,
      onTap: onTap,
    );
  }
}
