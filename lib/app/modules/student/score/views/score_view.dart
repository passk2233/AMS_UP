import 'package:flutter/material.dart';
import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/score_controller.dart';

class ScoreView extends GetView<ScoreController> {
  const ScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ScoreController>()) {
      Get.put(ScoreController());
    }

    return AppPageScaffold(
      withBackground: true,
      title: 'ຄະແນນ',
      trailing: const NotiBellButton(route: '/student-noti'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return AppRefreshableLoader(
            onRefresh: controller.fetchData,
            child: const AppLoading.score(),
          );
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.fetchData,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppProfileHeader(
                  name: controller.displayName,
                  subtitle: controller.studentCode,
                  caption: _captionText(),
                  photo: controller.photo,
                ),
                const SizedBox(height: AppSpacing.m),
                _TranscriptStatStrip(
                  cells: [
                    _StatCell(
                      value: controller.totalSubjects.toString(),
                      label: 'ລວມວິຊາ',
                      color: AppColors.statsBlue,
                    ),
                    _StatCell(
                      value: controller.totalCredits.toString(),
                      label: 'ລວມໜ່ວຍກິດ',
                      color: AppColors.accentGreen,
                    ),
                    _StatCell(
                      value: controller.gpa.toStringAsFixed(2),
                      label: 'ເກຣດສະເລ່ຍລວມ',
                      // White value sits on this fill; bright primary is 2.43:1,
                      // the on-fill teal clears AA at 4.70:1. See DESIGN.md.
                      color: AppColors.primaryFill,
                    ),
                    _StatCell(
                      value:
                          '${controller.currentTermNumber}/${controller.totalProgramTerms}',
                      label: 'ເທີມ',
                      color: AppColors.accentYellow,
                      valueColor: AppColors.textPrimary,
                      labelColor: AppColors.textPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                const Text("ຄະແນນແຕ່ລະພາກຮຽນ", style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.s + 2),
                _buildSemesterChips(),
                const Divider(height: 28),
                _buildSelectedSemester(),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _captionText() {
    final curri = controller.curriculumName;
    final year = controller.currentAcademicYear;
    if (year <= 0) return curri;
    return '$curri · ປີ $year';
  }

  Widget _buildSemesterChips() {
    final groups = controller.semestersNewestFirst;
    if (groups.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: groups.map((s) {
          final selected = controller.selectedSemesterId.value == s.semasterId;
          final label = controller.chipLabelFor(s);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: () => controller.changeSemester(s.semasterId),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected
                    ? AppColors.statsBlue
                    : AppColors.cardBg,
                side: BorderSide(
                  color: selected ? AppColors.statsBlue : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.chipRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: const Size(0, AppColors.minTouchTarget),
                // Flat — the system bans Material elevation tiers. The selected
                // chip already reads via its filled background + bold label.
                elevation: 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.line1,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (label.line2.isNotEmpty)
                    Text(
                      label.line2,
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedSemester() {
    // No grouping available — show every enrollment as a flat list.
    if (controller.semesters.isEmpty) {
      return _buildScoreList(controller.enrollments);
    }

    final semester = controller.selectedSemester;
    if (semester == null) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'ບໍ່ພົບຄະແນນ',
        subtitle: 'ຄະແນນຈະສະແດງຢູ່ບ່ອນນີ້',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.labelFor(semester),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s + 4),
        _buildScoreList(semester.enrollments),
        const SizedBox(height: AppSpacing.xs),
        _buildSemesterSummary(),
      ],
    );
  }

  Widget _buildSemesterSummary() {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _summaryColumn(
                title: 'ລວມເທີມ',
                detail:
                    '${controller.selectedSemesterCredits} ໜ່ວຍກິດ · ${controller.selectedSemesterSubjects} ວິຊາ',
                metricLabel: 'GPA',
                metricValue: controller.selectedSemesterGpa.toStringAsFixed(2),
                color: AppColors.statsBlue,
              ),
            ),
            const VerticalDivider(width: 24),
            Expanded(
              child: _summaryColumn(
                title: 'ລວມສະສົມ',
                detail: '${controller.selectedCumulativeCredits} ໜ່ວຍກິດ',
                metricLabel: 'CGPA',
                metricValue: controller.selectedCumulativeGpa.toStringAsFixed(
                  2,
                ),
                color: AppColors.borderApproved,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryColumn({
    required String title,
    required String detail,
    required String metricLabel,
    required String metricValue,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$metricLabel ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              metricValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreList(List<EnrollmentModel> items) {
    if (items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'ບໍ່ພົບຄະແນນ',
        subtitle: 'ຄະແນນຈະສະແດງຢູ່ບ່ອນນີ້',
      );
    }

    return Column(
      children: items.map<Widget>((e) {
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
      }).toList(),
    );
  }

  String _gradeLabel(String grade) {
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
  ({Color bg, Color fg}) _gradeColors(String grade) {
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

/// Horizontal four-cell stat strip mirroring the official transcript header
/// (total subjects · total credits · overall GPA · term progress).
class _TranscriptStatStrip extends StatelessWidget {
  final List<_StatCell> cells;
  const _TranscriptStatStrip({required this.cells});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.cardRadius),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final cell in cells)
              Expanded(
                child: Container(
                  color: cell.color,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cell.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: cell.valueColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cell.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: cell.labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCell {
  final String value;
  final String label;
  final Color color;
  final Color valueColor;
  final Color labelColor;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    this.valueColor = Colors.white,
    this.labelColor = Colors.white,
  });
}
