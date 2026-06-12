import 'package:flutter/material.dart';
import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/widget.dart';

/// Flat list of enrollment score cards (or an empty state).
class ScoreList extends StatelessWidget {
  /// Enrollments to render.
  final List<EnrollmentModel> items;

  const ScoreList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'ບໍ່ພົບຄະແນນ',
        subtitle: 'ຄະແນນຈະສະແດງຢູ່ບ່ອນນີ້',
      );
    }

    return Column(
      children: items.map<Widget>((e) => _ScoreCard(enrollment: e)).toList(),
    );
  }
}

/// One subject score card — code, title, teacher, and the grade badge.
class _ScoreCard extends StatelessWidget {
  /// Enrollment row to render.
  final EnrollmentModel enrollment;

  const _ScoreCard({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final e = enrollment;
    final sub = e.studyPlan?.subject;
    final teacher = e.studyPlan?.teacher;
    final code = sub?.subjectCode ?? '-';
    final credit = sub?.credit ?? 0;
    final title = sub?.nameLao ?? sub?.nameEng ?? '-';
    final teacherName = teacher?.nameLao ?? teacher?.nameEng ?? '-';
    final grade = e.grade ?? '-';
    final gc = _gradeColors(grade);

    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$code  ~ $credit ໜ່ວຍກິດ",
                  style: const TextStyle(
                    // On-fill teal (4.70:1) — bright primary fails at 12px.
                    color: AppColors.primaryFill,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  teacherName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // Solid status fill; the grade letter is the figure, so
                  // it earns a real surface, not a 10% wash.
                  color: gc.bg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: gc.fg,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _gradeLabel(grade),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _gradeLabel(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 'ດີເລີດ';
      case 'B+':
      case 'B':
        return 'ດີ';
      case 'C+':
      case 'C':
        return 'ປານກາງ';
      case 'D+':
      case 'D':
        return 'ພໍຜ່ານ';
      case 'F':
        return 'ຕົກ';
      default:
        return '-';
    }
  }

  /// Badge background + foreground for a grade. Honest status mapping
  /// (emerald=good, blue=ok, amber=marginal, red=fail) with AA-safe
  /// foregrounds: white on emerald/blue/red (≥3:1 at 22px bold), ink on
  /// amber where white is only 2.15:1. See DESIGN.md.
  static ({Color bg, Color fg}) _gradeColors(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'B+':
        return (bg: AppColors.success, fg: Colors.white);
      case 'B':
      case 'C+':
      case 'C':
        return (bg: AppColors.info, fg: Colors.white);
      case 'D+':
      case 'D':
        return (bg: AppColors.warning, fg: AppColors.textPrimary);
      case 'F':
        return (bg: AppColors.danger, fg: Colors.white);
      default:
        return (bg: AppColors.textSecondary, fg: Colors.white);
    }
  }
}
