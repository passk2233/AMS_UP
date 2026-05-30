import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/profile_student_controller.dart';

class ProfileStudentView extends GetView<ProfileStudentController> {
  const ProfileStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileStudentController>()) {
      Get.put(ProfileStudentController());
    }

    return GetBuilder<ProfileStudentController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return AppPageScaffold(
      title: 'ໂປຣໄຟລ໌',
      trailing: AppIconBubble(
        icon: Icons.notifications_none_rounded,
        onTap: () => Get.toNamed('/student-noti'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return AppRefreshableLoader(
            onRefresh: () async => controller.onInit(),
            child: const AppLoading.profile(),
          );
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return AppErrorState(
            message: controller.errorMessage.value,
            onRetry: () => controller.onInit(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          child: Column(
            children: [
              AppProfileHeader(
                name: controller.displayName,
                subtitle: "ລະຫັດ: ${controller.studentCode}",
                caption: controller.program,
                avatarImage: const AssetImage(AssetImages.profile2),
              ),
              const SizedBox(height: 25),

              // ─── Personal information ───────────────────────────────
              const AppSectionTitle("ຂໍ້ມູນສ່ວນຕົວ"),
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.person_outline,
                      label: "ຊື່-ນາມສະກຸນ (ອັງກິດ)",
                      value: controller.nameEng,
                    ),
                    AppInfoTile(
                      icon: Icons.transgender,
                      label: "ເພດ",
                      value: controller.gender,
                    ),
                    AppInfoTile(
                      icon: Icons.cake_outlined,
                      label: "ວັນເດືອນປີເກີດ",
                      value: controller.dob == null
                          ? '-'
                          : '${controller.dob!.day}/${controller.dob!.month}/${controller.dob!.year}',
                    ),
                    AppInfoTile(
                      icon: Icons.flag_outlined,
                      label: "ສັນຊາດ",
                      value: controller.nationality,
                    ),
                    AppInfoTile(
                      icon: Icons.people_outline,
                      label: "ຊົນເຜົ່າ",
                      value: controller.ethnic,
                    ),
                    AppInfoTile(
                      icon: Icons.account_tree,
                      label: "ເຊື້ອຊາດ",
                      value: controller.race,
                    ),
                    AppInfoTile(
                      icon: Icons.group_outlined,
                      label: "ຕະກູນ",
                      value: controller.tribe,
                    ),
                    AppInfoTile(
                      icon: Icons.menu_book_outlined,
                      label: "ສາສະໜາ",
                      value: controller.religion,
                    ),
                    AppInfoTile(
                      icon: Icons.favorite_border,
                      label: "ສະຖານະສົມລົດ",
                      value: controller.maritalStatus,
                    ),
                    AppInfoTile(
                      icon: Icons.health_and_safety_outlined,
                      label: "ສຸຂະພາບ",
                      value: controller.healthStatus,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Contact information ────────────────────────────────
              const AppSectionTitle("ຂໍ້ມູນຕິດຕໍ່"),
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.email_outlined,
                      label: "ອີເມວ",
                      value: controller.email,
                    ),
                    AppInfoTile(
                      icon: Icons.phone_android_outlined,
                      label: "ເບີໂທ",
                      value: controller.phone,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Education information ──────────────────────────────
              const AppSectionTitle("ຂໍ້ມູນການສຶກສາ"),
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.badge_outlined,
                      label: "ລະຫັດນັກສຶກສາ",
                      value: controller.studentCode,
                    ),
                    AppInfoTile(
                      icon: Icons.category_outlined,
                      label: "ປະເພດນັກສຶກສາ",
                      value: controller.studentTypeName,
                    ),
                    AppInfoTile(
                      icon: Icons.groups_outlined,
                      label: "ກຸ່ມ",
                      value: controller.studentGroupName,
                    ),
                    AppInfoTile(
                      icon: Icons.school_outlined,
                      label: "ຫຼັກສູດ",
                      value: controller.program,
                      valueColor: AppColors.primary,
                    ),
                    AppInfoTile(
                      icon: Icons.account_balance_outlined,
                      label: "ໂຮງຮຽນ / ສະຖາບັນ",
                      value: controller.school,
                    ),
                    AppInfoTile(
                      icon: Icons.work_outline,
                      label: "ຕຳແໜ່ງ",
                      value: controller.jobTitle,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              AppSignOutButton(onPressed: controller.logout),
              const SizedBox(height: 10),
            ],
          ),
        );
      }),
    );
        },
      ),
    );
  }
}
