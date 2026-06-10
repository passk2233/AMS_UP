import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../utilities/media_url.dart';
import '../../../../widgets/widget.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/student_group_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/student_type_model.dart';
import '../controllers/announcement_controller.dart';
import 'announcement_history_view.dart';

/// Announcement composer (the "Announcements" admin tab).
///
/// Toggles between the compose form and the [AnnouncementHistoryView] based
/// on [AnnouncementController.showHistory]. All form state lives in the
/// controller; this view is composition only.
class AnnouncementView extends GetView<AnnouncementController> {
  const AnnouncementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => controller.showHistory.value
            ? const AnnouncementHistoryView()
            : _ComposePage(controller: controller),
      ),
    );
  }
}

/// Composer page with header + compose card + target-audience card + send
/// button.
class _ComposePage extends StatelessWidget {
  /// Source of reactive state.
  final AnnouncementController controller;

  const _ComposePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AssetImages.dashboardBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          const AdminAppBar(),
          _ComposeHeader(onHistory: controller.openHistory),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  _ComposeCard(controller: controller),
                  const SizedBox(height: 14),
                  _AttachmentCard(controller: controller),
                  const SizedBox(height: 14),
                  _TargetAudienceCard(controller: controller),
                  const SizedBox(height: 14),
                  _SendButton(controller: controller),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top header row — title (with icon) on the left, history shortcut on the
/// right.
class _ComposeHeader extends StatelessWidget {
  /// Tap callback for the history shortcut.
  final VoidCallback onHistory;

  const _ComposeHeader({required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.laoBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.laoBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ສົ່ງການແຈ້ງເຕືອນ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _HistoryShortcut(onTap: onHistory),
        ],
      ),
    );
  }
}

/// Indigo pill that opens the [AnnouncementHistoryView].
class _HistoryShortcut extends StatelessWidget {
  /// Tap handler.
  final VoidCallback onTap;

