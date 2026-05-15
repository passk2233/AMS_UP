import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:frontend/app/widgets/app_colors.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AssetImages.login1),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double formWidth = constraints.maxWidth > 500
                            ? 400
                            : constraints.maxWidth;
                        return SizedBox(
                          width: formWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 40.0),

                              // Topic Welcome
                              const Text(
                                'ຍິນດີຕ້ອນຮັບ\nCEIT AMS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 60.0),

                              // Field User ID
                              const Text(
                                'ຊື່ຜູ້ໃຊ້',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextField(
                                controller: controller.usernameController,
                                decoration: InputDecoration(
                                  hintText: 'ກະລຸນາໃສ່ຊື່ຜູ້ໃຊ້',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14.0,
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2.0,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24.0),

                              // Field Password
                              const Text(
                                'ລະຫັດຜ່ານ',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Obx(() => TextField(
                                    controller: controller.passwordController,
                                    obscureText: controller.isObscured.value,
                                    decoration: InputDecoration(
                                      hintText: 'ກະລຸນາໃສ່ລະຫັດຜ່ານ',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14.0,
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                          width: 2.0,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      suffixIcon: SizedBox(
                                        width: AppColors.minTouchTarget,
                                        height: AppColors.minTouchTarget,
                                        child: IconButton(
                                          icon: Icon(
                                            controller.isObscured.value
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textSecondary,
                                          ),
                                          onPressed: () =>
                                              controller.toggleObscured(),
                                        ),
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 10.0),

                              // Remember Me Checkbox
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Obx(() => SizedBox(
                                        width: AppColors.minTouchTarget,
                                        height: AppColors.minTouchTarget,
                                        child: Checkbox(
                                          value: controller.rememberMe.value,
                                          onChanged: (value) =>
                                              controller
                                                  .toggleRememberMe(value),
                                          activeColor: AppColors.primary,
                                          side: const BorderSide(
                                              color: AppColors.textSecondary),
                                        ),
                                      )),
                                  const Text(
                                    'ຈົດຈຳຂ້ອຍ',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),

                              // Login Button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () => controller.login(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Obx(() => controller.isLoading.value
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text(
                                          'ເຂົ້າສູ່ລະບົບ',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        )),
                                ),
                              ),
                              const SizedBox(height: 40.0),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}