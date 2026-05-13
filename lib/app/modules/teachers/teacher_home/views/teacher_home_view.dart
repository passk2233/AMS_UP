import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../controllers/teacher_home_controller.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';

class TeacherHomeView extends GetView<TeacherHomeController> {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<TeacherBottomNavController>();

    return Scaffold(
      body: Stack(
        children: [
          // Background image (same as student)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AssetImages.login2),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: controller.refreshData,
                          icon:
                              const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('ລອງໃໝ່'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A68FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: const Color(0xFF4A68FF),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _topHeader(),
                    const SizedBox(height: 12),
                    _profile(),
                    const SizedBox(height: 12),
                    _stats(),
                    const SizedBox(height: 16),
                    _quickActions(nav),
                    const SizedBox(height: 16),
                    _todaysClasses(nav),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Top Header (matches student _topHeader) ──────────────────────────────
  Widget _topHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Spring 2026",
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            Text(
              "Welcome back",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        IconButton(
          onPressed: controller.refreshData,
          icon: const Icon(Icons.refresh_rounded, size: 28),
        ),
      ],
    );
  }

  // ── Profile Row (matches student _profile) ───────────────────────────────
  Widget _profile() {
    final user = controller.currentUser.value;
    String displayName = 'Teacher';
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

    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.blue[100],
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (roleLabel.isNotEmpty)
                Text(
                  roleLabel,
                  style: const TextStyle(color: Colors.blueAccent),
                ),
              if (departmentLabel.isNotEmpty)
                Text(
                  departmentLabel,
                  style:
                      const TextStyle(color: Colors.green, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Bar (matches student _stats) ───────────────────────────────────
  Widget _stats() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF4A68FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("Subjects",
              controller.mySubjectsCount.value.toString(), Icons.grid_view),
          _statItem("Bookings",
              controller.myBookingsCount.value.toString(), Icons.meeting_room),
          _statItem("Pending",
              controller.myPendingBookingsCount.value.toString(),
              Icons.pending_actions),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: Colors.white70, size: 14),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Quick Actions (matches student style) ────────────────────────────────
  Widget _quickActions(TeacherBottomNavController nav) {
    return Row(
      children: [
        _quickActionItem(
          icon: Icons.calendar_month,
          label: 'Schedule',
          color: Colors.blue,
          onTap: () => nav.changeTab(1),
        ),
        const SizedBox(width: 10),
        _quickActionItem(
          icon: Icons.meeting_room,
          label: 'Booking',
          color: Colors.green,
          onTap: () => nav.changeTab(2),
        ),
        const SizedBox(width: 10),
        _quickActionItem(
          icon: Icons.bar_chart,
          label: 'Evaluation',
          color: Colors.orange,
          onTap: () => nav.changeTab(3),
        ),
        const SizedBox(width: 10),
        _quickActionItem(
          icon: Icons.person,
          label: 'Profile',
          color: Colors.purple,
          onTap: () => nav.changeTab(4),
        ),
      ],
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Today's Classes (matches student _todaysClasses) ─────────────────────
  Widget _todaysClasses(TeacherBottomNavController nav) {
    final classes = controller.todaySchedules;
    final palette = <Color>[
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.redAccent,
      Colors.teal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Classes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (classes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.event_available_rounded,
                    size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No classes today',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Enjoy your free day!',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ...classes.asMap().entries.map((entry) {
          final i = entry.key;
          final sp = entry.value;
          final subject =
              sp.subject?.nameLao ?? sp.subject?.nameEng ?? 'Subject';
          final code = sp.subject?.subjectCode ?? '';
          final room = sp.room?.roomCode ??
              (sp.roomId != null ? 'Room ${sp.roomId}' : '-');
          final time = '${sp.startTime ?? '-'} - ${sp.endTime ?? '-'}';
          final group = sp.studentGroup?.stdGroupName ?? '';
          final color = palette[i % palette.length];

          return _classCard(
            title: '$subject${code.isNotEmpty ? ' ($code)' : ''}',
            desc: group,
            time: time,
            color: color,
            location: room,
            onTap: () => nav.changeTab(1),
          );
        }),
      ],
    );
  }

  Widget _classCard({
    required String title,
    required String desc,
    required String time,
    required Color color,
    required String location,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: color)),
                ),
                Text(time,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey),
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
      ),
    );
  }
}