  const _HistoryShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.laoBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, color: AppColors.laoBlue, size: 16),
            SizedBox(width: 4),
            Text(
              'ປະຫວັດ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.laoBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card containing the title + message fields.
class _ComposeCard extends StatelessWidget {
  /// Source of reactive state.
  final AnnouncementController controller;

  const _ComposeCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.edit_note_rounded,
      title: 'ຂຽນຂໍ້ຄວາມ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('ຫົວຂໍ້'),
          const SizedBox(height: 6),
          _FilledTextField(
            controller: controller.titleCtrl,
            hint: 'ຕົວຢ່າງ: ແຈ້ງປ່ຽນຕາຕະລາງສອບເສັງ',
          ),
          const SizedBox(height: 14),
          const _FieldLabel('ເນື້ອຫາ'),
          const SizedBox(height: 6),
          _FilledTextField(
            controller: controller.messageCtrl,
            hint: 'ພິມລາຍລະອຽດການແຈ້ງເຕືອນ...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

/// Target-audience selector + audience-specific filters.
class _TargetAudienceCard extends StatelessWidget {
  /// Source of reactive audience state.
  final AnnouncementController controller;

  const _TargetAudienceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.groups_rounded,
      title: 'ກຸ່ມເປົ້າໝາຍ',
      child: Obx(() {
        final audience = controller.selectedAudience.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('ສົ່ງຫາ'),
            const SizedBox(height: 8),
            _AudienceChips(controller: controller, selected: audience),
            if (audience == AnnouncementAudience.individual) ...[
              const SizedBox(height: 14),
              _IndividualSearchSection(controller: controller),
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

/// Individual-student lookup field + lookup result card.
class _IndividualSearchSection extends StatelessWidget {
  /// Source of reactive search state.
  final AnnouncementController controller;

  const _IndividualSearchSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('ຄົ້ນຫານັກສຶກສາ (ລະຫັດ ຫຼື ຊື່)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _FilledTextField(
                controller: controller.individualSearchCtrl,
                hint: 'ເຊັ່ນ: 64010001 ຫຼື ຊື່ນັກສຶກສາ',
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => SizedBox(
                height: AppColors.minTouchTarget,
                child: ElevatedButton.icon(
                  onPressed: controller.isSearching.value
                      ? null
                      : controller.searchStudents,
                  icon: controller.isSearching.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                  label: const Text('ຄົ້ນຫາ', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.laoBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Obx(() {
          final selected = controller.foundStudent.value;
          if (selected != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _FoundStudentCard(
                student: selected,
                onClear: controller.clearIndividualSelection,
              ),
            );
          }

          final results = controller.searchResults;
          if (results.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('ຜົນການຄົ້ນຫາ (${results.length})'),
                const SizedBox(height: 6),
                for (final s in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _StudentResultRow(
                      student: s,
                      onTap: () => controller.selectStudent(s),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Tappable row for one search match — picks the student as the recipient.
class _StudentResultRow extends StatelessWidget {
  /// The matched student.
  final StudentModel student;

  /// Selects this student.
  final VoidCallback onTap;

  const _StudentResultRow({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.laoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.laoBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.nameLao} ${s.surnameLao ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ລະຫັດ: ${s.stdCode}  •  ກຸ່ມ: ${s.studentGroup?.stdGroupName ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

/// Green-tinted card summarizing the selected student.
class _FoundStudentCard extends StatelessWidget {
  /// The selected student.
  final StudentModel student;

  /// Tap handler for the close button.
  final VoidCallback onClear;

  const _FoundStudentCard({required this.student, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.borderApproved.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderApproved.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.borderApproved.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.borderApproved,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.nameLao} ${s.surnameLao ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ລະຫັດ: ${s.stdCode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'ກຸ່ມ: ${s.studentGroup?.stdGroupName ?? '-'}  •  ປະເພດ: ${s.studentType?.stdTypeNameLao ?? '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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
    return _LabeledDropdown<int?>(
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
    return _LabeledDropdown<int>(
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
    return _LabeledDropdown<int?>(
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
    return _LabeledDropdown<int?>(
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

/// Primary "Send announcement" button.
class _SendButton extends StatelessWidget {
  /// Source of reactive sending state.
  final AnnouncementController controller;

  const _SendButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final uploading = controller.isUploading.value;
      final sending = controller.isSending.value;
      return AppPrimaryButton(
        label: uploading
            ? 'ກຳລັງອັບໂຫຼດໄຟລ໌...'
            : (sending ? 'ກຳລັງສົ່ງ...' : 'ສົ່ງການແຈ້ງເຕືອນ'),
        icon: Icons.send_rounded,
        isLoading: sending || uploading,
        onPressed: controller.sendNotification,
        backgroundColor: AppColors.laoBlue,
      );
    });
  }
}

/// Attachment section — an externally-hosted image URL (with live preview) and
/// an uploadable file. The photo is referenced by URL only (no upload); the
/// file is staged here and uploaded at send time by the controller.
class _AttachmentCard extends StatelessWidget {
  /// Source of reactive attachment state.
  final AnnouncementController controller;

  const _AttachmentCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.attachment_rounded,
      title: 'ໄຟລ໌ແນບ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final count = controller.pickedFiles.length;
            return _FieldLabel(
              count == 0
                  ? 'ໄຟລ໌ (PDF, ຮູບ, ເອກະສານ)'
                  : 'ໄຟລ໌ແນບ ($count/${AnnouncementController.maxUploadFiles})',
            );
          }),
          const SizedBox(height: 6),
          Obx(() {
            final files = controller.pickedFiles;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < files.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PickedFileRow(
                      file: files[i],
                      onRemove: () => controller.removePickedFileAt(i),
                    ),
                  ),
                if (files.length < AnnouncementController.maxUploadFiles)
                  _PickFileButton(
                    onTap: controller.pickAttachment,
                    label: files.isEmpty ? 'ເລືອກໄຟລ໌ແນບ' : 'ເພີ່ມໄຟລ໌',
                  ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Text(
            'ຮອງຮັບ PDF, Word, Excel, PowerPoint, ຮູບ — ສູງສຸດ 10 MB/ໄຟລ໌, '
            '${AnnouncementController.maxUploadFiles} ໄຟລ໌',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width "pick / add files" button.
class _PickFileButton extends StatelessWidget {
  /// Tap handler — opens the multi-select system file picker.
  final VoidCallback onTap;

  /// Button caption (e.g. "ເລືອກໄຟລ໌ແນບ" first, "ເພີ່ມໄຟລ໌" afterwards).
  final String label;

  const _PickFileButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.laoBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.laoBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 20,
              color: AppColors.laoBlue,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.laoBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staged-file row — icon, name, size, and a remove action.
class _PickedFileRow extends StatelessWidget {
  /// The picked-but-not-yet-uploaded file.
  final PlatformFile file;

  /// Removes this staged file.
  final VoidCallback onRemove;

  const _PickedFileRow({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isImage = isImagePath(file.name);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.borderApproved.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderApproved.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.borderApproved.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
              size: 20,
              color: AppColors.borderApproved,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(file.size),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.grey.shade600,
            ),
            tooltip: 'ລຶບ',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Human-readable byte size (B / KB / MB) for the staged file.
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────── reusable building blocks ──

/// White rounded card with an indigo icon-headed title row above the [child].
class _SectionCard extends StatelessWidget {
  /// Leading icon next to the title.
  final IconData icon;

  /// Card heading.
  final String title;

  /// Body slot.
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.m + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.laoBlue, size: 22),
              const SizedBox(width: AppSpacing.s),
              Text(title, style: AppTypography.subheading),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

/// Small all-caps caption used as a label above a field or dropdown.
class _FieldLabel extends StatelessWidget {
  /// Caption text.
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.captionStrong);
  }
}

/// Filled, rounded text field shared by the title / message / search inputs.
class _FilledTextField extends StatelessWidget {
  /// Backing controller.
  final TextEditingController controller;

  /// Placeholder text.
  final String hint;

  /// Vertical line count.
  final int maxLines;

  /// Optional keyboard hint (numeric for ID lookup, etc.).
  final TextInputType? keyboardType;

  const _FilledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        // Slate (4.5:1), not grey.shade400 (~1.8:1) — placeholders are held to
        // the same contrast floor as body text. See DESIGN.md.
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.laoBlue, width: 1.5),
        ),
      ),
    );
  }
}

/// Label + boxed dropdown column, used by every selector on this page.
class _LabeledDropdown<T> extends StatelessWidget {
  /// Caption rendered above the dropdown.
  final String label;

  /// Current value.
  final T value;

  /// Available options.
  final List<DropdownMenuItem<T>> items;

  /// Invoked when the user picks a different option.
  final ValueChanged<T?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
