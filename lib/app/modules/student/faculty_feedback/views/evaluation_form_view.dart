import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  // Group questions by category, preserving the original index
                  // so each star rating still maps to controller.ratings[i].
                  final groups = <String, List<int>>{};
                  for (var i = 0; i < questions.length; i++) {
                    final cat = (questions[i].category?.trim().isNotEmpty ?? false)
                        ? questions[i].category!.trim()
                        : 'ອື່ນໆ';
                    groups.putIfAbsent(cat, () => []).add(i);
                  }
                  final children = <Widget>[];
                  var section = 0;
                  groups.forEach((category, indices) {
                    section++;
                    children.add(Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.m, bottom: AppSpacing.s),
                      child: Text('$section. $category',
                          style: AppTypography.subheading),
                    ));
                    for (final i in indices) {
                      children.add(_StarRatingQuestion(
                        key: i < controller.questionKeys.length
                            ? controller.questionKeys[i]
                            : null,
                        index: i,
                        question: questions[i].question,
                      ));
                    }
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
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

  const _StarRatingQuestion(
      {super.key, required this.index, required this.question});

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
          Obx(() {
            final v = controller.ratings[index];
            final missing = controller.showErrors.value && v == 0;
            return Container(
              height: AppColors.minTouchTarget + 6,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: missing ? AppColors.danger : Colors.grey.shade300,
                  width: missing ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller.scoreCtrls[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppTypography.subheading
                            .copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: AppTypography.subheading
                          .copyWith(color: AppColors.textPrimary),
                      onChanged: (val) =>
                          controller.onScoreTyped(index, val),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ຫຼຸດ',
                    onPressed:
                        v > 0 ? () => controller.setRating(index, v - 1) : null,
                    icon: const Icon(Icons.remove_rounded),
                    color: AppColors.primaryFill,
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                  IconButton(
                    tooltip: 'ເພີ່ມ',
                    onPressed: v < 10
                        ? () => controller.setRating(index, v + 1)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.primaryFill,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Obx(() {
            final missing =
                controller.showErrors.value && controller.ratings[index] == 0;
            return Text(
              missing
                  ? 'ກະລຸນາໃຫ້ຄະແນນຂໍ້ນີ້ (1–10)'
                  : 'ໃຫ້ຄະແນນ 1–10 (ຄະແນນເຕັມ 10)',
              style: missing
                  ? AppTypography.caption.copyWith(color: AppColors.danger)
                  : AppTypography.caption,
            );
          }),
        ],
      ),
    );
  }
}
