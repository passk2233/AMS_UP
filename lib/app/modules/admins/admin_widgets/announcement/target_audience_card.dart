import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
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
            const SizedBox(height: 14),
            _LiveReachRow(controller: controller),
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

/// Multi-select student-group chips — the only student filter. An empty
/// selection means "all groups"; the leading ທັງໝົດ chip clears it.
class _StudentGroupSelector extends StatelessWidget {
  /// Source of reactive group selection.
  final AnnouncementController controller;

  const _StudentGroupSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AnnFieldLabel('ກຸ່ມນັກສຶກສາ (ເລືອກໄດ້ຫຼາຍກຸ່ມ)'),
        const SizedBox(height: 8),
        Obx(() {
          final selected = controller.selectedStudentGroups;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _groupChip(
                label: 'ທັງໝົດ',
                selected: selected.isEmpty,
                onTap: controller.clearStudentGroups,
              ),
              for (final g in controller.studentGroups)
                _groupChip(
                  label: g.stdGroupName,
                  selected: selected.any((s) => s.id == g.id),
                  onTap: () => controller.toggleStudentGroup(g),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _groupChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.info,
      backgroundColor: AppColors.scaffoldBg,
      side: BorderSide(
        color: selected ? AppColors.info : Colors.grey.shade300,
      ),
    );
  }
}

/// Live recipient-count row — re-estimated automatically whenever the
/// audience or group selection changes (see controller workers).
class _LiveReachRow extends StatelessWidget {
  /// Source of reactive reach state.
  final AnnouncementController controller;

  const _LiveReachRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isEstimatingReach.value;
      final count = controller.estimatedReach.value;
      return Row(
        children: [
          const Icon(Icons.podcasts_rounded, size: 16, color: AppColors.info),
          const SizedBox(width: 6),
          const Text(
            'ຜູ້ຮັບໂດຍປະມານ:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          if (loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              count == null ? '?' : '$count ຄົນ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      );
    });
  }
}
