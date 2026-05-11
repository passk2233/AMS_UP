import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';

import '../controllers/teacher_home_controller.dart';
import '../../../../widgets/widget.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';

class TeacherHomeView extends GetView<TeacherHomeController> {
  const TeacherHomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final nav = Get.find<TeacherBottomNavController>();

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
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dashboard (Teacher)',
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
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (controller.errorMessage.value.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off_rounded,
                                      size: 56, color: Colors.white.withOpacity(0.8)),
                                  const SizedBox(height: 16),
                                  Text(
                                    controller.errorMessage.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: controller.refreshData,
                                    icon: const Icon(Icons.refresh_rounded, size: 20),
                                    label: const Text('ລອງໃໝ່'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshData,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileCard(
                            user: controller.currentUser.value,
                            pendingCount: controller.myPendingBookingsCount.value,
                            approvedCount: controller.myBookingsCount.value,
                            roomInUsePercent: controller.mySubjectsCount.value,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: _QuickActionsRow(
                              onTapSchedules: () => nav.changeTab(1),
                              onTapBooking: () => nav.changeTab(2),
                              onTapEvaluation: () => nav.changeTab(3),
                              onTapProfile: () => nav.changeTab(4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SectionTitle(
                              title: 'ຕາຕະລາງວັນນີ້',
                              subtitle:
                                  'ຈຳນວນ ${controller.todaySchedules.length} ຄາບຮຽນ',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: controller.todaySchedules.map((sp) {
                                final subject = sp.subject?.nameLao ?? 'ບໍ່ລະບຸວິຊາ';
                                final code = sp.subject?.subjectCode ?? '';
                                final room = sp.room?.roomCode ??
                                    (sp.roomId != null ? 'Room ${sp.roomId}' : '-');
                                final time =
                                    '${sp.startTime ?? '-'} - ${sp.endTime ?? '-'}';
                                final group = sp.studentGroup?.stdGroupName ?? '';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => nav.changeTab(1),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '$subject${code.isNotEmpty ? ' ($code)' : ''}',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.watch_later_outlined, size: 14, color: Colors.grey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              time,
                                                              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey.shade600),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              room,
                                                              style: TextStyle(color: Colors.grey.shade600),
                                                            ),
                                                            if (group.isNotEmpty) ...[
                                                              const SizedBox(width: 8),
                                                              Icon(Icons.group_outlined, size: 14, color: Colors.grey.shade600),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                group,
                                                                style: TextStyle(color: Colors.grey.shade600),
                                                              ),
                                                            ]
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (controller.todaySchedules.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.event_available_rounded, size: 48, color: AppColors.primary.withOpacity(0.7)),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'ມື້ນີ້ບໍ່ມີຕາຕະລາງສອນ',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ພັກຜ່ອນໃຫ້ສະບາຍ!',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onTapSchedules;
  final VoidCallback onTapBooking;
  final VoidCallback onTapEvaluation;
  final VoidCallback onTapProfile;
  const _QuickActionsRow({
    required this.onTapSchedules,
    required this.onTapBooking,
    required this.onTapEvaluation,
    required this.onTapProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_month_rounded,
            label: 'ຕາຕະລາງ',
            onTap: onTapSchedules,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.meeting_room_rounded,
            label: 'ຈອງຫ້ອງ',
            onTap: onTapBooking,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.bar_chart_rounded,
            label: 'ປະເມີນ',
            onTap: onTapEvaluation,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_outline_rounded,
            label: 'ໂປຣໄຟລ໌',
            onTap: onTapProfile,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              highlightColor: Colors.white.withOpacity(0.2),
              splashColor: Colors.white.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
