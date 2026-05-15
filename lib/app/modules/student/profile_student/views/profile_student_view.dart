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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading.profile();
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

              const AppSectionTitle("ຂໍ້ມູນສ່ວນຕົວ"),
              AppSurfaceCard(
                child: Column(
                  children: [
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
                      icon: Icons.location_on_outlined,
                      label: "ທີ່ຢູ່",
                      value: controller.address,
                    ),
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

              const AppSectionTitle("ຂໍ້ມູນການສຶກສາ"),
              AppSurfaceCard(
                child: Column(
                  children: [
                    AppInfoTile(
                      icon: Icons.school_outlined,
                      label: "ຫຼັກສູດ",
                      value: controller.program,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              

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
