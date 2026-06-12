import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';

/// Date/time picker dialog for opening the window.
class EvalWindowFormDialog extends StatelessWidget {
  /// Source of the form fields.
  final EvalutionController controller;

  const EvalWindowFormDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ກຳນົດໄລຍະການປະເມີນ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ນັກສຶກສາຈະປະເມີນອາຈານໄດ້ພາຍໃນຊ່ວງເວລານີ້.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _WindowTimePicker(
              label: 'ເວລາເປີດ',
              icon: Icons.event_available_outlined,
              value: controller.formOpenTime,
            ),
            const SizedBox(height: 10),
            _WindowTimePicker(
              label: 'ເວລາປິດ',
              icon: Icons.event_busy_outlined,
              value: controller.formCloseTime,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('ຍົກເລີກ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.laoBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('ເປີດການປະເມີນ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One labeled date/time picker row used inside [EvalWindowFormDialog].
class _WindowTimePicker extends StatelessWidget {
  /// Caption above the picker.
  final String label;

  /// Glyph rendered beside the value.
  final IconData icon;

  /// Reactive backing value updated when the user picks a moment.
  final Rx<DateTime?> value;

  const _WindowTimePicker({
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Obx(() {
          final v = value.value;
          final display = v == null ? 'ເລືອກວັນທີ ແລະ ເວລາ' : _fmt(v);
          return GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.laoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        color: v == null
                            ? Colors.grey.shade500
                            : AppColors.textPrimary,
                        fontWeight: v == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pick(BuildContext context) async {
    final initial = value.value ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    value.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
