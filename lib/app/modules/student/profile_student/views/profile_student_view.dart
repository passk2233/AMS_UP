import 'package:flutter/material.dart';
import 'package:frontend/app/widgets/widget.dart';
import 'package:get/get.dart';
import '../controllers/profile_student_controller.dart';

/// Builds an info row, or an empty box when the value is missing ("-" / blank).
/// Fields the API does not provide (e.g. student type, an unset email) are
/// hidden instead of showing a column of "-".
Widget _infoTile(
  IconData icon,
  String label,
  String value, {
  Color? valueColor,
}) {
  final v = value.trim();
  if (v.isEmpty || v == '-') return const SizedBox.shrink();
  return AppInfoTile(icon: icon, label: label, value: v, valueColor: valueColor);
}

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
            topBar: const AppTopBar(notiRoute: '/student-noti'),
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

              final dob = controller.dob == null
                  ? '-'
                  : '${controller.dob!.day}/${controller.dob!.month}/${controller.dob!.year}';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                child: Column(
                  children: [
                    AppProfileHeader(
                      name: controller.displayName,
                      subtitle: "ລະຫັດ: ${controller.studentCode}",
                      caption: controller.program,
                      photo: controller.photo,
                    ),
                    const SizedBox(height: 25),

                    // ─── Personal information ───────────────────────────────
                    const AppSectionTitle("ຂໍ້ມູນສ່ວນຕົວ"),
                    AppSurfaceCard(
                      child: Column(
                        children: [
                          _infoTile(Icons.person_outline,
                              "ຊື່-ນາມສະກຸນ (ອັງກິດ)", controller.nameEng),
                          _infoTile(Icons.transgender, "ເພດ", controller.gender),
                          _infoTile(Icons.cake_outlined, "ວັນເດືອນປີເກີດ", dob),
                          _infoTile(Icons.flag_outlined, "ສັນຊາດ",
                              controller.nationality),
                          _infoTile(Icons.people_outline, "ຊົນເຜົ່າ",
                              controller.ethnic),
                          _infoTile(Icons.account_tree, "ເຊື້ອຊາດ",
                              controller.race),
                          _infoTile(Icons.group_outlined, "ຕະກູນ",
                              controller.tribe),
                          _infoTile(Icons.menu_book_outlined, "ສາສະໜາ",
                              controller.religion),
                          _infoTile(Icons.favorite_border, "ສະຖານະສົມລົດ",
                              controller.maritalStatus),
                          _infoTile(Icons.health_and_safety_outlined, "ສຸຂະພາບ",
                              controller.healthStatus),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Contact information ────────────────────────────────
                    const AppSectionTitle("ຂໍ້ມູນຕິດຕໍ່"),
                    AppSurfaceCard(
                      child: Column(
                        children: [
                          _infoTile(Icons.email_outlined, "ອີເມວ",
                              controller.email),
                          _infoTile(Icons.phone_android_outlined, "ເບີໂທ",
                              controller.phone),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Education information ──────────────────────────────
                    const AppSectionTitle("ຂໍ້ມູນການສຶກສາ"),
                    AppSurfaceCard(
                      child: Column(
                        children: [
                          _infoTile(Icons.badge_outlined, "ລະຫັດນັກສຶກສາ",
                              controller.studentCode),
                          _infoTile(Icons.category_outlined, "ປະເພດນັກສຶກສາ",
                              controller.studentTypeName),
                          _infoTile(Icons.groups_outlined, "ກຸ່ມ",
                              controller.studentGroupName),
                          _infoTile(Icons.school_outlined, "ຫຼັກສູດ",
                              controller.program,
                              valueColor: AppColors.primary),
                          _infoTile(Icons.account_balance_outlined,
                              "ໂຮງຮຽນ / ສະຖາບັນ", controller.school),
                          _infoTile(Icons.work_outline, "ຕຳແໜ່ງ",
                              controller.jobTitle),
                        ],
                      ),
                    ),

                    RoleSwitcherCard(
                      roles: controller.user.value?.roles ?? const [],
                      current: 'student',
                    ),

                    const SizedBox(height: 30),
                    Obx(
                      () => AppSignOutButton(
                        onPressed: controller.logout,
                        isLoading: controller.isLoggingOut.value,
                      ),
                    ),
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
