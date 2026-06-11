import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/study_plan_model.dart';
import '../../teacher_home/controllers/teacher_home_controller.dart';
import '../../teacher_navigator_bar/teacher_bottom_nav_controller.dart';

// Single brand accent — matches the student dashboard and avoids tinting
// class cards in the reserved status colors. See the status rule in DESIGN.md.
const List<Color> _palette = <Color>[AppColors.info];

/// Builds the "today's classes" section — either an empty state or a list
/// of [AppClassCard]s tinted by an index-based palette.
List<Widget> buildTodaysClasses(
  TeacherHomeController controller,
  TeacherBottomNavController nav,
) {
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
      TeacherClassCard(
        plan: classes[i],
        color: _palette[i % _palette.length],
        onTap: () => nav.changeTab(TeacherTab.schedule),
      ),
  ];
}

/// Single class card — adapter around [AppClassCard] that derives the
/// title / subtitle / time / room from a [StudyPlanModel].
class TeacherClassCard extends StatelessWidget {
  /// Study plan rendered by this card.
  final StudyPlanModel plan;

  /// Tint for the left border + icon bubble.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const TeacherClassCard({
    super.key,
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
