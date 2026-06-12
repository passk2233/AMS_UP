import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';

import '../controllers/faculty_feedback_controller.dart';
import 'package:frontend/app/modules/data/models/faculty_model.dart';

class EvaluationFormView extends GetView<FacultyFeedbackController> {
  const EvaluationFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final Faculty faculty = Get.arguments;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('ປະເມີນອາຈານ', style: AppTypography.heading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: Get.back,
        ),
      ),
      // Pop back to the list the moment the evaluation window closes
      // (admin closed it, or `close_time` passed while the student was here).
      // The list view itself renders the closed state; we only schedule the
      // pop, never paint anything for the closed branch.
      body: Obx(() {
        if (!controller.isEvaluationOpen.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.currentRoute != '/evaluation-form') return;
            Get.back();
            // Delay snackbar so navigation completes before the overlay
            // attaches — avoids AnimationController-after-dispose crash.
            Future.delayed(const Duration(milliseconds: 150), () {
              Get.snackbar(
                'ໄລຍະການປະເມີນຖືກປິດ',
                'ບໍ່ສາມາດສົ່ງການປະເມີນຕໍ່ໄດ້ໃນຕອນນີ້.',
                snackPosition: SnackPosition.BOTTOM,
              );
            });
          });
          return const SizedBox.shrink();
        }
        return _buildForm(faculty);
      }),
    );
  }

  Widget _buildForm(Faculty faculty) {
    return SafeArea(
      child: GetBuilder<FacultyFeedbackController>(
        builder: (controller) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.s,
              AppSpacing.l,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FacultyHeader(faculty: faculty),
                const SizedBox(height: AppSpacing.l),
                const Text('ຄຳຖາມການປະເມີນ',
                    style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.s),
                Obx(() {
                  final questions = controller.questions;
                  if (questions.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.quiz_outlined,
                      title: 'ຍັງບໍ່ມີຄຳຖາມການປະເມີນ',
                      subtitle: 'ກະລຸນາລອງໃໝ່ພາຍຫຼັງ',
                    );
                  }
                  return Column(
                    children: List.generate(
                      questions.length,
                      (i) => _StarRatingQuestion(
                        index: i,
                        question: questions[i].question,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.l),
                AppTextField(
                  label: 'ຄຳເຫັນເພີ່ມເຕີມ',
                  hint: 'ບອກພວກເຮົາແບບໃດກໍຄິດໄດ້... (ບໍ່ບັງຄັບ)',
                  maxLines: 4,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onChanged: (val) => controller.comment.value = val,
                ),
                const SizedBox(height: AppSpacing.l),
                AppPrimaryButton(
                  label: 'ສົ່ງການປະເມີນ',
                  icon: Icons.send_rounded,
                  onPressed: () => controller.submitFeedback(faculty),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'ການປະເມີນຂອງທ່ານຈະຖືກສົ່ງແບບບໍ່ລະບຸຕົວຕົນ',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _FacultyHeader extends StatelessWidget {
  final Faculty faculty;
  const _FacultyHeader({required this.faculty});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          AppAvatar(photo: faculty.photo, radius: 32),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faculty.name, style: AppTypography.subheading),
                const SizedBox(height: AppSpacing.xs),
                Text(faculty.course, style: AppTypography.bodySmallMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRatingQuestion extends GetView<FacultyFeedbackController> {
  final int index;
  final String question;

  const _StarRatingQuestion({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.s + 2),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppTypography.body),
          const SizedBox(height: AppSpacing.s),
          Obx(
            () => Row(
              children: List.generate(5, (starIndex) {
                final filled = starIndex < controller.ratings[index];
                return Expanded(
                  child: SizedBox(
                    height: AppColors.minTouchTarget,
                    child: IconButton(
                      tooltip: '${starIndex + 1} ດາວ',
                      onPressed: () =>
                          controller.setRating(index, starIndex + 1),
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 30,
                        color: filled
                            ? AppColors.accentYellow
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
