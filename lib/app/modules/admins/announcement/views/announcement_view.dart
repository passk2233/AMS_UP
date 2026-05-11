import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../controllers/announcement_controller.dart';
import 'announcement_history_view.dart';

class AnnouncementView extends GetView<AnnouncementController> {
  const AnnouncementView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AnnouncementController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: Obx(() => controller.showHistory.value
                ? const AnnouncementHistoryView()
                : _buildComposePage(controller)),
          );
        },
      ),
    );
  }

  Widget _buildComposePage(AnnouncementController controller) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AssetImages.dashboardBg),
          fit: BoxFit.cover,
        ),
      ),
              child: Column(
                children: [
                  const AdminAppBar(),
                  // ── Page Header ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.laoBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.campaign_rounded,
                              color: AppColors.laoBlue, size: 22),
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
                        GestureDetector(
                          onTap: controller.openHistory,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.laoBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_rounded,
                                    color: AppColors.laoBlue, size: 16),
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
                        ),
                      ],
                    ),
                  ),
                  // ── Content ───────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildComposeCard(),
                          const SizedBox(height: 14),
                          _buildTargetAudienceCard(),
                          const SizedBox(height: 14),
                          _buildSendButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPOSE MESSAGE CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildComposeCard() {
    return _card(
      icon: Icons.edit_note_rounded,
      title: 'ຂຽນຂໍ້ຄວາມ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('ຫົວຂໍ້'),
          const SizedBox(height: 6),
          _inputField(
            controller: controller.titleCtrl,
            hint: 'ຕົວຢ່າງ: ແຈ້ງປ່ຽນຕາຕະລາງສອບເສັງ',
          ),
          const SizedBox(height: 14),
          _label('ເນື້ອຫາ'),
          const SizedBox(height: 6),
          _inputField(
            controller: controller.messageCtrl,
            hint: 'ພິມລາຍລະອຽດການແຈ້ງເຕືອນ...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TARGET AUDIENCE CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTargetAudienceCard() {
    return _card(
      icon: Icons.groups_rounded,
      title: 'ກຸ່ມເປົ້າໝາຍ',
      child: Obx(() {
        final audience = controller.selectedAudience.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Audience chips ──────────────────────────────────
            _label('ສົ່ງຫາ'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(
                controller.audienceLabels.length,
                (i) {
                  final selected = audience == i;
                  return ChoiceChip(
                    label: Text(controller.audienceLabels[i]),
                    selected: selected,
                    onSelected: (_) {
                      controller.selectedAudience.value = i;
                      // Clear individual search when switching away
                      if (i != 3) {
                        controller.foundStudent.value = null;
                        controller.individualIdCtrl.clear();
                      }
                    },
                    selectedColor: AppColors.laoBlue,
                    backgroundColor: const Color(0xFFF5F7FA),
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? AppColors.laoBlue
                            : Colors.grey.shade300,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    showCheckmark: false,
                  );
                },
              ),
            ),

            // ── Individual student search ──────────────────────
            if (audience == 3) ...[
              const SizedBox(height: 14),
              _buildIndividualSearch(),
            ],

            // ── Student filters (audience == 1) ────────────────
            if (audience == 1) ...[
              const SizedBox(height: 14),
              _buildStudentFilters(),
            ],

            // ── Teacher/All department filter ──────────────────
            if (audience == 0 || audience == 2) ...[
              const SizedBox(height: 14),
              _buildDepartmentRow(),
            ],
          ],
        );
      }),
    );
  }

  // ── Individual Student Search ─────────────────────────────────────────────
  Widget _buildIndividualSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('ຄົ້ນຫານັກສຶກສາ (ໃສ່ ID)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _inputField(
                controller: controller.individualIdCtrl,
                hint: 'ເຊັ່ນ: 123',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: controller.isSearching.value
                      ? null
                      : controller.searchStudentById,
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
        // ── Found student card ──
        Obx(() {
          final s = controller.foundStudent.value;
          if (s == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.nameLao} ${s.surnameLao ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${s.id}  •  ${s.stdCode}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        'ກຸ່ມ: ${s.studentGroup?.stdGroupName ?? '-'}  •  ປະເພດ: ${s.studentType?.stdTypeNameLao ?? '-'}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.foundStudent.value = null;
                    controller.individualIdCtrl.clear();
                  },
                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Student-specific filters (group, type, year, department) ──────────────
  Widget _buildStudentFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Department + Year
        Row(
          children: [
            Expanded(
              child: _dropdownColumn<int?>(
                label: 'ພາກວິຊາ',
                value: controller.selectedDepartment.value?.id,
                items: [
                  const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13))),
                  ...controller.departments.map((d) => DropdownMenuItem<int?>(
                        value: d.id,
                        child: Text(d.deptNameLao,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  controller.selectedDepartment.value = val == null
                      ? null
                      : controller.departments
                          .firstWhereOrNull((d) => d.id == val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownColumn<int>(
                label: 'ຊັ້ນປີ',
                value: controller.selectedYear.value,
                items: List.generate(
                  controller.yearLabels.length,
                  (i) => DropdownMenuItem<int>(
                    value: i,
                    child: Text(controller.yearLabels[i],
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) controller.selectedYear.value = val;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Student Group + Student Type
        Row(
          children: [
            Expanded(
              child: _dropdownColumn<int?>(
                label: 'ກຸ່ມນັກສຶກສາ',
                value: controller.selectedStudentGroup.value?.id,
                items: [
                  const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13))),
                  ...controller.studentGroups.map((g) =>
                      DropdownMenuItem<int?>(
                        value: g.id,
                        child: Text(g.stdGroupName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  controller.selectedStudentGroup.value = val == null
                      ? null
                      : controller.studentGroups
                          .firstWhereOrNull((g) => g.id == val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownColumn<int?>(
                label: 'ປະເພດນັກສຶກສາ',
                value: controller.selectedStudentType.value?.id,
                items: [
                  const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13))),
                  ...controller.studentTypes.map((t) =>
                      DropdownMenuItem<int?>(
                        value: t.id,
                        child: Text(t.stdTypeNameLao,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) {
                  controller.selectedStudentType.value = val == null
                      ? null
                      : controller.studentTypes
                          .firstWhereOrNull((t) => t.id == val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Department-only row (for All / Teachers) ──────────────────────────────
  Widget _buildDepartmentRow() {
    return _dropdownColumn<int?>(
      label: 'ພາກວິຊາ',
      value: controller.selectedDepartment.value?.id,
      items: [
        const DropdownMenuItem<int?>(
            value: null,
            child: Text('ທັງໝົດ', style: TextStyle(fontSize: 13))),
        ...controller.departments.map((d) => DropdownMenuItem<int?>(
              value: d.id,
              child: Text(d.deptNameLao,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (val) {
        controller.selectedDepartment.value = val == null
            ? null
            : controller.departments.firstWhereOrNull((d) => d.id == val);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSendButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed:
              controller.isSending.value ? null : controller.sendNotification,
          icon: controller.isSending.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded, size: 20),
          label: Text(
            controller.isSending.value ? 'ກຳລັງສົ່ງ...' : 'ສົ່ງການແຈ້ງເຕືອນ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.laoBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.laoBlue.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.laoBlue, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.laoBlue, width: 1.5)),
      ),
    );
  }

  Widget _dropdownColumn<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500),
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
