import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../controllers/teacher_home_controller.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';

class TeacherHomeView extends GetView<TeacherHomeController> {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<TeacherBottomNavController>();

    return GetBuilder<TeacherHomeController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      withBackground: true,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.dashboard();
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.refreshData,
          );
        }

        final user = controller.currentUser.value;
        String displayName = 'ອາຈານ';
        String roleLabel = '';
        String departmentLabel = '';
        if (user != null) {
          if (user.teacher != null) {
            final t = user.teacher!;
            displayName = '${t.nameLao} ${t.surnameLao}'.trim();
            departmentLabel = t.department?.deptNameLao ?? '';
          } else {
            displayName = user.username;
          }
          if (user.roles != null && user.roles!.isNotEmpty) {
            roleLabel = user.roles!.first;
          }
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              AppGreetingHeader(
                greeting: "ສະບາຍດີ, $displayName 👋",
                subtitle: "ພາກຮຽນ 2026",
                trailing: AppIconBubble(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Get.toNamed('/teacher-noti'),
                ),
              ),
              const SizedBox(height: 16),
              AppProfileHeader(
                name: displayName,
                subtitle: roleLabel,
                caption: departmentLabel,
                avatarFallback: displayName.isNotEmpty ? displayName : 'T',
              ),
              const SizedBox(height: 16),
              AppStatsBanner(
                items: [
                  AppStatItem(
                    label: "ວິຊາ",
                    value: controller.mySubjectsCount.value.toString(),
                    icon: Icons.grid_view_rounded,
                  ),
                  AppStatItem(
                    label: "ຈອງຫ້ອງ",
                    value: controller.myBookingsCount.value.toString(),
                    icon: Icons.meeting_room_rounded,
                  ),
                  AppStatItem(
                    label: "ລໍຖ້າ",
                    value:
                        controller.myPendingBookingsCount.value.toString(),
                    icon: Icons.pending_actions_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      icon: Icons.calendar_month_rounded,
                      label: 'ຕາຕະລາງ',
                      color: AppColors.statsBlue,
                      onTap: () => nav.changeTab(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickAction(
                      icon: Icons.meeting_room_rounded,
                      label: 'ຈອງຫ້ອງ',
                      color: AppColors.borderApproved,
                      onTap: () => nav.changeTab(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'ປະເມີນ',
                      color: AppColors.borderPending,
                      onTap: () => nav.changeTab(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickAction(
                      icon: Icons.person_rounded,
                      label: 'ໂປຣໄຟລ໌',
                      color: Colors.purple,
                      onTap: () => nav.changeTab(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "ຫ້ອງຮຽນມື້ນີ້",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ..._todaysClasses(nav),
            ],
          ),
        );
      }),
    );
        },
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _todaysClasses(TeacherBottomNavController nav) {
    final classes = controller.todaySchedules;
    final palette = <Color>[
      Colors.purple,
      AppColors.statsBlue,
      AppColors.borderApproved,
      AppColors.borderPending,
      AppColors.rejectRed,
      Colors.teal,
    ];

    if (classes.isEmpty) {
      return const [
        AppEmptyState(
          icon: Icons.event_available_rounded,
          title: 'ບໍ່ມີຫ້ອງຮຽນມື້ນີ້',
          subtitle: 'ມື້ພັກຜ່ອນ!',
        ),
      ];
    }

    return classes.asMap().entries.map((entry) {
      final i = entry.key;
      final sp = entry.value;
      final subject = sp.subject?.nameLao ?? sp.subject?.nameEng ?? 'ວິຊາ';
      final code = sp.subject?.subjectCode ?? '';
      final room = sp.room?.roomCode ??
          (sp.roomId != null ? 'ຫ້ອງ ${sp.roomId}' : '-');
      final time = '${sp.startTime ?? '-'} - ${sp.endTime ?? '-'}';
      final group = sp.studentGroup?.stdGroupName ?? '';
      final color = palette[i % palette.length];

      return AppClassCard(
        title: '$subject${code.isNotEmpty ? ' ($code)' : ''}',
        subtitle: group.isNotEmpty ? group : null,
        time: time,
        location: room,
        color: color,
        onTap: () => nav.changeTab(1),
      );
    }).toList();
  }
}
