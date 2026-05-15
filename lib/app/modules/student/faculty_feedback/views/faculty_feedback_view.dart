import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/faculty_feedback_controller.dart';
import 'faculty_model.dart';
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'ປະເມີນອາຈານ',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: InputDecoration(
                hintText: 'ຄົ້ນຫາອາຈານ ຫຼື ວິຊາ...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey.shade400),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.buttonRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.buttonRadius),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.buttonRadius),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () {
                if (controller.isLoading.value) {
                  return const AppLoading.facultyList();
                }
                if (controller.errorMessage.value.isNotEmpty) {
                  return AppErrorState(
                    message: controller.errorMessage.value,
                    onRetry: () => controller.onInit(),
                  );
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
              },
            ),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  faculty.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
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
    return ElevatedButton.icon(
      onPressed: () =>
          Get.toNamed(Routes.EVALUATION_FORM, arguments: faculty),
      icon: const Icon(Icons.rate_review_rounded, size: 18),
      label: const Text(
        'ປະເມີນ',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.buttonRadius),
        ),
        elevation: 0,
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
          Icon(Icons.check_circle_outline,
              color: AppColors.borderApproved, size: 20),
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
