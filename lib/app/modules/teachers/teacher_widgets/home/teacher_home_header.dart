import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/user_model.dart';
import '../../teacher_home/controllers/teacher_home_controller.dart';

/// Adapter that turns a [UserModel] into the display strings the dashboard
/// needs. Keeps the formatting decisions out of the widgets.
class TeacherDisplay {
  final UserModel? user;

  const TeacherDisplay(this.user);

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
class TeacherGreeting extends StatelessWidget {
  /// Display name (already resolved).
  final String name;

  const TeacherGreeting({super.key, required this.name});

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
class TeacherStatsBanner extends StatelessWidget {
  /// Source of the reactive counters.
  final TeacherHomeController controller;

  const TeacherStatsBanner({super.key, required this.controller});

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
