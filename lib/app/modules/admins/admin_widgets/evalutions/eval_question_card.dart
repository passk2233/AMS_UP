import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/evaluation_question_model.dart';
import '../../evalutions/controllers/evalutions_controller.dart';

/// One question row card — number bubble + category + active toggle + edit
/// / delete actions.
class EvalQuestionCard extends StatelessWidget {
  /// The question rendered by this card.
  final EvaluationQuestionModel question;

  /// 1-based row number shown inside the leading bubble.
  final int index;

  /// Source of mutation callbacks.
  final EvalutionController controller;

  const EvalQuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final active = question.isActive == 1;
    final borderColor = active
        ? AppColors.borderApproved
        : Colors.grey.shade300;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NumberBubble(number: index + 1),
                const SizedBox(width: 8),
                if (question.category != null && question.category!.isNotEmpty)
                  _CategoryChip(category: question.category!),
                const Spacer(),
                _ActiveToggle(
                  active: active,
                  onTap: () => controller.toggleQuestionActive(question),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SmallActionButton(
                  icon: Icons.edit_outlined,
                  label: 'ແກ້ໄຂ',
                  color: AppColors.laoBlue,
                  onTap: () => controller.editQuestion(question),
                ),
                const SizedBox(width: 8),
                _SmallActionButton(
                  icon: Icons.delete_outline,
                  label: 'ລຶບ',
                  color: AppColors.rejectRed,
                  onTap: () =>
                      controller.deleteQuestion(question.evaQuestionId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small indigo square containing the 1-based row number.
class _NumberBubble extends StatelessWidget {
  /// Row number.
  final int number;

  const _NumberBubble({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.laoBlue,
          ),
        ),
      ),
    );
  }
}

/// Gray pill showing the question's category.
class _CategoryChip extends StatelessWidget {
  /// Category label.
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Tappable status pill that flips the question's active flag.
class _ActiveToggle extends StatelessWidget {
  /// Current active state.
  final bool active;

  /// Tap handler.
  final VoidCallback onTap;

  const _ActiveToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppColors.borderApproved.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          active ? 'ເປີດ' : 'ປິດ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.borderApproved : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// Color-tinted inline action button shared by the question card.
class _SmallActionButton extends StatelessWidget {
  /// Glyph.
  final IconData icon;

  /// Caption.
  final String label;

  /// Tint applied to icon + text.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
