import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_mode_toggle.dart';
import 'eval_question_card.dart';

/// Sub-page that lets the admin manage the evaluation question bank.
class EvalQuestionsPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const EvalQuestionsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EvalModeToggle(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingQuestions.value) {
              return const AppLoading.questionList();
            }
            if (controller.questionsError.isNotEmpty &&
                controller.questions.isEmpty) {
              return AppErrorState(
                message: controller.questionsError.value,
                onRetry: controller.fetchQuestions,
              );
            }
            return _QuestionListSection(controller: controller);
          }),
        ),
      ],
    );
  }
}

/// Header (count + "Add" button) and the scrollable question list.
class _QuestionListSection extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _QuestionListSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                'ຄຳຖາມທັງໝົດ (${controller.questions.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: controller.addQuestion,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('ເພີ່ມ', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.laoBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: controller.questions.isEmpty
              ? const AppEmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'ຍັງບໍ່ມີຄຳຖາມ',
                  subtitle: 'ກົດ "ເພີ່ມ" ເພື່ອສ້າງຄຳຖາມ',
                )
              : RefreshIndicator(
                  onRefresh: controller.fetchQuestions,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: controller.questions.length,
                    itemBuilder: (_, i) => EvalQuestionCard(
                      question: controller.questions[i],
                      index: i,
                      controller: controller,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
