import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/schedules_controller.dart';
import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';

class SchedulesView extends GetView<SchedulesController> {
  const SchedulesView({super.key});

  static const _days = [
    'ທັງໝົດ',
    'ຈັນ',
    'ອັງຄານ',
    'ພຸດ',
    'ພະຫັດ',
    'ສຸກ',
    'ເສົາ',
    'ອາທິດ',
  ];

  static const _dayKeys = [
    '',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  Widget build(BuildContext context) {
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
              // ── Premium Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ຕາຕະລາງການສອນ',
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
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white),
                        tooltip: 'Refresh',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Day filter chips ────────────────────────────────────
              SizedBox(
                height: 44,
                child: Obx(() {
                  final currentSelectedDay = controller.selectedDay.value;
                  return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemCount: _days.length,
                      itemBuilder: (context, index) {
                        final isActive = currentSelectedDay == index;
                        return GestureDetector(
                          onTap: () => controller.selectedDay.value = index,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _days[index],
                              style: TextStyle(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                }),
              ),

              const SizedBox(height: 12),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final err = controller.errorMessage.value;
                  if (err.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off_rounded,
                                      size: 56,
                                      color:
                                          Colors.white.withOpacity(0.8)),
                                  const SizedBox(height: 16),
                                  Text(
                                    err,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: controller.refreshData,
                                    icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 20),
                                    label: const Text('ລອງໃໝ່'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
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

                  // Filter by selected day
                  final dayKey = _dayKeys[controller.selectedDay.value];
                  final filtered = dayKey.isEmpty
                      ? controller.schedules
                      : controller.schedules
                          .where((sp) =>
                              (sp.dayOfWeek ?? '').toLowerCase() ==
                              dayKey)
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      Colors.white.withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy_rounded,
                                    size: 56,
                                    color:
                                        Colors.white.withOpacity(0.7)),
                                const SizedBox(height: 12),
                                const Text(
                                  'ບໍ່ມີຕາຕະລາງ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dayKey.isEmpty
                                      ? 'ຍັງບໍ່ມີຕາຕະລາງການສອນ'
                                      : 'ບໍ່ມີຕາຕະລາງໃນວັນນີ້',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshData,
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final sp = filtered[index];
                        final subject =
                            sp.subject?.nameLao ?? 'ບໍ່ລະບຸວິຊາ';
                        final code = sp.subject?.subjectCode ?? '';
                        final room = sp.room?.roomCode ??
                            (sp.roomId != null
                                ? 'Room ${sp.roomId}'
                                : '-');
                        final time =
                            '${sp.startTime ?? '-'} - ${sp.endTime ?? '-'}';
                        final day = sp.dayOfWeek ?? '-';
                        final group =
                            sp.studentGroup?.stdGroupName ?? '';

                        final colors = [
                          AppColors.accentGreen,
                          AppColors.primary,
                          AppColors.borderPending,
                          AppColors.rejectRed,
                          AppColors.laoBlue,
                        ];
                        final themeColor =
                            colors[index % colors.length];

                        return _ScheduleCard(
                          subject: subject,
                          code: code,
                          room: room,
                          time: time,
                          day: day,
                          group: group,
                          themeColor: themeColor,
                        );
                      },
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

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleCard extends StatelessWidget {
  final String subject, code, room, time, day, group;
  final Color themeColor;

  const _ScheduleCard({
    required this.subject,
    required this.code,
    required this.room,
    required this.time,
    required this.day,
    required this.group,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Color indicator
                  Container(width: 5, color: themeColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  day.toUpperCase(),
                                  style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 14,
                                      color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$subject${code.isNotEmpty ? ' ($code)' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _InfoChip(
                                  icon: Icons.meeting_room_outlined,
                                  text: room),
                              if (group.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                _InfoChip(
                                    icon: Icons.group_outlined,
                                    text: group),
                              ],
                            ],
                          ),
                        ],
                      ),
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
