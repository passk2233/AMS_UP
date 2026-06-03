import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/widget.dart';

import 'teacher_info_view.dart';

/// Modal bottom sheet shown when a student taps a class on their schedule.
///
/// Surfaces the full detail of that class — subject, time, day, room, group —
/// and a tappable teacher row that routes to [TeacherInfoView]. [item] is one
/// entry from `ScheduleStudentController.filteredSchedules`; it carries the
/// formatted display strings plus the original [StudyPlanModel] under `plan`.
Future<void> showSubjectDetailSheet(
  BuildContext context,
  Map<String, dynamic> item,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _SubjectDetailSheet(item: item),
  );
}

class _SubjectDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;

  const _SubjectDetailSheet({required this.item});

  static const _laoDays = <int, String>{
    DateTime.monday: 'ວັນຈັນ',
    DateTime.tuesday: 'ວັນອັງຄານ',
    DateTime.wednesday: 'ວັນພຸດ',
    DateTime.thursday: 'ວັນພະຫັດ',
    DateTime.friday: 'ວັນສຸກ',
    DateTime.saturday: 'ວັນເສົາ',
    DateTime.sunday: 'ວັນອາທິດ',
  };

  @override
  Widget build(BuildContext context) {
    final plan = item['plan'] as StudyPlanModel?;
    final accent = item['color'] as Color? ?? AppColors.primary;

    final subjectTitle = (item['title'] as String?)?.trim().isNotEmpty == true
        ? item['title'] as String
        : (plan?.subject?.nameEng ?? plan?.subject?.nameLao ?? 'ວິຊາ');
    final code = plan?.subject?.subjectCode ?? '';
    final credit = plan?.subject?.credit;
    final laoName = plan?.subject?.nameLao ?? '';
    final showLaoName = laoName.isNotEmpty &&
        laoName.toLowerCase() != subjectTitle.toLowerCase();

    final time = (item['time'] as String?) ?? '-';
    final date = item['date'] as DateTime?;
    final dayValue = date == null
        ? '-'
        : '${_laoDays[date.weekday] ?? ''} (${date.day}/${date.month}/${date.year})';
    final room = plan?.room?.roomCode ??
        (item['location'] as String?) ??
        '-';
    final group = (item['subtitle'] as String?) ??
        plan?.studentGroup?.stdGroupName ??
        '-';

    final teacher = plan?.teacher;
    final teacherId = teacher?.id ?? plan?.teacherId ?? 0;
    final teacherName = _teacherName(teacher, item['instructor'] as String?);

    final codeCredit = [
      if (code.isNotEmpty) code,
      if (credit != null && credit > 0) '$credit ໜ່ວຍກິດ',
    ].join('  ·  ');

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E2E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header: subject icon + name + code/credit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.menu_book_rounded, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        if (showLaoName) ...[
                          const SizedBox(height: 2),
                          Text(
                            laoName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (codeCredit.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            codeCredit,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Detail rows
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.access_time_rounded,
                      label: 'ເວລາ',
                      value: time,
                    ),
                    AppInfoTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'ມື້ຮຽນ',
                      value: dayValue,
                    ),
                    AppInfoTile(
                      icon: Icons.meeting_room_outlined,
                      label: 'ຫ້ອງຮຽນ',
                      value: room,
                    ),
                    AppInfoTile(
                      icon: Icons.groups_outlined,
                      label: 'ກຸ່ມຮຽນ',
                      value: group,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const AppSectionTitle('ອາຈານປະຈຳວິຊາ'),
              _TeacherRow(
                name: teacherName,
                code: teacher?.teacherCode,
                onTap: teacherId > 0
                    ? () {
                        Navigator.of(context).pop();
                        Get.to(
                          () => TeacherInfoView(
                            seedTeacher: teacher,
                            teacherId: teacherId,
                            subjectName: subjectTitle,
                            groupName: group == '-' ? null : group,
                            timeLabel: time == '-' ? null : time,
                          ),
                          transition: Transition.cupertino,
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 20),

              AppSecondaryButton(
                label: 'ປິດ',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _teacherName(TeacherModel? t, String? fallback) {
    if (t != null) {
      final full = '${t.nameLao} ${t.surnameLao}'.trim();
      if (full.isNotEmpty) return full;
      if (t.nameEng.trim().isNotEmpty) return t.nameEng.trim();
    }
    final f = fallback?.trim();
    return (f != null && f.isNotEmpty) ? f : 'ບໍ່ລະບຸ';
  }
}

/// Tappable teacher affordance inside the sheet. Teal-accented with a chevron
/// to read unmistakably as "tap to open the teacher's page".
class _TeacherRow extends StatelessWidget {
  final String name;
  final String? code;
  final VoidCallback? onTap;

  const _TeacherRow({required this.name, this.code, this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final tappable = onTap != null;

    return AppSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tappable
                      ? ((code != null && code!.isNotEmpty)
                          ? 'ລະຫັດ $code · ແຕະເພື່ອເບິ່ງຂໍ້ມູນ'
                          : 'ແຕະເພື່ອເບິ່ງຂໍ້ມູນ')
                      : 'ບໍ່ມີຂໍ້ມູນເພີ່ມເຕີມ',
                  style: TextStyle(
                    fontSize: 12,
                    color: tappable
                        ? AppColors.primaryFill
                        : AppColors.textSecondary,
                    fontWeight: tappable ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryFill,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
