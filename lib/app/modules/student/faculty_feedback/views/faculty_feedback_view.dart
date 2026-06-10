import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/faculty_feedback_controller.dart';
import 'package:frontend/app/modules/data/models/faculty_model.dart';
import 'package:frontend/app/routes/app_pages.dart';

class FacultyFeedbackView extends GetView<FacultyFeedbackController> {
  const FacultyFeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FacultyFeedbackController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Get.back(),
              ),
              title: const Text(
                'ປະເມີນອາຈານ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Obx(
                    () => AppSearchBar(
                      hint: 'ຄົ້ນຫາອາຈານ ຫຼື ວິຊາ...',
                      onChanged: (v) => controller.query.value = v,
                      currentQuery: controller.query.value,
                      onClear: () => controller.query.value = '',
                    ),
                  ),
                ),
                // Anonymity reassurance — the product's core trust guarantee, stated
                // where the student is about to act on it.
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    0,
                    AppSpacing.m,
                    AppSpacing.s,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ຄຳຕອບຂອງທ່ານເປັນຄວາມລັບ — ອາຈານຈະບໍ່ເຫັນຊື່ຜູ້ປະເມີນ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const AppLoading.facultyList();
                    }
                    if (controller.errorMessage.value.isNotEmpty) {
                      return AppErrorState(
                        message: controller.errorMessage.value,
                        onRetry: () => controller.onInit(),
                      );
                    }
                    if (!controller.isEvaluationOpen.value) {
                      return _buildClosedState(controller);
                    }
                    final list = controller.filteredFacultyList;
                    if (list.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.school_outlined,
                        title: 'ບໍ່ພົບອາຈານ',
                        subtitle: 'ລອງຄົ້ນຫາດ້ວຍຄຳອື່ນ',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (context, index) =>
                          _buildFacultyCard(list[index]),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFacultyCard(Faculty faculty) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(photo: faculty.photo, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faculty.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      faculty.course,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: AppColors.minTouchTarget,
            child: faculty.isSubmitted
                ? _buildSubmittedButton()
                : _buildEvaluateButton(faculty),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluateButton(Faculty faculty) {
    return AppPrimaryButton(
      label: 'ປະເມີນ',
      icon: Icons.rate_review_rounded,
      onPressed: () => Get.toNamed(Routes.EVALUATION_FORM, arguments: faculty),
    );
  }

  Widget _buildClosedState(FacultyFeedbackController controller) {
    final window = controller.activeWindow.value;
    String? hint;
    if (window != null && window.openTime != null) {
      final dt = window.openTime!;
      String two(int n) => n.toString().padLeft(2, '0');
      final fmt =
          '${two(dt.day)}/${two(dt.month)}/${dt.year} '
          '${two(dt.hour)}:${two(dt.minute)}';
      hint = window.isOpenNow ? null : 'ໄລຍະຕໍ່ໄປຈະເປີດໃນ $fmt';
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ການປະເມີນຍັງບໍ່ໄດ້ເປີດ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hint ?? 'ກະລຸນາລໍຖ້າຜູ້ດູແລລະບົບເປີດໄລຍະການປະເມີນ.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => controller.fetchData(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('ໂຫຼດໃໝ່'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.borderApproved.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppColors.buttonRadius),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.borderApproved,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'ສົ່ງແລ້ວ',
            style: TextStyle(
              color: AppColors.borderApproved,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
