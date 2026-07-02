import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/student_group_model.dart';
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
              _StudentGroupSelector(controller: controller),
            ],
            // All / Teachers have no filters: those audiences always reach
            // every matching person.
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

/// Student-group dropdown — the only student filter.
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
