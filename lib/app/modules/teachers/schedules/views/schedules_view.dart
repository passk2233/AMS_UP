import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/schedules_controller.dart';

class SchedulesView extends GetView<SchedulesController> {
  const SchedulesView({super.key});

  static const _days = [
    'All',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Schedule',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.blue, size: 20),
                onPressed: controller.refreshData,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Day filter strip (matches student calendar strip style) ─────
          _buildDayFilterStrip(),
          const SizedBox(height: 8),

          // ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final err = controller.errorMessage.value;
              if (err.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      err,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
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
                          (sp.dayOfWeek ?? '').toLowerCase() == dayKey)
                      .toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No classes scheduled.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: Colors.blue,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final sp = filtered[index];
                    final subject =
                        sp.subject?.nameLao ?? sp.subject?.nameEng ?? 'Subject';
                    final code = sp.subject?.subjectCode ?? '';
                    final room = sp.room?.roomCode ??
                        (sp.roomId != null ? 'Room ${sp.roomId}' : '-');
                    final time =
                        '${sp.startTime ?? '-'} - ${sp.endTime ?? '-'}';
                    final day = sp.dayOfWeek ?? '-';
                    final group = sp.studentGroup?.stdGroupName ?? '';

                    final palette = <Color>[
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.redAccent,
                      Colors.teal,
                    ];
                    final color = palette[index % palette.length];

                    return _buildScheduleCard(
                      title:
                          '$subject${code.isNotEmpty ? ' ($code)' : ''}',
                      subtitle: group,
                      time: time,
                      day: day,
                      location: room,
                      color: color,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Day filter strip (matches student _buildCalendarStrip style) ────────
  Widget _buildDayFilterStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 44,
        child: Obx(() {
          final currentSelected = controller.selectedDay.value;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _days.length,
            itemBuilder: (context, index) {
              final isSelected = currentSelected == index;
              return GestureDetector(
                onTap: () => controller.selectedDay.value = index,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _days[index],
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ── Schedule Card (matches student _buildScheduleCard) ─────────────────
  Widget _buildScheduleCard({
    required String title,
    required String subtitle,
    required String time,
    required String day,
    required String location,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                time,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  day.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
