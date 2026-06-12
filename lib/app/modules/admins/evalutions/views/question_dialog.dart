import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';

/// Add / edit question dialog for the admin evaluation question bank.
///
/// Reads its inputs from the provided [questionCtrl] / [categoryCtrl] so the
/// caller can act on the captured values when this dialog pops `true`.
class QuestionDialog extends StatelessWidget {
  /// Backing controller for the question text field.
  final TextEditingController questionCtrl;

  /// Backing controller for the (optional) category field.
  final TextEditingController categoryCtrl;

  /// `true` shows "edit" copy, `false` shows "add" copy.
  final bool isEdit;

  const QuestionDialog({
    super.key,
    required this.questionCtrl,
    required this.categoryCtrl,
    required this.isEdit,
  });

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
            Text(
              isEdit ? 'ແກ້ໄຂຄຳຖາມ' : 'ເພີ່ມຄຳຖາມໃໝ່',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _DialogLabel('ຄຳຖາມ *'),
            const SizedBox(height: 4),
            _DialogTextField(
              controller: questionCtrl,
              hint: 'ພິມຄຳຖາມ...',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const _DialogLabel('ໝວດໝູ່ (ບໍ່ບັງຄັບ)'),
            const SizedBox(height: 4),
            _DialogTextField(
              controller: categoryCtrl,
              hint: 'ເຊັ່ນ: ການສອນ, ການປະເມີນ...',
            ),
            const SizedBox(height: 18),
            _DialogFooter(confirmLabel: isEdit ? 'ບັນທຶກ' : 'ເພີ່ມ'),
          ],
        ),
      ),
    );
  }
}

/// Caption rendered above each field in [QuestionDialog].
class _DialogLabel extends StatelessWidget {
  /// Caption text.
  final String text;

  const _DialogLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Filled, rounded multi-line text field used inside [QuestionDialog].
class _DialogTextField extends StatelessWidget {
  /// Backing controller.
  final TextEditingController controller;

  /// Placeholder.
  final String hint;

  /// Vertical line count.
  final int maxLines;

  const _DialogTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.scaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: maxLines > 1 ? 12 : 10,
        ),
      ),
    );
  }
}

/// Cancel / confirm footer used by [QuestionDialog].
class _DialogFooter extends StatelessWidget {
  /// Confirm button caption (changes between "add" and "save").
  final String confirmLabel;

  const _DialogFooter({required this.confirmLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
