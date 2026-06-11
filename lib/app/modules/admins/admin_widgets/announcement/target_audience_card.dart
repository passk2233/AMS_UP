import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/student_group_model.dart';
import '../../../data/models/student_type_model.dart';
import '../../announcement/controllers/announcement_controller.dart';
import 'announcement_form_blocks.dart';
import 'individual_search_section.dart';

/// Target-audience selector + audience-specific filters.
class TargetAudienceCard extends StatelessWidget {
  /// Source of reactive audience state.
  final AnnouncementController controller;

  const TargetAudienceCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnSectionCard(
      icon: Icons.groups_rounded,
      title: 'ກຸ່ມເປົ້າໝາຍ',
      child: Obx(() {
        final audience = controller.selectedAudience.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnnFieldLabel('ສົ່ງຫາ'),
            const SizedBox(height: 8),
            _AudienceChips(controller: controller, selected: audience),
            if (audience == AnnouncementAudience.individual) ...[
              const SizedBox(height: 14),
              IndividualSearchSection(controller: controller),
            ],
            if (audience == AnnouncementAudience.students) ...[
              const SizedBox(height: 14),
              _StudentFiltersGrid(controller: controller),
            ],
            if (audience == AnnouncementAudience.all ||
                audience == AnnouncementAudience.teachers) ...[
              const SizedBox(height: 14),
              _DepartmentSelector(controller: controller),
            ],
          ],
        );
      }),
    );
  }
}

/// Single-select [AppFilterChipRow] — one chip per audience option.
class _AudienceChips extends StatelessWidget {
  /// Source of reactive audience state.
  final AnnouncementController controller;

  /// Currently selected audience index.
  final int selected;

  const _AudienceChips({required this.controller, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AppFilterChipRow(
      items: [
        for (final label in controller.audienceLabels)
          AppFilterChip(label: label),
      ],
      selectedIndex: selected,
      onSelected: _onSelect,
      activeColor: AppColors.info,
      padding: EdgeInsets.zero,
    );
  }

  void _onSelect(int i) {
    controller.selectedAudience.value = i;
    if (i != AnnouncementAudience.individual) {
      controller.clearIndividualSelection();
    }
  }
}

/// Two-row grid of department / year / group / type dropdowns shown only
/// when [AnnouncementAudience.students] is active.
class _StudentFiltersGrid extends StatelessWidget {
  /// Source of reactive filter state.
  final AnnouncementController controller;

  const _StudentFiltersGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _DepartmentSelector(controller: controller)),
            const SizedBox(width: 12),
            Expanded(child: _YearSelector(controller: controller)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StudentGroupSelector(controller: controller)),
            const SizedBox(width: 12),
            Expanded(child: _StudentTypeSelector(controller: controller)),
          ],
        ),
      ],
    );
  }
}

/// Department dropdown — used standalone for All/Teachers, and inside the
/// student-filters grid for Students.
class _DepartmentSelector extends StatelessWidget {
  /// Source of reactive department selection.
  final AnnouncementController controller;

  const _DepartmentSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnLabeledDropdown<int?>(
      label: 'ພາກວິຊາ',
      value: controller.selectedDepartment.value?.id,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13)),
        ),
        for (final d in controller.departments)
          DropdownMenuItem<int?>(
            value: d.id,
            child: Text(
              d.deptNameLao,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (val) => controller.selectedDepartment.value = val == null
          ? null
          : controller.departments.firstWhereOrNull(
              (DepartmentModel d) => d.id == val,
            ),
    );
  }
}

/// Year-level dropdown (1..4 / all).
class _YearSelector extends StatelessWidget {
  /// Source of reactive year selection.
  final AnnouncementController controller;

  const _YearSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnLabeledDropdown<int>(
      label: 'ຊັ້ນປີ',
      value: controller.selectedYear.value,
      items: [
        for (var i = 0; i < controller.yearLabels.length; i++)
          DropdownMenuItem<int>(
            value: i,
            child: Text(
              controller.yearLabels[i],
              style: const TextStyle(fontSize: 13),
            ),
          ),
      ],
      onChanged: (val) {
        if (val != null) controller.selectedYear.value = val;
      },
    );
  }
}

/// Student-group dropdown.
class _StudentGroupSelector extends StatelessWidget {
  /// Source of reactive group selection.
  final AnnouncementController controller;

  const _StudentGroupSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnLabeledDropdown<int?>(
      label: 'ກຸ່ມນັກສຶກສາ',
      value: controller.selectedStudentGroup.value?.id,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13)),
        ),
        for (final g in controller.studentGroups)
          DropdownMenuItem<int?>(
            value: g.id,
            child: Text(
              g.stdGroupName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (val) => controller.selectedStudentGroup.value = val == null
          ? null
          : controller.studentGroups.firstWhereOrNull(
              (StudentGroupModel g) => g.id == val,
            ),
    );
  }
}

/// Student-type dropdown.
class _StudentTypeSelector extends StatelessWidget {
  /// Source of reactive type selection.
  final AnnouncementController controller;

  const _StudentTypeSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnLabeledDropdown<int?>(
      label: 'ປະເພດນັກສຶກສາ',
      value: controller.selectedStudentType.value?.id,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13)),
        ),
        for (final t in controller.studentTypes)
          DropdownMenuItem<int?>(
            value: t.id,
            child: Text(
              t.stdTypeNameLao,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (val) => controller.selectedStudentType.value = val == null
          ? null
          : controller.studentTypes.firstWhereOrNull(
              (StudentTypeModel t) => t.id == val,
            ),
    );
  }
}
